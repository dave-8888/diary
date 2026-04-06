import 'dart:async';

import 'package:camera/camera.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:diary_mvp/app/cupertino_kit.dart';
import 'package:diary_mvp/app/themed_snackbar.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/models/captured_media_result.dart';
import 'package:diary_mvp/features/diary/presentation/utils/camera_support.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/local_video_player.dart';
import 'package:diary_mvp/features/diary/services/location_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum CameraCaptureMode { photo, video }

enum _PermissionKind { camera, microphone }

class CameraCapturePage extends ConsumerStatefulWidget {
  const CameraCapturePage({
    super.key,
    this.initialMode = CameraCaptureMode.photo,
  });

  final CameraCaptureMode initialMode;

  @override
  ConsumerState<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends ConsumerState<CameraCapturePage>
    with WidgetsBindingObserver {
  static const MethodChannel _permissionsChannel = MethodChannel(
    'diary_mvp/camera_permissions',
  );

  final CropController _cropController = CropController();

  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  late CameraCaptureMode _captureMode;

  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isCropping = false;
  bool _isVideoRecording = false;
  Object? _error;
  _PermissionKind? _permissionIssue;

  String? _capturedPhotoPath;
  String? _capturedVideoPath;
  String? _capturedVideoDurationLabel;
  DateTime? _capturedPhotoCapturedAt;
  String? _capturedPhotoLocation;
  DateTime? _capturedVideoCapturedAt;
  String? _capturedVideoLocation;
  Uint8List? _croppedImageBytes;
  Uint8List? _previewImageBytes;
  DateTime? _videoRecordingStartedAt;
  Future<void>? _capturedPhotoLocationLookup;
  Future<void>? _capturedVideoLocationLookup;

  @override
  void initState() {
    super.initState();
    _captureMode = widget.initialMode;
    WidgetsBinding.instance.addObserver(this);
    if (supportsInAppCameraCapture) {
      _prepareCamera();
    } else {
      _isInitializing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final controller = _controller;
    if (controller == null || _cameras.isEmpty || _hasCapturedMedia) return;

    if (state == AppLifecycleState.inactive) {
      await controller.dispose();
      _controller = null;
      return;
    }

    if (state == AppLifecycleState.resumed && mounted) {
      await _initializeCamera(_cameras[_selectedCameraIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final controller = _controller;
    final canSwitchCamera = _cameras.length > 1 &&
        !_isInitializing &&
        !_isCapturing &&
        !_hasCapturedMedia &&
        !_isVideoRecording;
    final canChangeMode = !_isInitializing &&
        !_isCapturing &&
        !_hasCapturedMedia &&
        !_isVideoRecording;

    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(
              context,
              strings,
              canSwitchCamera: canSwitchCamera,
            ),
            Expanded(child: _buildBody(context, controller, canChangeMode)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: _buildBottomBar(context, controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasCapturedPhoto => _capturedPhotoPath != null;

  bool get _hasCapturedVideo => _capturedVideoPath != null;

  bool get _hasCapturedMedia => _hasCapturedPhoto || _hasCapturedVideo;

  String _pageTitle(AppStrings strings) {
    if (_isCropping) return strings.cropPhoto;
    if (_hasCapturedPhoto) return strings.previewPhoto;
    if (_hasCapturedVideo) return strings.previewVideo;
    return _captureMode == CameraCaptureMode.video
        ? strings.recordVideo
        : strings.cameraCapture;
  }

  Widget _buildTopBar(
    BuildContext context,
    AppStrings strings, {
    required bool canSwitchCamera,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _buildTopBarButton(
            icon: CupertinoIcons.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              _pageTitle(strings),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox.square(
            dimension: 40,
            child: canSwitchCamera
                ? _buildTopBarButton(
                    icon: Icons.cameraswitch_outlined,
                    onTap: _switchCamera,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CameraController? controller,
    bool canChangeMode,
  ) {
    if (_isCropping) {
      return _buildCropBody(context);
    }

    if (_hasCapturedPhoto) {
      return _buildPhotoPreviewBody(context);
    }

    if (_hasCapturedVideo) {
      return _buildVideoPreviewBody(context);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                CupertinoPill(
                  selected: _captureMode == CameraCaptureMode.photo,
                  onPressed: canChangeMode
                      ? () =>
                          setState(() => _captureMode = CameraCaptureMode.photo)
                      : null,
                  icon: Icons.photo_camera_outlined,
                  label: Text(context.strings.photoMode),
                ),
                CupertinoPill(
                  selected: _captureMode == CameraCaptureMode.video,
                  onPressed: canChangeMode
                      ? () =>
                          setState(() => _captureMode = CameraCaptureMode.video)
                      : null,
                  icon: Icons.videocam_outlined,
                  label: Text(context.strings.videoMode),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _buildLiveBody(context, controller)),
      ],
    );
  }

  Widget _buildLiveBody(BuildContext context, CameraController? controller) {
    final strings = context.strings;

    if (!supportsInAppCameraCapture) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            strings.cameraUnsupportedPlatform,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(),
            const SizedBox(height: 16),
            Text(
              strings.cameraLoading,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      final permissionIssue = _permissionIssue;
      if (permissionIssue != null) {
        final message = switch (permissionIssue) {
          _PermissionKind.camera => strings.cameraPermissionOpenSettings,
          _PermissionKind.microphone =>
            strings.microphonePermissionOpenSettings,
        };

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CupertinoActionButton(
                  onPressed: () => _openSystemSettings(permissionIssue),
                  variant: CupertinoActionButtonVariant.outline,
                  icon: Icons.settings_outlined,
                  label: strings.settingsTooltip,
                ),
              ],
            ),
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            strings.cameraInitializationFailed(_error!),
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_cameras.isEmpty ||
        controller == null ||
        !controller.value.isInitialized) {
      return Center(
        child: Text(
          strings.cameraUnavailable,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                if (_isVideoRecording)
                  Positioned(
                    top: 18,
                    left: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fiber_manual_record_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            strings.recordingVideo,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreviewBody(BuildContext context) {
    final strings = context.strings;
    final imageBytes = _previewImageBytes;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 960),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.grey.shade900,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageBytes == null
                  ? const SizedBox.shrink()
                  : Image.memory(imageBytes, fit: BoxFit.contain),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              strings.previewPhoto,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreviewBody(BuildContext context) {
    final strings = context.strings;
    final videoPath = _capturedVideoPath;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1080),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.grey.shade900,
              ),
              clipBehavior: Clip.antiAlias,
              child: videoPath == null
                  ? const SizedBox.shrink()
                  : LocalVideoPlayer(path: videoPath),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _capturedVideoDurationLabel == null
                  ? strings.previewVideo
                  : '${strings.previewVideo} · $_capturedVideoDurationLabel',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropBody(BuildContext context) {
    final strings = context.strings;
    final imageBytes = _previewImageBytes;

    if (imageBytes == null) {
      return Center(
        child: Text(
          strings.cameraUnavailable,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Crop(
        controller: _cropController,
        image: imageBytes,
        withCircleUi: false,
        baseColor: Colors.black,
        maskColor: Colors.black.withValues(alpha: 0.55),
        onCropped: (croppedImage) async {
          if (!mounted) return;
          setState(() {
            _croppedImageBytes = croppedImage;
            _previewImageBytes = croppedImage;
            _isCropping = false;
            _isCapturing = false;
          });
          context.showAppSnackBar(
            strings.photoCropped,
            tone: AppSnackBarTone.success,
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CameraController? controller) {
    final strings = context.strings;

    if (!supportsInAppCameraCapture) {
      return const SizedBox.shrink();
    }

    if (_isCropping) {
      return Row(
        children: [
          Expanded(
            child: CupertinoActionButton(
              onPressed: _isCapturing
                  ? null
                  : () => setState(() => _isCropping = false),
              expand: true,
              variant: CupertinoActionButtonVariant.outline,
              label: strings.cancelCrop,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoActionButton(
              onPressed: _isCapturing ? null : _applyCrop,
              expand: true,
              isBusy: _isCapturing,
              icon: Icons.crop,
              label: _isCapturing ? strings.croppingPhoto : strings.applyCrop,
            ),
          ),
        ],
      );
    }

    if (_hasCapturedPhoto) {
      return Row(
        children: [
          Expanded(
            child: CupertinoActionButton(
              onPressed: _isCapturing ? null : _retakePhoto,
              expand: true,
              variant: CupertinoActionButtonVariant.outline,
              icon: Icons.replay_outlined,
              label: strings.retakePhoto,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoActionButton(
              onPressed: _isCapturing ? null : _startCropping,
              expand: true,
              variant: CupertinoActionButtonVariant.tinted,
              icon: Icons.crop_outlined,
              label: strings.cropPhoto,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoActionButton(
              onPressed: _isCapturing ? null : _usePhoto,
              expand: true,
              isBusy: _isCapturing,
              icon: Icons.check_circle_outline,
              label: _isCapturing ? strings.saving : strings.usePhoto,
            ),
          ),
        ],
      );
    }

    if (_hasCapturedVideo) {
      return Row(
        children: [
          Expanded(
            child: CupertinoActionButton(
              onPressed: _isCapturing ? null : _retakeVideo,
              expand: true,
              variant: CupertinoActionButtonVariant.outline,
              icon: Icons.replay_outlined,
              label: strings.retakeVideo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoActionButton(
              onPressed: _isCapturing ? null : _useVideo,
              expand: true,
              isBusy: _isCapturing,
              icon: Icons.check_circle_outline,
              label: _isCapturing ? strings.saving : strings.useVideo,
            ),
          ),
        ],
      );
    }

    if (_captureMode == CameraCaptureMode.video) {
      return CupertinoActionButton(
        onPressed: _isCapturing
            ? null
            : _isVideoRecording
                ? _stopVideoRecording
                : (_canStartVideoRecording(controller)
                    ? _startVideoRecording
                    : null),
        expand: true,
        minHeight: 54,
        isBusy: _isCapturing,
        destructive: _isVideoRecording,
        icon: _isVideoRecording
            ? Icons.stop_circle_outlined
            : Icons.videocam_outlined,
        label: _isCapturing
            ? strings.saving
            : _isVideoRecording
                ? strings.stopVideoRecording
                : strings.startVideoRecording,
      );
    }

    return CupertinoActionButton(
      onPressed: _canCapturePhoto(controller) ? _capturePhoto : null,
      expand: true,
      minHeight: 54,
      isBusy: _isCapturing,
      icon: Icons.camera_alt_outlined,
      label: _isCapturing ? strings.saving : strings.takePhoto,
    );
  }

  bool _canCapturePhoto(CameraController? controller) {
    return !_isInitializing &&
        !_isCapturing &&
        !_isVideoRecording &&
        controller != null &&
        controller.value.isInitialized &&
        !controller.value.isTakingPicture;
  }

  bool _canStartVideoRecording(CameraController? controller) {
    return !_isInitializing &&
        !_isCapturing &&
        controller != null &&
        controller.value.isInitialized &&
        !controller.value.isTakingPicture &&
        !controller.value.isRecordingVideo;
  }

  Future<void> _loadCameras() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      _cameras = cameras;
      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _error = null;
        });
        return;
      }
      await _initializeCamera(cameras.first);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _error = error;
      });
    }
  }

  Future<void> _prepareCamera() async {
    setState(() {
      _isInitializing = true;
      _error = null;
      _permissionIssue = null;
    });

    final hasCameraPermission =
        await _requestPermission(_PermissionKind.camera);
    if (!hasCameraPermission) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _permissionIssue = _PermissionKind.camera;
        _error = 'camera_permission_denied';
      });
      return;
    }

    await _loadCameras();
  }

  Future<bool> _requestPermission(_PermissionKind kind) async {
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      return true;
    }

    try {
      return await _permissionsChannel.invokeMethod<bool>(
            'requestPermission',
            {
              'type':
                  kind == _PermissionKind.microphone ? 'microphone' : 'camera',
            },
          ) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _openSystemSettings(_PermissionKind kind) async {
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    try {
      await _permissionsChannel.invokeMethod<void>(
        'openSettings',
        {
          'type': kind == _PermissionKind.microphone ? 'microphone' : 'camera',
        },
      );
    } on PlatformException {
      // Best-effort only.
    }
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    final previousController = _controller;
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      await controller.initialize();
      await previousController?.dispose();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (error) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _error = error;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _selectedCameraIndex = nextIndex;
    await _initializeCamera(_cameras[nextIndex]);
  }

  Future<void> _capturePhoto() async {
    final strings = context.strings;
    final controller = _controller;
    if (!_canCapturePhoto(controller)) return;

    setState(() => _isCapturing = true);

    try {
      final capturedAt = DateTime.now();
      final file = await controller!.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _capturedPhotoPath = file.path;
        _capturedPhotoCapturedAt = capturedAt;
        _capturedPhotoLocation = null;
        _previewImageBytes = bytes;
        _croppedImageBytes = null;
      });
      final lookup = _resolveCapturedPhotoLocation(file.path);
      _capturedPhotoLocationLookup = lookup;
      unawaited(lookup);
    } on CameraException catch (error) {
      if (!mounted) return;
      context.showAppSnackBar(
        error.code == 'CameraAccessDenied'
            ? strings.cameraPermissionDenied
            : strings.cameraCaptureFailed(error.description ?? error.code),
        tone: AppSnackBarTone.error,
      );
    } catch (error) {
      if (!mounted) return;
      context.showAppSnackBar(
        strings.cameraCaptureFailed(error),
        tone: AppSnackBarTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _startVideoRecording() async {
    final strings = context.strings;
    final controller = _controller;
    if (!_canStartVideoRecording(controller)) return;

    final hasMicrophonePermission = await _requestPermission(
      _PermissionKind.microphone,
    );
    if (!hasMicrophonePermission) {
      if (!mounted) return;
      setState(() {
        _permissionIssue = _PermissionKind.microphone;
        _error = 'microphone_permission_denied';
      });
      return;
    }

    setState(() => _isCapturing = true);

    try {
      await controller!.prepareForVideoRecording();
      await controller.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _isVideoRecording = true;
        _videoRecordingStartedAt = DateTime.now();
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      context.showAppSnackBar(
        error.code == 'CameraAccessDenied'
            ? strings.cameraPermissionDenied
            : strings.videoRecordingFailed(error.description ?? error.code),
        tone: AppSnackBarTone.error,
      );
      setState(() => _isCapturing = false);
    } catch (error) {
      if (!mounted) return;
      context.showAppSnackBar(
        strings.videoRecordingFailed(error),
        tone: AppSnackBarTone.error,
      );
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _stopVideoRecording() async {
    final strings = context.strings;
    final controller = _controller;
    if (controller == null ||
        !controller.value.isRecordingVideo ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    final startedAt = _videoRecordingStartedAt;

    try {
      final file = await controller.stopVideoRecording();
      final seconds = startedAt == null
          ? 0
          : DateTime.now().difference(startedAt).inSeconds.clamp(0, 86400);
      if (!mounted) return;
      setState(() {
        _capturedVideoPath = file.path;
        _capturedVideoDurationLabel = _formatDuration(seconds);
        _capturedVideoCapturedAt = DateTime.now();
        _capturedVideoLocation = null;
        _isCapturing = false;
        _isVideoRecording = false;
        _videoRecordingStartedAt = null;
      });
      final lookup = _resolveCapturedVideoLocation(file.path);
      _capturedVideoLocationLookup = lookup;
      unawaited(lookup);
      context.showAppSnackBar(
        strings.videoRecordingSaved,
        tone: AppSnackBarTone.success,
      );
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _isVideoRecording = false;
        _videoRecordingStartedAt = null;
      });
      context.showAppSnackBar(
        strings.videoRecordingFailed(error.description ?? error.code),
        tone: AppSnackBarTone.error,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _isVideoRecording = false;
        _videoRecordingStartedAt = null;
      });
      context.showAppSnackBar(
        strings.videoRecordingFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhotoPath = null;
      _capturedPhotoCapturedAt = null;
      _capturedPhotoLocation = null;
      _capturedPhotoLocationLookup = null;
      _croppedImageBytes = null;
      _previewImageBytes = null;
      _isCropping = false;
    });
  }

  void _retakeVideo() {
    setState(() {
      _capturedVideoPath = null;
      _capturedVideoDurationLabel = null;
      _capturedVideoCapturedAt = null;
      _capturedVideoLocation = null;
      _capturedVideoLocationLookup = null;
      _isVideoRecording = false;
      _videoRecordingStartedAt = null;
    });
  }

  void _startCropping() {
    if (_previewImageBytes == null) return;
    setState(() => _isCropping = true);
  }

  void _applyCrop() {
    setState(() => _isCapturing = true);
    _cropController.crop();
  }

  Future<void> _usePhoto() async {
    final strings = context.strings;
    final capturedPhotoPath = _capturedPhotoPath;
    if (capturedPhotoPath == null) return;

    setState(() => _isCapturing = true);

    try {
      final locationLookup = _capturedPhotoLocationLookup;
      if (locationLookup != null) {
        await locationLookup;
      }
      final storage = ref.read(localStorageServiceProvider);
      final savedPath = _croppedImageBytes != null
          ? await storage.saveImageBytesToAppStorage(_croppedImageBytes!)
          : await storage.copyImageToAppStorage(capturedPhotoPath);
      if (!mounted) return;
      context.pop(
        CapturedMediaResult(
          type: MediaType.image,
          path: savedPath,
          capturedAt: _capturedPhotoCapturedAt,
          location: _capturedPhotoLocation,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      context.showAppSnackBar(
        strings.cameraCaptureFailed(error),
        tone: AppSnackBarTone.error,
      );
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _useVideo() async {
    final strings = context.strings;
    final capturedVideoPath = _capturedVideoPath;
    if (capturedVideoPath == null) return;

    setState(() => _isCapturing = true);

    try {
      final locationLookup = _capturedVideoLocationLookup;
      if (locationLookup != null) {
        await locationLookup;
      }
      final storage = ref.read(localStorageServiceProvider);
      final savedPath = await storage.copyVideoToAppStorage(capturedVideoPath);
      if (!mounted) return;
      context.pop(
        CapturedMediaResult(
          type: MediaType.video,
          path: savedPath,
          durationLabel: _capturedVideoDurationLabel,
          capturedAt: _capturedVideoCapturedAt,
          location: _capturedVideoLocation,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      context.showAppSnackBar(
        strings.videoRecordingFailed(error),
        tone: AppSnackBarTone.error,
      );
      setState(() => _isCapturing = false);
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _resolveCapturedPhotoLocation(String photoPath) async {
    final locale = Localizations.localeOf(context);
    final result =
        await ref.read(locationServiceProvider).lookupCurrentLocation(
              locale: locale,
            );
    if (!mounted || _capturedPhotoPath != photoPath) {
      return;
    }
    if (!result.ok || result.locationText == null) {
      return;
    }
    setState(() {
      _capturedPhotoLocation = result.locationText;
    });
  }

  Future<void> _resolveCapturedVideoLocation(String videoPath) async {
    final locale = Localizations.localeOf(context);
    final result =
        await ref.read(locationServiceProvider).lookupCurrentLocation(
              locale: locale,
            );
    if (!mounted || _capturedVideoPath != videoPath) {
      return;
    }
    if (!result.ok || result.locationText == null) {
      return;
    }
    setState(() {
      _capturedVideoLocation = result.locationText;
    });
  }
}
