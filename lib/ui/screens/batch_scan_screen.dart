import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/batch_scan/models/scan_session.dart';
import '../../features/batch_scan/services/batch_processing_service.dart';
import '../../features/subscription/services/subscription_service.dart';
import '../../services/haptic_service.dart';
import '../quantum_theme.dart';
import '../widgets/glass_container.dart';

/// Batch scanning screen for processing multiple business cards
class BatchScanScreen extends ConsumerStatefulWidget {
  const BatchScanScreen({super.key});

  @override
  ConsumerState<BatchScanScreen> createState() => _BatchScanScreenState();
}

class _BatchScanScreenState extends ConsumerState<BatchScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _sessionNameController = TextEditingController();
  final TextEditingController _eventNameController = TextEditingController();

  List<String> _selectedImages = [];
  bool _isProcessing = false;
  BatchProgress? _progress;

  @override
  void dispose() {
    _sessionNameController.dispose();
    _eventNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final subscriptionService = SubscriptionService();

    // Check if user can access batch processing
    if (!subscriptionService.canAccessFeature(ProFeature.batchProcessing)) {
      _showPaywall();
      return;
    }

    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((img) => img.path));
        });
        HapticService().mediumImpact();
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Future<void> _startProcessing() async {
    if (_selectedImages.isEmpty) {
      _showError('Please select some images first');
      return;
    }

    if (_sessionNameController.text.isEmpty) {
      _showError('Please enter a session name');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Create batch processing service would go here
    // For now, simulate processing
    HapticService().heavyImpact();

    // Navigate to processing screen
    if (mounted) {
      context.push('/batch-processing', extra: {
        'images': _selectedImages,
        'sessionName': _sessionNameController.text,
        'eventName': _eventNameController.text,
      });
    }
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SubscriptionPaywallSheet(
        feature: 'Batch Processing',
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: QuantumTheme.errorRed,
      ),
    );
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Batch Scan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: QuantumTheme.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: QuantumTheme.primaryBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${_selectedImages.length} cards',
                        style: const TextStyle(
                          color: QuantumTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Session details
              Padding(
                padding: const EdgeInsets.all(16),
                child: GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Session Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _sessionNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Session Name *',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            hintText: 'e.g., Tech Summit 2025',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _eventNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Event Name (optional)',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            hintText: 'e.g., Annual Conference',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Selected images grid
              Expanded(
                child: _selectedImages.isEmpty
                    ? _buildEmptyState()
                    : _buildImageGrid(),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Cards'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: QuantumTheme.primaryBlue,
                          side: const BorderSide(
                            color: QuantumTheme.primaryBlue,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedImages.isEmpty || _isProcessing
                            ? null
                            : _startProcessing,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(Icons.play_arrow),
                        label: Text(_isProcessing ? 'Processing...' : 'Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: QuantumTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_outlined,
            size: 120,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No cards added yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap "Add Cards" to select business card images',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            GlassContainer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _selectedImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white.withOpacity(0.1),
                      child: const Icon(
                        Icons.credit_card,
                        size: 48,
                        color: Colors.white54,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImages.removeAt(index);
                  });
                  HapticService().lightImpact();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Subscription paywall sheet
class SubscriptionPaywallSheet extends StatelessWidget {
  final String feature;

  const SubscriptionPaywallSheet({
    super.key,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuantumTheme.deepSpace,
            QuantumTheme.darkPurple,
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Icon(
            Icons.workspace_premium,
            size: 80,
            color: QuantumTheme.primaryBlue,
          ),
          const SizedBox(height: 24),
          Text(
            'Upgrade to Pro',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$feature is a Pro feature',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildFeature('Unlimited contacts'),
                _buildFeature('Batch processing'),
                _buildFeature('Cloud sync'),
                _buildFeature('QR code generation'),
                _buildFeature('Voice notes'),
                _buildFeature('No ads'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/subscription');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuantumTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Upgrade Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: QuantumTheme.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
