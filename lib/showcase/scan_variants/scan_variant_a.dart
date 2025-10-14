import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/ocr/mlkit_ocr_service.dart';
import '../../services/parser_service.dart';

class ScanScreenVariantA extends ConsumerStatefulWidget {
  const ScanScreenVariantA({super.key});

  @override
  ConsumerState<ScanScreenVariantA> createState() => _ScanScreenVariantAState();
}

enum ScanMode { camera, gallery }

class _ScanScreenVariantAState extends ConsumerState<ScanScreenVariantA>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  Uint8List? _imageBytes;
  bool _isProcessing = false;
  bool _isSelectingMedia = false;
  String? _error;
  late AnimationController _modeIconController;
  late Animation<double> _modeIconProgress;
  final PageController _guidancePageController =
      PageController(viewportFraction: 0.92);

  CameraController? _cameraController;
  Future<void>? _cameraInitializationFuture;
  ScanMode _scanMode = ScanMode.camera;

  @override
  void initState() {
    super.initState();
    _modeIconController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _modeIconProgress = CurvedAnimation(
      parent: _modeIconController,
      curve: Curves.easeInOut,
    );

    _setupCamera();
  }

  @override
  void dispose() {
    _guidancePageController.dispose();
    _cameraController?.dispose();
    _modeIconController.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      if (_cameraController != null) {
        await _cameraController?.dispose();
        if (mounted) {
          setState(() {
            _cameraController = null;
            _cameraInitializationFuture = null;
          });
        }
      }
      return;
    }

    final previousController = _cameraController;
    if (previousController != null) {
      await previousController.dispose();
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera found on this device.';
        });
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      final initialization = controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraInitializationFuture = initialization;
      });
      await initialization;
      if (mounted) {
        setState(() => _error = null);
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to initialize camera: $e';
        _cameraController = null;
        _cameraInitializationFuture = null;
      });
    }
  }

  Future<bool> _checkAndRequestPermission(ImageSource source) async {
    Permission permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;

    var status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
    }

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      _showPermissionDialog(
        source,
        'Permission Required',
        'We need ${source == ImageSource.camera ? "camera" : "photo library"} access to scan business cards.',
        false,
      );
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        source,
        'Permission Required',
        'Please enable ${source == ImageSource.camera ? "camera" : "photo library"} access in Settings.',
        true,
      );
    }
    return false;
  }

  void _showPermissionDialog(
    ImageSource source,
    String title,
    String message,
    bool openSettings,
  ) {
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
          else
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                final granted = await _checkAndRequestPermission(source);
                if (!granted) return;
                if (source == ImageSource.camera) {
                  await _onCapturePressed();
                } else {
                  await _pickImage(ImageSource.gallery);
                }
              },
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      await _onCapturePressed();
      return;
    }
    final granted = await _checkAndRequestPermission(source);
    if (!granted) return;
    try {
      setState(() {
        _isSelectingMedia = true;
        _error = null;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() => _isSelectingMedia = false);
        return;
      }

      final imageFile = File(pickedFile.path);
      final imageBytes = await pickedFile.readAsBytes();

      setState(() {
        _image = imageFile;
        _imageBytes = imageBytes;
        _isSelectingMedia = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error picking image: $e';
        _isSelectingMedia = false;
      });
    }
  }

  Future<void> _onCapturePressed() async {
    final granted = await _checkAndRequestPermission(ImageSource.camera);
    if (!granted) return;

    if (_cameraController == null ||
        !(_cameraController?.value.isInitialized ?? false)) {
      await _setupCamera();
    }

    final controller = _cameraController;
    if (controller == null) return;

    try {
      setState(() {
        _isSelectingMedia = true;
        _error = null;
      });

      final initialization = _cameraInitializationFuture;
      if (initialization != null) {
        await initialization;
      }
      final file = await controller.takePicture();
      final imageBytes = await file.readAsBytes();

      setState(() {
        _image = File(file.path);
        _imageBytes = imageBytes;
        _isSelectingMedia = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error capturing image: $e';
        _isSelectingMedia = false;
      });
    }
  }

  void _switchMode(ScanMode mode) {
    if (_scanMode == mode) return;
    setState(() {
      _scanMode = mode;
      if (mode == ScanMode.gallery) {
        _modeIconController.forward();
        if (_cameraController?.value.isInitialized ?? false) {
          try {
            _cameraController?.pausePreview();
          } catch (_) {}
        }
        _guidancePageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _modeIconController.reverse();
        _guidancePageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
    if (mode == ScanMode.camera) {
      if (_cameraController != null &&
          (_cameraController?.value.isInitialized ?? false)) {
        try {
          _cameraController?.resumePreview();
        } catch (_) {}
      } else {
        _setupCamera();
      }
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
          _error = 'No text detected. Please try again with better lighting.';
          _isProcessing = false;
        });
        return;
      }

      final parser = ParserService();
      final parsed = parser.parseLines(lines);

      if (!mounted) return;

      context.push('/review', extra: {
        'imagePath': _image!.path,
        'lines': lines,
        'parsed': parsed,
      });

      ocrService.dispose();
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error processing image: $e';
        _isProcessing = false;
      });
    }
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || _cameraInitializationFuture == null) {
      return _buildEmptyPreview();
    }

    return FutureBuilder<void>(
      future: _cameraInitializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_cameraController!),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                  ],
                ),
              ),
            ),
            Center(
              child: AspectRatio(
                aspectRatio: 3.5 / 2.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.6,
                                ),
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                        ),
                        ..._buildAnimatedCorners(constraints),
                      ],
                    );
                  },
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              left: 24,
              right: 24,
              bottom: _scanMode == ScanMode.camera ? 48 : 32,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _scanMode == ScanMode.camera
                    ? _buildFloatingCaption(
                        key: const ValueKey('camera-caption'),
                        icon: Icons.center_focus_strong_rounded,
                        text: 'Align the business card inside the frame',
                      )
                    : _buildFloatingCaption(
                        key: const ValueKey('gallery-caption'),
                        icon: Icons.collections_rounded,
                        text: 'Choose a clear, well-lit card photo',
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildAnimatedCorners(BoxConstraints constraints) {
    final cornerLength = constraints.maxWidth * 0.12;
    final isActive = _image == null && _scanMode == ScanMode.camera;
    return [
      _AnimatedCorner(
        alignment: Alignment.topLeft,
        length: cornerLength,
        active: isActive,
      ),
      _AnimatedCorner(
        alignment: Alignment.topRight,
        length: cornerLength,
        active: isActive,
      ),
      _AnimatedCorner(
        alignment: Alignment.bottomLeft,
        length: cornerLength,
        active: isActive,
      ),
      _AnimatedCorner(
        alignment: Alignment.bottomRight,
        length: cornerLength,
        active: isActive,
      ),
    ];
  }

  Widget _buildFloatingCaption({
    Key? key,
    required IconData icon,
    required String text,
  }) {
    return AnimatedContainer(
      key: key,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_a_photo_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Take a photo or select from gallery',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCarousel() {
    return SizedBox(
      height: 120,
      child: PageView(
        controller: _guidancePageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _InstructionCard(
            title: 'Camera Mode',
            description:
                'Ensure the card is flat and fill the frosted frame for best OCR results.',
            icon: Icons.photo_camera_rounded,
          ),
          _InstructionCard(
            title: 'Gallery Mode',
            description:
                'Pick a sharp image with readable text and no glare for quick extraction.',
            icon: Icons.photo_library_rounded,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Scan Business Card',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: _image != null
                    ? Container(
                        key: ValueKey(_image!.path),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : (_scanMode == ScanMode.camera
                        ? _buildCameraPreview()
                        : _buildEmptyPreview()),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                height: _error != null ? null : 0,
                child: _error != null
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            _buildBottomSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    final theme = Theme.of(context);
    final hasImage = _image != null;
    final initialSize = hasImage ? 0.38 : 0.28;
    final maxSize = hasImage ? 0.75 : 0.45;

    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.25,
      maxChildSize: maxSize,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ModeToggleButton(
                        label: 'Camera',
                        icon: Icons.camera_alt_rounded,
                        selected: _scanMode == ScanMode.camera,
                        onTap: () => _switchMode(ScanMode.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModeToggleButton(
                        label: 'Gallery',
                        icon: Icons.photo_library_rounded,
                        selected: _scanMode == ScanMode.gallery,
                        onTap: () => _switchMode(ScanMode.gallery),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.12),
                      child: AnimatedIcon(
                        icon: AnimatedIcons.play_pause,
                        progress: _modeIconProgress,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInstructionCarousel(),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: hasImage
                      ? Column(
                          key: const ValueKey('actions-image'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ready to extract details',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _InteractiveButton(
                                    onTap: _isProcessing
                                        ? null
                                        : () => setState(() => _image = null),
                                    icon: Icons.refresh_rounded,
                                    label: 'Retake',
                                    style: _InteractiveButtonStyle.outlined(
                                      theme,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _InteractiveButton(
                                    onTap: _isProcessing ? null : _processImage,
                                    icon: Icons.text_snippet_rounded,
                                    label: _isProcessing
                                        ? 'Processing...'
                                        : 'Extract Text',
                                    trailing: _isProcessing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : null,
                                    style: _InteractiveButtonStyle.filled(
                                      theme,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: _isProcessing
                                  ? const AnimatedProgressIndicator()
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('actions-empty'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _scanMode == ScanMode.camera
                                  ? 'Capture instantly'
                                  : 'Select from library',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _InteractiveButton(
                              onTap: _isSelectingMedia
                                  ? null
                                  : () {
                                      if (_scanMode == ScanMode.camera) {
                                        _onCapturePressed();
                                      } else {
                                        _pickImage(ImageSource.gallery);
                                      }
                                    },
                              icon: _scanMode == ScanMode.camera
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.photo_library_rounded,
                              label: _scanMode == ScanMode.camera
                                  ? 'Tap to capture'
                                  : 'Open gallery',
                              trailing: _isSelectingMedia
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : null,
                              style: _InteractiveButtonStyle.filled(theme),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedCorner extends StatelessWidget {
  const _AnimatedCorner({
    required this.alignment,
    required this.length,
    required this.active,
  });

  final Alignment alignment;
  final double length;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(
      color: Colors.white.withOpacity(0.9),
      width: 4,
    );

    final border = Border(
      top: (alignment == Alignment.topLeft || alignment == Alignment.topRight)
          ? borderSide
          : BorderSide.none,
      right: (alignment == Alignment.topRight ||
              alignment == Alignment.bottomRight)
          ? borderSide
          : BorderSide.none,
      bottom: (alignment == Alignment.bottomLeft ||
              alignment == Alignment.bottomRight)
          ? borderSide
          : BorderSide.none,
      left:
          (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft)
              ? borderSide
              : BorderSide.none,
    );

    const radius = Radius.circular(18);
    final borderRadius = BorderRadius.only(
      topLeft: alignment == Alignment.topLeft ? radius : Radius.zero,
      topRight: alignment == Alignment.topRight ? radius : Radius.zero,
      bottomLeft: alignment == Alignment.bottomLeft ? radius : Radius.zero,
      bottomRight: alignment == Alignment.bottomRight ? radius : Radius.zero,
    );

    return Align(
      alignment: alignment,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: active ? 1 : 0.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 600),
          scale: active ? 1 : 0.8,
          child: Container(
            width: length,
            height: length,
            decoration: BoxDecoration(
              border: border,
              borderRadius: borderRadius,
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  const _ModeToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: selected ? 1.02 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.12)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.iconTheme.color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveButtonStyle {
  const _InteractiveButtonStyle._({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.border,
  });

  final Color? backgroundColor;
  final Color foregroundColor;
  final BoxBorder? border;

  factory _InteractiveButtonStyle.filled(ThemeData theme) {
    return _InteractiveButtonStyle._(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      border: null,
    );
  }

  factory _InteractiveButtonStyle.outlined(ThemeData theme) {
    return _InteractiveButtonStyle._(
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.primary,
      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
    );
  }
}

class _InteractiveButton extends StatefulWidget {
  const _InteractiveButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.style,
    this.trailing,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final _InteractiveButtonStyle style;
  final Widget? trailing;

  @override
  State<_InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<_InteractiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHighlight(bool isDown) {
    if (!mounted) return;
    if (isDown) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style;
    final onTap = widget.onTap;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onTap == null ? 0.5 : 1.0,
      child: GestureDetector(
        onTapDown: (_) {
          if (onTap != null) _handleHighlight(true);
        },
        onTapUp: (_) {
          _handleHighlight(false);
        },
        onTapCancel: () => _handleHighlight(false),
        onTap: onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: style.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: style.border,
              boxShadow: style.backgroundColor != null
                  ? [
                      BoxShadow(
                        color: style.backgroundColor!
                            .withOpacity(onTap == null ? 0.05 : 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: style.foregroundColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: style.foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: widget.trailing,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedProgressIndicator extends StatefulWidget {
  const AnimatedProgressIndicator({super.key});

  @override
  State<AnimatedProgressIndicator> createState() =>
      _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Extracting contact information...',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeInOut,
                ).value,
              ),
            );
          },
        ),
      ],
    );
  }
}
