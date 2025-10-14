import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/ocr/mlkit_ocr_service.dart';
import '../../services/parser_service.dart';

class ScanScreenVariantD extends ConsumerStatefulWidget {
  const ScanScreenVariantD({super.key});

  @override
  ConsumerState<ScanScreenVariantD> createState() => _ScanScreenVariantDState();
}

class _ScanScreenVariantDState extends ConsumerState<ScanScreenVariantD>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isProcessing = false;
  String? _error;
  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScaleAnim;
  late AnimationController _ambientController;
  Timer? _tipTimer;
  bool _showTips = false;
  final List<String> _scanTips = const [
    'Align card',
    'Avoid glare',
    'Fill the frame',
    'Hold steady',
  ];
  int _activeTip = 0;

  @override
  void initState() {
    super.initState();
    _buttonAnimController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonAnimController, curve: Curves.easeInOut),
    );

    _ambientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _buttonAnimController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _ambientController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showTips = true);
    });

    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _activeTip = (_activeTip + 1) % _scanTips.length;
      });
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _ambientController.dispose();
    _buttonAnimController.dispose();
    super.dispose();
  }

  void _handleCameraTap() {
    if (_isProcessing) return;
    _buttonAnimController.forward(from: 0).then((_) {
      if (mounted) {
        _buttonAnimController.reverse();
      }
    });
    _checkAndRequestPermission(ImageSource.camera);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      key: const ValueKey('empty'),
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final frameWidth = math.max(availableWidth * 0.75, 260.0);
        final frameHeight = frameWidth * 0.62;
        final parallaxShift = (_buttonAnimController.value - 0.5) * 24;
        final wave = math.sin(_ambientController.value * math.pi);
        final flashOpacity =
            math.max(0, math.sin(_buttonAnimController.value * math.pi));
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0, -0.8 + (0.2 * wave)),
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primaryContainer.withOpacity(0.25),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              top: constraints.maxHeight * 0.18 + parallaxShift,
              left: 24,
              width: 160,
              height: 160,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 450),
                opacity: _showTips ? 1.0 : 0.0,
                child: _buildBlob(
                  theme.colorScheme.primary,
                  160,
                  wave: wave,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              bottom: constraints.maxHeight * 0.12 - parallaxShift,
              right: 32,
              width: 120,
              height: 120,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 450),
                opacity: _showTips ? 0.9 : 0.0,
                child: _buildBlob(
                  theme.colorScheme.secondary,
                  120,
                  wave: -wave,
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: CustomPaint(
                  painter: _ScanFramePainter(
                    progress: _ambientController.value,
                    color: theme.colorScheme.primary,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: theme.colorScheme.surface.withOpacity(0.55),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withOpacity(0.08 + (0.04 * wave)),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.35),
                                theme.colorScheme.primary.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.add_a_photo_rounded,
                            size: 58,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Tap to start scanning',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Capture your business card and we\'ll pick out the important details for you.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: flashOpacity.clamp(0, 0.5).toDouble(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        colors: [
                          Colors.white.withOpacity(0.35),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlob(Color color, double size, {double wave = 0}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.28 + (0.04 * wave)),
            color.withOpacity(0.06),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildTipsTimeline(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _showTips ? 1.0 : 0.0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: List.generate(_scanTips.length, (index) {
            final isActive = index == _activeTip;
            final delay = 350 + (index * 70);
            return AnimatedSlide(
              duration: Duration(milliseconds: delay),
              curve: Curves.easeOutCubic,
              offset: _showTips ? Offset.zero : const Offset(0, 0.2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.only(
                    right: index == _scanTips.length - 1 ? 0 : 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.75),
                            theme.colorScheme.primary.withOpacity(0.55),
                          ],
                        )
                      : null,
                  color: isActive
                      ? null
                      : theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.45),
                  border: Border.all(
                    color: isActive
                        ? theme.colorScheme.primary.withOpacity(0.5)
                        : theme.colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: isActive ? 1.0 : 0.0,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: isActive
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      _scanTips[index],
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
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

      setState(() => _image = File(pickedFile.path));
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
    } catch (e) {
      setState(() {
        _error = 'Error processing image: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        body: Column(
          children: [
            // Image Preview with animation
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0)
                          .animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _image != null
                    ? Hero(
                        key: ValueKey(_image!.path),
                        tag: 'scan-preview',
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.file(
                              _image!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      )
                    : _buildEmptyState(context),
              ),
            ),

            if (_image == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTipsTimeline(context),
              ),

            // Error Message with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInBack,
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: _error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      key: const ValueKey('error-banner'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.1),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withOpacity(0.12),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),

            // Action Buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (_image == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ScaleTransition(
                              scale: _buttonScaleAnim,
                              child: FilledButton.icon(
                                onPressed:
                                    _isProcessing ? null : _handleCameraTap,
                                icon: const Icon(Icons.camera_alt_rounded),
                                label: const Text('Camera',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
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
                                  : () => _checkAndRequestPermission(
                                      ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded),
                              label: const Text('Gallery',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => setState(() => _image = null),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retake',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.5),
                                  width: 1.5,
                                ),
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
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_rounded),
                              label: Text(
                                _isProcessing
                                    ? 'Processing...'
                                    : 'Extract Text',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanFramePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final oscillation = math.sin(progress * math.pi);
    final inset = 14 + (oscillation * 2);
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(inset),
      const Radius.circular(28),
    );

    final glowPaint = Paint()
      ..color = color.withOpacity(0.12 + (oscillation.abs() * 0.08))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final framePaint = Paint()
      ..color = color.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 + (oscillation * 1.2)
      ..strokeCap = StrokeCap.round;

    final innerPaint = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, framePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(inset + 10),
        const Radius.circular(24),
      ),
      innerPaint,
    );

    final cornerLength = size.shortestSide * (0.12 + (oscillation * 0.015));
    final cornerPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    void drawCorner(Offset origin,
        {required bool horizontalPositive, required bool verticalPositive}) {
      final dx = horizontalPositive ? cornerLength : -cornerLength;
      final dy = verticalPositive ? cornerLength : -cornerLength;
      canvas.drawLine(origin, origin.translate(dx, 0), cornerPaint);
      canvas.drawLine(origin, origin.translate(0, dy), cornerPaint);
    }

    drawCorner(rrect.outerRect.topLeft, horizontalPositive: true, verticalPositive: true);
    drawCorner(rrect.outerRect.topRight,
        horizontalPositive: false, verticalPositive: true);
    drawCorner(rrect.outerRect.bottomLeft,
        horizontalPositive: true, verticalPositive: false);
    drawCorner(rrect.outerRect.bottomRight,
        horizontalPositive: false, verticalPositive: false);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
