import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../../models/contact.dart';
import '../../features/qr_code/services/qr_code_service.dart';
import '../quantum_theme.dart';
import '../widgets/glass_container.dart';

/// QR Code sharing screen for contacts
class QrCodeShareScreen extends ConsumerStatefulWidget {
  final Contact contact;

  const QrCodeShareScreen({
    super.key,
    required this.contact,
  });

  @override
  ConsumerState<QrCodeShareScreen> createState() => _QrCodeShareScreenState();
}

class _QrCodeShareScreenState extends ConsumerState<QrCodeShareScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final QrCodeService _qrService = QrCodeService();
  Uint8List? _qrCodeImage;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
    _generateQrCode();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateQrCode() async {
    setState(() {
      _isGenerating = true;
    });

    final result = await _qrService.generateQrCodeImage(
      contact: widget.contact,
      size: 512,
      foregroundColor: QuantumTheme.primaryBlue,
      backgroundColor: Colors.white,
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate QR code: ${failure.message}'),
            backgroundColor: QuantumTheme.errorRed,
          ),
        );
      },
      (imageData) {
        setState(() {
          _qrCodeImage = imageData;
          _isGenerating = false;
        });
      },
    );
  }

  Future<void> _shareQrCode() async {
    if (_qrCodeImage == null) return;

    try {
      // Save temp file and share
      // In production, would save to temp directory
      await Share.share(
        'Contact: ${widget.contact.fullName}\nScan this QR code to import',
        subject: 'Business Card - ${widget.contact.fullName}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: $e'),
          backgroundColor: QuantumTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              QuantumTheme.deepSpace,
              QuantumTheme.darkPurple,
              QuantumTheme.deepSpace,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      'Share Contact',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share, color: QuantumTheme.primaryBlue),
                      onPressed: _shareQrCode,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Contact info
                      Text(
                        widget.contact.fullName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.contact.title != null)
                        Text(
                          widget.contact.title!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      if (widget.contact.company != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.contact.company!,
                          style: TextStyle(
                            fontSize: 16,
                            color: QuantumTheme.primaryBlue,
                          ),
                        ),
                      ],

                      const SizedBox(height: 48),

                      // QR Code
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: GlassContainer(
                          child: Container(
                            width: 300,
                            height: 300,
                            padding: const EdgeInsets.all(20),
                            child: _isGenerating
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(
                                        QuantumTheme.primaryBlue,
                                      ),
                                    ),
                                  )
                                : _qrCodeImage != null
                                    ? _qrService.generateQrCodeWidget(
                                        contact: widget.contact,
                                        size: 260,
                                        foregroundColor: QuantumTheme.primaryBlue,
                                        backgroundColor: Colors.white,
                                      )
                                    : const Icon(
                                        Icons.qr_code_2,
                                        size: 100,
                                        color: Colors.white54,
                                      ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Instructions
                      Text(
                        'Scan to import contact',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Share button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _shareQrCode,
                            icon: const Icon(Icons.share),
                            label: const Text(
                              'Share QR Code',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: QuantumTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: QuantumTheme.primaryBlue.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// QR Scanner Screen for importing contacts
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final QrCodeService _qrService = QrCodeService();
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              QuantumTheme.deepSpace,
              QuantumTheme.darkPurple,
              QuantumTheme.deepSpace,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Scan QR Code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Scanner area
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Scanner frame
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: QuantumTheme.primaryBlue,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Stack(
                          children: [
                            // Corner decorations
                            Positioned(
                              top: 0,
                              left: 0,
                              child: _buildCorner(),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Transform.rotate(
                                angle: 1.5708,
                                child: _buildCorner(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Transform.rotate(
                                angle: -1.5708,
                                child: _buildCorner(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Transform.rotate(
                                angle: 3.14159,
                                child: _buildCorner(),
                              ),
                            ),
                            // Scanner placeholder
                            Center(
                              child: Icon(
                                Icons.qr_code_scanner,
                                size: 100,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        'Position QR code within frame',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Manual entry button
                      TextButton.icon(
                        onPressed: () {
                          // Show manual vCard input dialog
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Enter manually'),
                        style: TextButton.styleFrom(
                          foregroundColor: QuantumTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorner() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: QuantumTheme.primaryBlue,
            width: 4,
          ),
          left: BorderSide(
            color: QuantumTheme.primaryBlue,
            width: 4,
          ),
        ),
      ),
    );
  }
}
