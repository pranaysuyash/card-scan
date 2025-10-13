import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/ocr/mlkit_ocr_service.dart';
import '../../services/parser_service.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isProcessing = false;
  String? _error;
  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScaleAnim;

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
  }

  @override
  void dispose() {
    _buttonAnimController.dispose();
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
                    ? Container(
                        key: ValueKey(_image!.path),
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
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
                      )
                    : Center(
                        key: const ValueKey('empty'),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Error Message with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: _error != null ? null : 0,
              child: _error != null
                  ? Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
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
                                onPressed: _isProcessing
                                    ? null
                                    : () {
                                        _buttonAnimController
                                            .forward()
                                            .then((_) {
                                          _buttonAnimController.reverse();
                                        });
                                        _checkAndRequestPermission(
                                            ImageSource.camera);
                                      },
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
