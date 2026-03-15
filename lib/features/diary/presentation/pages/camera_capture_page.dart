import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CameraCapturePage extends ConsumerStatefulWidget {
  const CameraCapturePage({super.key});

  @override
  ConsumerState<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends ConsumerState<CameraCapturePage>
    with WidgetsBindingObserver {
  final CropController _cropController = CropController();

  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isCropping = false;
  Object? _error;

  String? _capturedPhotoPath;
  Uint8List? _croppedImageBytes;
  Uint8List? _previewImageBytes;

  @override
  void initState() {
    super.initState();
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
    if (controller == null || _cameras.isEmpty || _hasCapturedPhoto) return;

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
    final canSwitch = _cameras.length > 1 &&
        !_isInitializing &&
        !_isCapturing &&
        !_hasCapturedPhoto;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_isCropping ? strings.cropPhoto : strings.cameraCapture),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (canSwitch)
            IconButton(
              tooltip: strings.switchCamera,
              onPressed: _switchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
            ),
        ],
      ),
      body: _buildBody(context, controller),
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

  Widget _buildBody(BuildContext context, CameraController? controller) {
    final strings = context.strings;

    if (_isCropping) {
      return _buildCropBody(context);
    }

    if (_hasCapturedPhoto) {
      return _buildPreviewBody(context);
    }

    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(strings.cameraLoading,
                style: const TextStyle(color: Colors.white)),
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
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildPreviewBody(BuildContext context) {
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
                  _isCapturing ? strings.croppingPhoto : strings.applyCrop),
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

    return FilledButton.icon(
      onPressed: _canCapture(controller) ? _capturePhoto : null,
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

  bool _canCapture(CameraController? controller) {
    return !_isInitializing &&
        !_isCapturing &&
        controller != null &&
        controller.value.isInitialized &&
        !controller.value.isTakingPicture;
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
      enableAudio: false,
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
    if (!_canCapture(controller)) return;

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

  void _retakePhoto() {
    setState(() {
      _capturedPhotoPath = null;
      _croppedImageBytes = null;
      _previewImageBytes = null;
      _isCropping = false;
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
      context.pop(savedPath);
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
}
