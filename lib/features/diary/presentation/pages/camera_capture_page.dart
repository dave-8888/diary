import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/models/captured_media_result.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/local_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum CameraCaptureMode { photo, video }

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

  String? _capturedPhotoPath;
  String? _capturedVideoPath;
  String? _capturedVideoDurationLabel;
  Uint8List? _croppedImageBytes;
  Uint8List? _previewImageBytes;
  DateTime? _videoRecordingStartedAt;

  @override
  void initState() {
    super.initState();
    _captureMode = widget.initialMode;
    WidgetsBinding.instance.addObserver(this);
    _loadCameras();
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_pageTitle(strings)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (canSwitchCamera)
            IconButton(
              tooltip: strings.switchCamera,
              onPressed: _switchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
            ),
        ],
      ),
      body: _buildBody(context, controller, canChangeMode),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: _buildBottomBar(context, controller),
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
            child: SegmentedButton<CameraCaptureMode>(
              segments: [
                ButtonSegment(
                  value: CameraCaptureMode.photo,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(context.strings.photoMode),
                ),
                ButtonSegment(
                  value: CameraCaptureMode.video,
                  icon: const Icon(Icons.videocam_outlined),
                  label: Text(context.strings.videoMode),
                ),
              ],
              selected: {_captureMode},
              onSelectionChanged: canChangeMode
                  ? (selection) {
                      setState(() => _captureMode = selection.first);
                    }
                  : null,
            ),
          ),
        ),
        Expanded(child: _buildLiveBody(context, controller)),
      ],
    );
  }

  Widget _buildLiveBody(BuildContext context, CameraController? controller) {
    final strings = context.strings;

    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
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
                        color: Colors.redAccent.withOpacity(0.92),
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
        maskColor: Colors.black.withOpacity(0.55),
        onCropped: (croppedImage) async {
          if (!mounted) return;
          setState(() {
            _croppedImageBytes = croppedImage;
            _previewImageBytes = croppedImage;
            _isCropping = false;
            _isCapturing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.photoCropped)),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CameraController? controller) {
    final strings = context.strings;

    if (_isCropping) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isCapturing
                  ? null
                  : () => setState(() => _isCropping = false),
              child: Text(strings.cancelCrop),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isCapturing ? null : _applyCrop,
              icon: _isCapturing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.crop),
              label: Text(
                _isCapturing ? strings.croppingPhoto : strings.applyCrop,
              ),
            ),
          ),
        ],
      );
    }

    if (_hasCapturedPhoto) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isCapturing ? null : _retakePhoto,
              icon: const Icon(Icons.replay_outlined),
              label: Text(strings.retakePhoto),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: _isCapturing ? null : _startCropping,
              icon: const Icon(Icons.crop_outlined),
              label: Text(strings.cropPhoto),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isCapturing ? null : _usePhoto,
              icon: _isCapturing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isCapturing ? strings.saving : strings.usePhoto),
            ),
          ),
        ],
      );
    }

    if (_hasCapturedVideo) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isCapturing ? null : _retakeVideo,
              icon: const Icon(Icons.replay_outlined),
              label: Text(strings.retakeVideo),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isCapturing ? null : _useVideo,
              icon: _isCapturing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isCapturing ? strings.saving : strings.useVideo),
            ),
          ),
        ],
      );
    }

    if (_captureMode == CameraCaptureMode.video) {
      return FilledButton.icon(
        onPressed: _isCapturing
            ? null
            : _isVideoRecording
                ? _stopVideoRecording
                : (_canStartVideoRecording(controller)
                    ? _startVideoRecording
                    : null),
        icon: _isCapturing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _isVideoRecording
                    ? Icons.stop_circle_outlined
                    : Icons.videocam_outlined,
              ),
        label: Text(
          _isCapturing
              ? strings.saving
              : _isVideoRecording
                  ? strings.stopVideoRecording
                  : strings.startVideoRecording,
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: _isVideoRecording ? Colors.redAccent : null,
        ),
      );
    }

    return FilledButton.icon(
      onPressed: _canCapturePhoto(controller) ? _capturePhoto : null,
      icon: _isCapturing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.camera_alt_outlined),
      label: Text(_isCapturing ? strings.saving : strings.takePhoto),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
      ),
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
      final file = await controller!.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _capturedPhotoPath = file.path;
        _previewImageBytes = bytes;
        _croppedImageBytes = null;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'CameraAccessDenied'
                ? strings.cameraPermissionDenied
                : strings.cameraCaptureFailed(error.description ?? error.code),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.cameraCaptureFailed(error))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'CameraAccessDenied'
                ? strings.cameraPermissionDenied
                : strings.videoRecordingFailed(error.description ?? error.code),
          ),
        ),
      );
      setState(() => _isCapturing = false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.videoRecordingFailed(error))),
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
        _isCapturing = false;
        _isVideoRecording = false;
        _videoRecordingStartedAt = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.videoRecordingSaved)),
      );
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _isVideoRecording = false;
        _videoRecordingStartedAt = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                strings.videoRecordingFailed(error.description ?? error.code))),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _isVideoRecording = false;
        _videoRecordingStartedAt = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.videoRecordingFailed(error))),
      );
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhotoPath = null;
      _croppedImageBytes = null;
      _previewImageBytes = null;
      _isCropping = false;
    });
  }

  void _retakeVideo() {
    setState(() {
      _capturedVideoPath = null;
      _capturedVideoDurationLabel = null;
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
      final storage = ref.read(localStorageServiceProvider);
      final savedPath = _croppedImageBytes != null
          ? await storage.saveImageBytesToAppStorage(_croppedImageBytes!)
          : await storage.copyImageToAppStorage(capturedPhotoPath);
      if (!mounted) return;
      context.pop(
        CapturedMediaResult(
          type: MediaType.image,
          path: savedPath,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.cameraCaptureFailed(error))),
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
      final storage = ref.read(localStorageServiceProvider);
      final savedPath = await storage.copyVideoToAppStorage(capturedVideoPath);
      if (!mounted) return;
      context.pop(
        CapturedMediaResult(
          type: MediaType.video,
          path: savedPath,
          durationLabel: _capturedVideoDurationLabel,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.videoRecordingFailed(error))),
      );
      setState(() => _isCapturing = false);
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
