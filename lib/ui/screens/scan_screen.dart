import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/ocr/mlkit_ocr_service.dart';
import '../../services/parser_service.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isProcessing = false;
  String? _error;
  bool _showSuccess = false;

  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScaleAnim;
  late AnimationController _heroController;
  late Animation<double> _heroScaleAnim;
  late AnimationController _blobController;
  late AnimationController _framePulseController;
  late Animation<double> _framePulseAnim;

  final List<String> _microcopy = const [
    'Position the card within the frame to capture crisp details.',
    'Good lighting helps the scanner read names and titles clearly.',
    'Try to keep your phone steady for the best OCR accuracy.',
  ];
  int _carouselIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _buttonAnimController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonAnimController, curve: Curves.easeInOut),
    );

    _heroController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _heroScaleAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeInOut),
    );

    _blobController = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat();

    _framePulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _framePulseAnim = CurvedAnimation(
      parent: _framePulseController,
      curve: Curves.easeInOut,
    );

    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _carouselIndex = (_carouselIndex + 1) % _microcopy.length;
      });
    });
  }

  @override
  void dispose() {
    _buttonAnimController.dispose();
    _heroController.dispose();
    _blobController.dispose();
    _framePulseController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndRequestPermission(ImageSource source) async {
    Permission permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;

    final status = await permission.request();

    if (status.isGranted) {
      await _pickImage(source);
    } else if (status.isDenied) {
      _showPermissionDialog(
        'Permission Required',
        'We need ${source == ImageSource.camera ? "camera" : "photo library"} access to scan business cards.',
        false,
      );
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        'Permission Required',
        'Please enable ${source == ImageSource.camera ? "camera" : "photo library"} access in Settings.',
        true,
      );
    }
  }

  void _showPermissionDialog(String title, String message, bool openSettings) {
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
              onPressed: () {
                Navigator.pop(context);
                _checkAndRequestPermission(ImageSource.camera);
              },
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isProcessing = true;
        _error = null;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error picking image: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
      _showSuccess = false;
    });

    try {
      final ocrService = MlKitOcrService();
      final lines = await ocrService.extractTextLines(_image!.path);

      if (lines.isEmpty) {
        setState(() {
          _error = 'No text detected. Please try again with better lighting.';
          _isProcessing = false;
        });
        ocrService.dispose();
        return;
      }

      final parser = ParserService();
      final parsed = parser.parseLines(lines);

      if (!mounted) {
        ocrService.dispose();
        return;
      }

      setState(() {
        _isProcessing = false;
        _showSuccess = true;
      });
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) {
        ocrService.dispose();
        return;
      }

      setState(() {
        _showSuccess = false;
      });

      context.push('/review', extra: {
        'imagePath': _image!.path,
        'lines': lines,
        'parsed': parsed,
      });

      ocrService.dispose();
    } catch (e) {
      setState(() {
        _error = 'Error processing image: $e';
        _isProcessing = false;
        _showSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'Scan Business Card',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceVariant.withOpacity(0.45),
                ],
              ),
            ),
          ),
          Positioned(
            top: -size.height * 0.15 +
                math.sin(_blobController.value * 2 * math.pi) * 20,
            left: -size.width * 0.25,
            child: _GradientBlob(
              size: size.width * 0.9,
              colors: [
                theme.colorScheme.primary.withOpacity(0.25),
                theme.colorScheme.tertiary.withOpacity(0.2),
              ],
            ),
          ),
          Positioned(
            bottom: -size.height * 0.2 +
                math.cos((_blobController.value + 0.35) * 2 * math.pi) * 25,
            right: -size.width * 0.15,
            child: _GradientBlob(
              size: size.width * 0.7,
              colors: [
                theme.colorScheme.secondaryContainer.withOpacity(0.25),
                theme.colorScheme.primary.withOpacity(0.18),
              ],
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                color: theme.colorScheme.surface.withOpacity(0.35),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: AnimatedBuilder(
                          animation: _framePulseAnim,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _CameraFramePainter(
                                color: theme.colorScheme.primary,
                                progress: _framePulseAnim.value,
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 600),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.95, end: 1.0)
                                  .animate(animation),
                              child: child,
                            ),
                          ),
                          child: _image != null
                              ? OrientationBuilder(
                                  key: ValueKey(_image!.path),
                                  builder: (context, orientation) {
                                    final tilt = orientation == Orientation.portrait
                                        ? 0.05
                                        : -0.05;
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 500),
                                      curve: Curves.easeOutCubic,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateX(tilt * 0.7)
                                        ..rotateY(tilt),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.2),
                                            blurRadius: 32,
                                            offset: const Offset(0, 16),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Image.file(
                                          _image!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : _buildEmptyState(theme),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildErrorBanner(theme),
              const SizedBox(height: 12),
              _buildBottomSheet(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      key: const ValueKey('empty'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _heroScaleAnim,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _image == null ? 1 : 0,
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.18),
                    theme.colorScheme.primaryContainer.withOpacity(0.06),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.center_focus_strong_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _microcopy[_carouselIndex],
            key: ValueKey(_carouselIndex),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _microcopy.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: index == _carouselIndex ? 24 : 8,
              decoration: BoxDecoration(
                color: index == _carouselIndex
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _error != null
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildBottomSheet(ThemeData theme) {
    final tip = _showSuccess
        ? 'Text extracted successfully!'
        : _isProcessing
            ? 'Analyzing card... hold steady.'
            : 'Tap Camera or Gallery to begin scanning.';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface.withOpacity(0.72),
                    theme.colorScheme.surfaceVariant.withOpacity(0.55),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tip,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : _showSuccess
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    key: const ValueKey('success'),
                                    color: theme.colorScheme.primary,
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_image == null)
                    Row(
                      children: [
                        Expanded(
                          child: ScaleTransition(
                            scale: _buttonScaleAnim,
                            child: FilledButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () {
                                      HapticFeedback.mediumImpact();
                                      _buttonAnimController.forward().then((_) {
                                        _buttonAnimController.reverse();
                                      });
                                      _checkAndRequestPermission(ImageSource.camera);
                                    },
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text(
                                'Camera',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    _checkAndRequestPermission(ImageSource.gallery);
                                  },
                            icon: const Icon(Icons.photo_library_rounded),
                            label: const Text(
                              'Gallery',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              side: BorderSide(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _image = null;
                                    });
                                  },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text(
                              'Retake',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              side: BorderSide(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed:
                                _isProcessing || _image == null ? null : _processImage,
                            icon: const Icon(Icons.auto_fix_high_rounded),
                            label: Text(
                              _isProcessing ? 'Processing...' : 'Extract Text',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientBlob extends StatelessWidget {
  const _GradientBlob({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
          stops: const [0.1, 1],
        ),
      ),
    );
  }
}

class _CameraFramePainter extends CustomPainter {
  const _CameraFramePainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 3.0 + math.sin(progress * math.pi) * 0.8;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(12),
      const Radius.circular(28),
    );
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    const dashLength = 16.0;
    const gap = 10.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CameraFramePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
