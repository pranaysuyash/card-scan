import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/ocr/mlkit_ocr_service.dart';
import '../../services/parser_service.dart';

enum ScanMode { camera, gallery }

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final Duration _panelAnimationDuration = const Duration(milliseconds: 400);

  CameraController? _cameraController;
  late final PageController _guidePageController;
  late final AnimationController _buttonAnimController;
  late final AnimationController _guidanceIconController;
  late final Animation<double> _buttonScaleAnim;
  late final DraggableScrollableController _sheetController;

  File? _image;
  bool _isProcessing = false;
  bool _isCameraInitializing = false;
  String? _error;
  ScanMode _mode = ScanMode.camera;
  int _currentGuidePage = 0;

  @override
  void initState() {
    super.initState();
    _guidePageController = PageController();
    _guidePageController.addListener(_handleGuidePageChanged);

    _sheetController = DraggableScrollableController();

    _buttonAnimController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonAnimController, curve: Curves.easeInOut),
    );

    _guidanceIconController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _guidePageController.removeListener(_handleGuidePageChanged);
    _guidePageController.dispose();
    _sheetController.dispose();
    _buttonAnimController.dispose();
    _guidanceIconController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _handleGuidePageChanged() {
    final page = _guidePageController.page?.round() ?? 0;
    if (page != _currentGuidePage) {
      setState(() => _currentGuidePage = page);
    }
  }

  Future<void> _checkAndRequestPermission(ImageSource source) async {
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;

    final status = await permission.request();

    if (status.isGranted) {
      if (source == ImageSource.camera) {
        await _startCamera();
      } else {
        await _pickFromGallery();
      }
    } else if (status.isDenied) {
      _showPermissionDialog(
        title: 'Permission Required',
        message:
            'We need ${source == ImageSource.camera ? "camera" : "photo library"} access to scan business cards.',
        onRetry: () => _checkAndRequestPermission(source),
      );
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        title: 'Permission Required',
        message:
            'Please enable ${source == ImageSource.camera ? "camera" : "photo library"} access in Settings.',
        openSettings: true,
      );
    }
  }

  void _showPermissionDialog({
    required String title,
    required String message,
    bool openSettings = false,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (openSettings)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            )
          else if (onRetry != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  Future<void> _startCamera() async {
    if (!mounted) return;
    setState(() {
      _mode = ScanMode.camera;
      _isCameraInitializing = true;
      _error = null;
    });

    try {
      final previousController = _cameraController;
      _cameraController = null;
      await previousController?.dispose();

      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitializing = false;
      });

      _guidePageController.animateToPage(
        ScanMode.camera.index,
        duration: _panelAnimationDuration,
        curve: Curves.easeOutCubic,
      );
      _guidanceIconController.reverse();
    } catch (e) {
      setState(() {
        _error = 'Unable to start camera: $e';
        _isCameraInitializing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() {
        _mode = ScanMode.gallery;
        _isProcessing = true;
        _error = null;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        return;
      }

      if (!mounted) return;
      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = false;
      });

      _guidePageController.animateToPage(
        ScanMode.gallery.index,
        duration: _panelAnimationDuration,
        curve: Curves.easeOutCubic,
      );
      _guidanceIconController.forward();

      if (_sheetController.hasClients) {
        _sheetController.animateTo(
          0.45,
          duration: _panelAnimationDuration,
          curve: Curves.easeOutCubic,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error picking image: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      await _checkAndRequestPermission(ImageSource.camera);
      return;
    }

    try {
      setState(() {
        _error = null;
        _isProcessing = true;
      });

      final XFile file = await controller.takePicture();

      if (!mounted) return;
      setState(() {
        _image = File(file.path);
        _isProcessing = false;
      });

      if (_sheetController.hasClients) {
        _sheetController.animateTo(
          0.45,
          duration: _panelAnimationDuration,
          curve: Curves.easeOutCubic,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error capturing photo: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final ocrService = MlKitOcrService();
      final lines = await ocrService.extractTextLines(_image!.path);

      if (lines.isEmpty) {
        setState(() {
          _error =
              'No text detected. Please try again with better lighting.';
          _isProcessing = false;
        });
        return;
      }

      final parser = ParserService();
      final parsed = parser.parseLines(lines);

      if (!mounted) return;

      setState(() => _isProcessing = false);

      context.push('/review', extra: {
        'imagePath': _image!.path,
        'lines': lines,
        'parsed': parsed,
      });

      ocrService.dispose();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error processing image: $e';
        _isProcessing = false;
      });
    }
  }

  void _resetCapture() {
    setState(() => _image = null);
    if (_sheetController.hasClients) {
      _sheetController.animateTo(
        0.22,
        duration: _panelAnimationDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onModeSelected(ScanMode mode) {
    if (_mode == mode) return;

    setState(() {
      _mode = mode;
      _error = null;
    });

    if (mode == ScanMode.camera) {
      _guidanceIconController.reverse();
      _checkAndRequestPermission(ImageSource.camera);
    } else {
      _guidanceIconController.forward();
      _guidePageController.animateToPage(
        ScanMode.gallery.index,
        duration: _panelAnimationDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan Business Card',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildPreviewArea(theme)),
          if (_error != null) _buildErrorBanner(theme),
          _buildBottomSheet(theme),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.2),
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 72, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildLivePreview(theme),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.45),
                              Colors.transparent,
                              Colors.black.withOpacity(0.55),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    _buildFrostedFrame(theme, constraints),
                    _buildInstructionPager(theme),
                    _buildCaption(theme),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreview(ThemeData theme) {
    if (_image != null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Image.file(
          _image!,
          key: ValueKey(_image!.path),
          fit: BoxFit.cover,
        ),
      );
    }

    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      return CameraPreview(controller);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: const ValueKey('placeholder'),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        child: Center(
          child: _isCameraInitializing
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_camera_front_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap Capture to enable the camera',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFrostedFrame(ThemeData theme, BoxConstraints constraints) {
    final highlight = _mode == ScanMode.camera && _image == null;
    final width = constraints.maxWidth * 0.82;
    final height = width * 0.62;

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: highlight ? 8 : 2,
                  sigmaY: highlight ? 8 : 2,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.12),
                      width: 2,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(highlight ? 0.08 : 0.03),
                        Colors.white.withOpacity(highlight ? 0.02 : 0.01),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _CornerIndicator(
              highlight: highlight,
              alignment: Alignment.topLeft,
              color: theme.colorScheme.primary,
            ),
            _CornerIndicator(
              highlight: highlight,
              alignment: Alignment.topRight,
              color: theme.colorScheme.primary,
            ),
            _CornerIndicator(
              highlight: highlight,
              alignment: Alignment.bottomLeft,
              color: theme.colorScheme.primary,
            ),
            _CornerIndicator(
              highlight: highlight,
              alignment: Alignment.bottomRight,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionPager(ThemeData theme) {
    return Positioned(
      top: 24,
      left: 24,
      right: 24,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: _image == null ? 1 : 0,
        child: Column(
          children: [
            SizedBox(
              height: 110,
              child: PageView(
                controller: _guidePageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _GuideSlide(
                    title: 'Align your card',
                    description:
                        'Hold steady and keep the business card inside the frame.',
                  ),
                  _GuideSlide(
                    title: 'Use gallery photos',
                    description:
                        'Pick an existing shot where the card is well lit and sharp.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                final isActive = index == _currentGuidePage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaption(ThemeData theme) {
    final isCamera = _mode == ScanMode.camera;
    final caption = isCamera
        ? 'Center the card inside the frosted frame.'
        : 'Choose a crisp photo from your gallery to continue.';

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      left: 24,
      right: 24,
      bottom: isCamera ? 48 : 72,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: _image == null ? 1 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                AnimatedIcon(
                  icon: AnimatedIcons.search_ellipsis,
                  progress: _guidanceIconController,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    caption,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildErrorBanner(ThemeData theme) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      left: 24,
      right: 24,
      top: _error != null ? 120 : -120,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _error != null ? 1 : 0,
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.errorContainer,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error ?? '',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
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

  Widget _buildBottomSheet(ThemeData theme) {
    final hasImage = _image != null;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: hasImage ? 0.3 : 0.22,
      minChildSize: 0.18,
      maxChildSize: hasImage ? 0.65 : 0.42,
      builder: (context, scrollController) {
        return AnimatedContainer(
          duration: _panelAnimationDuration,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Text(
                  'Capture Options',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildModeToggle(theme),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: hasImage
                      ? _buildCapturedActions(theme)
                      : _buildCaptureControls(theme),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeToggle(ThemeData theme) {
    return Row(
      children: ScanMode.values.map((mode) {
        final isActive = _mode == mode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _onModeSelected(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary.withOpacity(0.15)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mode == ScanMode.camera
                          ? Icons.camera_alt_rounded
                          : Icons.photo_library_rounded,
                      size: 20,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mode == ScanMode.camera ? 'Camera' : 'Gallery',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCaptureControls(ThemeData theme) {
    final isCamera = _mode == ScanMode.camera;
    return Column(
      key: ValueKey(_mode),
      children: [
        if (isCamera) ...[
          ScaleTransition(
            scale: _buttonScaleAnim,
            child: GestureDetector(
              onTapDown: (_) => _buttonAnimController.forward(),
              onTapCancel: () => _buttonAnimController.reverse(),
              onTapUp: (_) => _buttonAnimController.reverse(),
              onTap: () {
                _capturePhoto();
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isProcessing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.camera, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      _isProcessing ? 'Capturing...' : 'Capture',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Make sure the card is well lit and readable.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          FilledButton.icon(
            onPressed:
                _isProcessing ? null : () => _checkAndRequestPermission(ImageSource.gallery),
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.photo_library_rounded),
            label: Text(
              _isProcessing ? 'Opening...' : 'Choose from Gallery',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select an existing photo to scan the card instantly.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildCapturedActions(ThemeData theme) {
    return Column(
      key: const ValueKey('captured'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: _image != null
                      ? DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to extract text',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We will analyze the card and surface the important details.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AnimatedProgressIndicator(isActive: _isProcessing),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _resetCapture,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Retake',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _processImage,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isProcessing ? 'Extracting...' : 'Extract Text',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CornerIndicator extends StatelessWidget {
  const _CornerIndicator({
    required this.highlight,
    required this.alignment,
    required this.color,
  });

  final bool highlight;
  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double inset = highlight ? -8 : -16;
    final double length = highlight ? 36 : 28;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      left: alignment.x < 0 ? inset : null,
      right: alignment.x > 0 ? inset : null,
      top: alignment.y < 0 ? inset : null,
      bottom: alignment.y > 0 ? inset : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        width: length,
        height: length,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0
                ? BorderSide(color: color, width: 3)
                : BorderSide.none,
            bottom: alignment.y > 0
                ? BorderSide(color: color, width: 3)
                : BorderSide.none,
            left: alignment.x < 0
                ? BorderSide(color: color, width: 3)
                : BorderSide.none,
            right: alignment.x > 0
                ? BorderSide(color: color, width: 3)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft
                ? const Radius.circular(18)
                : Radius.zero,
            topRight: alignment == Alignment.topRight
                ? const Radius.circular(18)
                : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft
                ? const Radius.circular(18)
                : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight
                ? const Radius.circular(18)
                : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class _GuideSlide extends StatelessWidget {
  const _GuideSlide({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AnimatedProgressIndicator extends StatelessWidget {
  const _AnimatedProgressIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isActive ? 1 : 0),
      duration: const Duration(milliseconds: 450),
      builder: (context, value, child) {
        if (value <= 0) {
          return const SizedBox.shrink();
        }
        return Opacity(
          opacity: value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 6 + (6 * value),
              child: LinearProgressIndicator(
                value: isActive ? null : value,
                backgroundColor:
                    theme.colorScheme.surfaceVariant.withOpacity(0.4),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
