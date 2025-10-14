import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../services/ocr/mlkit_ocr_service.dart';
import '../../services/parser_service.dart';

class ScanScreenVariantC extends ConsumerStatefulWidget {
  const ScanScreenVariantC({super.key});

  @override
  ConsumerState<ScanScreenVariantC> createState() => _ScanScreenVariantCState();
}

class _ScanScreenVariantCState extends ConsumerState<ScanScreenVariantC>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isProcessing = false;
  String? _error;
  String? _tip = 'Align the card edges with the floating frame.';
  bool _showSuccess = false;

  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScaleAnim;
  late AnimationController _blobController;
  late AnimationController _pulseController;
  late AnimationController _heroController;
  late PageController _copyController;
  Timer? _copyTimer;
  int _copyIndex = 0;
  double _tiltX = 0;
  double _tiltY = 0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  late final VoidCallback _heroListener;

  static const _microcopy = [
    'Tip: Capture cards on a contrasting surface for clearer edges.',
    'Auto-detect will crop the card before OCR kicks in.',
    'We never upload photos—everything happens securely on-device.'
  ];

  double _heroOpacity = 1;

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

    _blobController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _heroListener = () {
      if (!mounted) return;
      setState(() {
        _heroOpacity = 0.8 + (_heroController.value * 0.2);
      });
    };
    _heroController.addListener(_heroListener);

    _copyController = PageController();
    _copyTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _copyIndex = (_copyIndex + 1) % _microcopy.length;
      _copyController.animateToPage(
        _copyIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {});
    });

    _accelerometerSub = accelerometerEvents.listen((event) {
      const smoothing = 0.12;
      final normalizedX = (event.y / 10).clamp(-1.0, 1.0);
      final normalizedY = (event.x / 10).clamp(-1.0, 1.0);
      if (!mounted) return;
      setState(() {
        _tiltX = _tiltX * (1 - smoothing) + normalizedX * smoothing;
        _tiltY = _tiltY * (1 - smoothing) + normalizedY * smoothing;
      });
    });
  }

  @override
  void dispose() {
    _buttonAnimController.dispose();
    _blobController.dispose();
    _pulseController.dispose();
    _heroController.removeListener(_heroListener);
    _heroController.dispose();
    _copyController.dispose();
    _copyTimer?.cancel();
    _accelerometerSub?.cancel();
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
        _tip = 'Hold steady—we\'ll auto-enhance for clarity.';
        _showSuccess = false;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() {
          _isProcessing = false;
          _tip = 'Align the card edges with the floating frame.';
        });
        return;
      }

      HapticFeedback.lightImpact();
      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = false;
        _tip = 'Looks sharp! Review the card or retake if needed.';
      });
    } catch (e) {
      setState(() {
        _error = 'Error picking image: $e';
        _isProcessing = false;
        _tip = 'Something went wrong—try again or pick from gallery.';
      });
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
      _tip = 'Processing card… Sit tight!';
      _showSuccess = false;
    });

    final ocrService = MlKitOcrService();

    try {
      final lines = await ocrService.extractTextLines(_image!.path);

      if (lines.isEmpty) {
        setState(() {
          _error = 'No text detected. Please try again with better lighting.';
          _isProcessing = false;
          _tip = 'Try a brighter spot or tap Retake for another shot.';
        });
        HapticFeedback.heavyImpact();
        return;
      }

      final parser = ParserService();
      final parsed = parser.parseLines(lines);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _showSuccess = true;
        _tip = 'Text captured! Opening details…';
      });
      HapticFeedback.lightImpact();

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      context.push('/review', extra: {
        'imagePath': _image!.path,
        'lines': lines,
        'parsed': parsed,
      });

      setState(() {
        _showSuccess = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error processing image: $e';
        _isProcessing = false;
        _tip = 'We hit a snag—double-check the photo and try again.';
        _showSuccess = false;
      });
      HapticFeedback.heavyImpact();
    } finally {
      ocrService.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final curvedPulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan Business Card',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _AnimatedBackdrop(
              animation: CurvedAnimation(
                parent: _blobController,
                curve: Curves.easeInOut,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: theme.colorScheme.surface.withOpacity(0.55),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.94, end: 1.0)
                                    .animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _image != null
                              ? _ParallaxCapturedCard(
                                  key: ValueKey(_image!.path),
                                  image: _image!,
                                  tiltX: _tiltX,
                                  tiltY: _tiltY,
                                )
                              : _HeroCaptureState(
                                  heroController: _heroController,
                                  heroOpacity: _heroOpacity,
                                  microcopy: _microcopy,
                                  copyController: _copyController,
                                  activeIndex: _copyIndex,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _error == null
                          ? const SizedBox.shrink()
                          : Container(
                              key: const ValueKey('error'),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      theme.colorScheme.error.withOpacity(0.2),
                                ),
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
                            ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: AnimatedOpacity(
              opacity: _image == null ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: ScaleTransition(
                scale:
                    Tween<double>(begin: 0.96, end: 1.02).animate(curvedPulse),
                child: IgnorePointer(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.78,
                    height: MediaQuery.of(context).size.width * 0.52,
                    child: CustomPaint(
                      painter: _CardFramePainter(
                        color: theme.colorScheme.primary
                            .withOpacity(0.6 - 0.2 * curvedPulse.value),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _GlassActionSheet(
              isProcessing: _isProcessing,
              showSuccess: _showSuccess,
              tip: _tip,
              onCamera: _isProcessing
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _buttonAnimController
                          .forward()
                          .then((_) => _buttonAnimController.reverse());
                      _checkAndRequestPermission(ImageSource.camera);
                    },
              onGallery: _isProcessing
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _checkAndRequestPermission(ImageSource.gallery);
                    },
              onRetake: _isProcessing
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _image = null;
                        _tip = 'Align the card edges with the floating frame.';
                        _error = null;
                        _showSuccess = false;
                      });
                    },
              onProcess: _isProcessing ? null : _processImage,
              hasImage: _image != null,
              cameraScale: _buttonScaleAnim,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCaptureState extends StatelessWidget {
  const _HeroCaptureState({
    required this.heroController,
    required this.heroOpacity,
    required this.microcopy,
    required this.copyController,
    required this.activeIndex,
  });

  final AnimationController heroController;
  final double heroOpacity;
  final List<String> microcopy;
  final PageController copyController;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          opacity: heroOpacity,
          duration: const Duration(milliseconds: 400),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.04).animate(
              CurvedAnimation(parent: heroController, curve: Curves.easeInOut),
            ),
            child: Hero(
              tag: 'scan-hero',
              child: Container(
                width: MediaQuery.of(context).size.width * 0.66,
                height: MediaQuery.of(context).size.width * 0.42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.75),
                      theme.colorScheme.secondary.withOpacity(0.65),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.35),
                      blurRadius: 40,
                      spreadRadius: 2,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Icon(
                          Icons.auto_fix_high_rounded,
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          size: 32,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Text(
                          'Guided\nCapture',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: copyController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: microcopy.length,
                  itemBuilder: (context, index) {
                    final text = microcopy[index];
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(microcopy.length, (index) {
                  final isActive = index == activeIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: isActive ? 20 : 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParallaxCapturedCard extends StatelessWidget {
  const _ParallaxCapturedCard({
    required this.image,
    required this.tiltX,
    required this.tiltY,
    super.key,
  });

  final File image;
  final double tiltX;
  final double tiltY;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateX(tiltX * 0.35)
        ..rotateY(tiltY * -0.35),
      child: Container(
        width: size.width * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.file(
            image,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _GlassActionSheet extends StatelessWidget {
  const _GlassActionSheet({
    required this.isProcessing,
    required this.showSuccess,
    required this.tip,
    required this.onCamera,
    required this.onGallery,
    required this.onRetake,
    required this.onProcess,
    required this.hasImage,
    required this.cameraScale,
  });

  final bool isProcessing;
  final bool showSuccess;
  final String? tip;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onRetake;
  final VoidCallback? onProcess;
  final bool hasImage;
  final Animation<double> cameraScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTip = tip ?? 'Ready when you are!';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.75),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.1),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isProcessing) const LinearProgressIndicator(minHeight: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: showSuccess
                      ? Row(
                          key: const ValueKey('success'),
                          children: [
                            AnimatedScale(
                              scale: showSuccess ? 1 : 0.9,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutBack,
                              child: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primary.withOpacity(0.2),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Card scanned successfully!',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          key: const ValueKey('tip'),
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Text(
                            effectiveTip,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: hasImage
                      ? Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onRetake,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retake'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  side: BorderSide(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: onProcess,
                                icon: isProcessing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_rounded),
                                label: Text(
                                  isProcessing ? 'Processing…' : 'Extract Text',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ScaleTransition(
                                scale: cameraScale,
                                child: FilledButton.icon(
                                  onPressed: onCamera,
                                  icon: const Icon(Icons.camera_alt_rounded),
                                  label: const Text('Camera'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onGallery,
                                icon: const Icon(Icons.photo_library_rounded),
                                label: const Text('Gallery'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  side: BorderSide(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBackdrop extends StatelessWidget {
  const _AnimatedBackdrop({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ],
            ),
          ),
          child: Stack(
            children: [
              _GradientBlob(
                top: lerpDouble(-240, 120, value)!,
                left: lerpDouble(-160, 80, Curves.easeInOut.transform(value))!,
                size: 420,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.45),
                  theme.colorScheme.primaryContainer.withOpacity(0.1),
                ],
              ),
              _GradientBlob(
                bottom: lerpDouble(-180, 100, value)!,
                right: lerpDouble(
                    -140, 40, Curves.easeInOut.transform(1 - value))!,
                size: 360,
                colors: [
                  theme.colorScheme.secondary.withOpacity(0.45),
                  theme.colorScheme.secondaryContainer.withOpacity(0.1),
                ],
              ),
              _GradientBlob(
                top: lerpDouble(200, 40, value)!,
                right: lerpDouble(-120, 140, value)!,
                size: 260,
                colors: [
                  theme.colorScheme.tertiary.withOpacity(0.35),
                  theme.colorScheme.tertiaryContainer.withOpacity(0.1),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GradientBlob extends StatelessWidget {
  const _GradientBlob({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.colors,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: colors,
          ),
        ),
      ),
    );
  }
}

class _CardFramePainter extends CustomPainter {
  _CardFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(24),
    );
    canvas.drawRRect(rrect, paint);

    final cornerPaint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    final corners = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];

    for (final corner in corners) {
      final horizontalEnd = Offset(
        corner.dx + (corner.dx == 0 ? cornerLength : -cornerLength),
        corner.dy,
      );
      final verticalEnd = Offset(
        corner.dx,
        corner.dy + (corner.dy == 0 ? cornerLength : -cornerLength),
      );
      canvas.drawLine(corner, horizontalEnd, cornerPaint);
      canvas.drawLine(corner, verticalEnd, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardFramePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
