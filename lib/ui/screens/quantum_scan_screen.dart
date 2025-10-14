import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/ocr/mlkit_ocr_service.dart';
import '../../services/parser_service.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import '../quantum_theme.dart';
import '../widgets/particle_system.dart';
import '../widgets/neural_glass_container.dart';
import '../widgets/confetti_animation.dart';

enum ScanState { idle, scanning, complete, error }

class QuantumScanScreen extends ConsumerStatefulWidget {
  const QuantumScanScreen({super.key});

  @override
  ConsumerState<QuantumScanScreen> createState() => _QuantumScanScreenState();
}

class _QuantumScanScreenState extends ConsumerState<QuantumScanScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  ScanState _state = ScanState.idle;
  String? _error;
  double _scanProgress = 0.0;

  // Animation controllers
  late AnimationController _logoRippleController;
  late AnimationController _scanLineController;
  late AnimationController _progressController;
  late AnimationController _tiltController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _logoRippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: -1.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _logoRippleController.dispose();
    _scanLineController.dispose();
    _progressController.dispose();
    _tiltController.dispose();
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
      builder: (context) => NeuralGlassContainer(
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(32),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(24),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: QuantumTheme.textPrimary,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(color: QuantumTheme.textSecondary),
          ),
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
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
        _state = ScanState.idle;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error picking image: $e';
        _state = ScanState.error;
      });
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    final soundManager = SoundManager();
    final hapticService = HapticService();

    await soundManager.playScanStart();
    hapticService.lightImpact();

    setState(() {
      _state = ScanState.scanning;
      _error = null;
      _scanProgress = 0.0;
    });

    // Start animations
    _logoRippleController.repeat();
    _scanLineController.forward();
    _progressController.forward();

    try {
      final ocrService = MlKitOcrService();

      // Simulate progress with smooth easing
      final lines = await ocrService.extractTextLines(_image!.path);

      if (lines.isEmpty) {
        setState(() {
          _error = 'No text detected. Please try again with better lighting.';
          _state = ScanState.error;
        });
        _stopAnimations();
        return;
      }

      final parser = ParserService();
      final parsed = parser.parseLines(lines);

      // Complete state
      setState(() {
        _state = ScanState.complete;
        _scanProgress = 1.0;
      });

      _stopAnimations();

      // Play success sound and haptic
      await soundManager.playScanComplete();
      hapticService.heavyImpact();

      // Show confetti celebration
      ConfettiBurst.celebrate(context);

      if (!mounted) return;

      // Delay navigation slightly to show completion
      await Future.delayed(const Duration(milliseconds: 800));

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
        _state = ScanState.error;
      });
      _stopAnimations();
    }
  }

  void _stopAnimations() {
    _logoRippleController.stop();
    _scanLineController.stop();
    _progressController.stop();
  }

  void _resetScan() {
    setState(() {
      _image = null;
      _state = ScanState.idle;
      _error = null;
      _scanProgress = 0.0;
    });
    _scanLineController.reset();
    _progressController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumTheme.deepSpace,
      body: Stack(
        children: [
          // Particle background
          const Positioned.fill(
            child: ParticleSystem(
              particleCount: 80,
              maxVelocity: 0.3,
            ),
          ),

          // Morphing blobs
          MorphingBlob(
            size: 320,
            color: QuantumTheme.primaryPurple.withOpacity(0.15),
            alignment: Alignment.topLeft,
          ),
          MorphingBlob(
            size: 320,
            color: QuantumTheme.primaryBlue.withOpacity(0.15),
            alignment: Alignment.bottomRight,
            duration: const Duration(seconds: 10),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  Expanded(child: _buildScanArea()),
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo with ripple effect
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: QuantumTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: QuantumTheme.neuralGlow(blurRadius: 40),
              ),
            ),
            // Logo container
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: QuantumTheme.accentGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: QuantumTheme.neuralGlow(
                  color: QuantumTheme.primaryBlue,
                  blurRadius: 60,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            // Ripple effect
            if (_state == ScanState.scanning)
              AnimatedBuilder(
                animation: _logoRippleController,
                builder: (context, child) {
                  return Container(
                    width: 96 + (40 * _logoRippleController.value),
                    height: 96 + (40 * _logoRippleController.value),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(
                          0.3 * (1 - _logoRippleController.value),
                        ),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  );
                },
              ),
          ],
        ),

        const SizedBox(height: 24),

        // Title
        const Text(
          'QUANTUM',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: QuantumTheme.textPrimary,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: QuantumTheme.primaryBlue,
                blurRadius: 30,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        ShaderMask(
          shaderCallback: (bounds) =>
              QuantumTheme.primaryGradient.createShader(bounds),
          child: const Text(
            'Neural Card Intelligence',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: QuantumTheme.successGreen.withOpacity(0.1),
            border: Border.all(
              color: QuantumTheme.successGreen.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: QuantumTheme.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Systems Online',
                style: TextStyle(
                  color: Color(0xFF86efac),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanArea() {
    return NeuralGlassContainer(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Neural scan grid
          Positioned.fill(
            child: NeuralScanGrid(
              isActive: _state == ScanState.scanning,
            ),
          ),

          // Corner labels
          _buildCornerLabels(),

          // Corner brackets
          _buildCornerBrackets(),

          // Scan line
          if (_state == ScanState.scanning)
            AnimatedBuilder(
              animation: _scanLineController,
              builder: (context, child) {
                return Positioned(
                  top: _scanLineController.value * 100,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          QuantumTheme.primaryBlue,
                          QuantumTheme.primaryPurple,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: QuantumTheme.neuralGlow(
                        color: QuantumTheme.primaryBlue,
                        blurRadius: 20,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Content
          Positioned.fill(
            child: _buildScanContent(),
          ),

          // Progress bar
          if (_state == ScanState.scanning)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: LinearProgressIndicator(
                      value: _progressController.value,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation(
                        QuantumTheme.primaryBlue,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerLabels() {
    return Stack(
      children: [
        const Positioned(
          top: 16,
          left: 16,
          child: Text(
            'RES: 4096x2560',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
              color: Color(0xFF60a5fa),
            ),
          ),
        ),
        const Positioned(
          top: 16,
          right: 16,
          child: Text(
            'AI: v4.7.2',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
              color: Color(0xFFa78bfa),
            ),
          ),
        ),
        const Positioned(
          bottom: 16,
          left: 16,
          child: Text(
            'FPS: 120',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
              color: Color(0xFF60a5fa),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Text(
            _getStatusText(),
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
              color: Color(0xFFa78bfa),
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    switch (_state) {
      case ScanState.idle:
        return 'READY';
      case ScanState.scanning:
        return 'SCANNING';
      case ScanState.complete:
        return 'COMPLETE';
      case ScanState.error:
        return 'ERROR';
    }
  }

  Widget _buildCornerBrackets() {
    final Color bracketColor = _state == ScanState.complete
        ? QuantumTheme.successGreen
        : QuantumTheme.primaryBlue;

    return CustomPaint(
      painter: _CornerBracketsPainter(color: bracketColor),
      size: Size.infinite,
    );
  }

  Widget _buildScanContent() {
    if (_image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          children: [
            Image.file(
              _image!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            if (_state == ScanState.scanning)
              Container(
                color: QuantumTheme.deepSpace.withOpacity(0.3),
              ),
            if (_state == ScanState.complete)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      QuantumTheme.successGreen.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            if (_state == ScanState.scanning)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSpinner(),
                    const SizedBox(height: 16),
                    const Text(
                      'Processing Neural Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: QuantumTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analyzing quantum patterns...',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14,
                        color: QuantumTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            if (_state == ScanState.complete)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Color(0xFF4ade80),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Scan Complete',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF86efac),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Extracting data...',
                      style: TextStyle(
                        fontSize: 14,
                        color: QuantumTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: QuantumTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_a_photo_rounded,
              size: 64,
              color: QuantumTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Initiate Neural Scan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: QuantumTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to begin quantum analysis',
            style: TextStyle(
              fontSize: 14,
              color: QuantumTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinner() {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          SizedBox(
            width: 128,
            height: 128,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor:
                  const AlwaysStoppedAnimation(QuantumTheme.primaryBlue),
              backgroundColor: QuantumTheme.primaryBlue.withOpacity(0.2),
            ),
          ),
          // Inner ring
          SizedBox(
            width: 112,
            height: 112,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor:
                  const AlwaysStoppedAnimation(QuantumTheme.primaryPurple),
              backgroundColor: QuantumTheme.primaryPurple.withOpacity(0.2),
            ),
          ),
          // Percentage
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return Text(
                '${(_progressController.value * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: QuantumTheme.textPrimary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (_image == null) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _checkAndRequestPermission(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Neural Scan'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _checkAndRequestPermission(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Gallery'),
            ),
          ),
        ],
      );
    }

    if (_state == ScanState.complete) {
      return FilledButton.icon(
        onPressed: _resetScan,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Scan Another Card'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: QuantumTheme.successGreen,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _state == ScanState.scanning ? null : _resetScan,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retake'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _state == ScanState.scanning ? null : _processImage,
            icon: _state == ScanState.scanning
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
              _state == ScanState.scanning ? 'Scanning...' : 'Extract Text',
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  final Color color;

  _CornerBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double bracketSize = 40;
    const double margin = 20;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(margin + bracketSize, margin)
        ..lineTo(margin, margin)
        ..lineTo(margin, margin + bracketSize),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - bracketSize, margin)
        ..lineTo(size.width - margin, margin)
        ..lineTo(size.width - margin, margin + bracketSize),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(margin, size.height - margin - bracketSize)
        ..lineTo(margin, size.height - margin)
        ..lineTo(margin + bracketSize, size.height - margin),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - bracketSize, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin - bracketSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
