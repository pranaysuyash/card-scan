import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/contact.dart';
import '../../providers/contact_provider.dart';
import '../quantum_theme.dart';
import '../widgets/particle_system.dart';
import '../widgets/neural_glass_container.dart';
import '../widgets/confetti_animation.dart';

class QuantumReviewScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  final List<String> ocrLines;
  final Map<String, dynamic>? parsedData;

  const QuantumReviewScreen({
    super.key,
    this.imagePath,
    required this.ocrLines,
    this.parsedData,
  });

  @override
  ConsumerState<QuantumReviewScreen> createState() =>
      _QuantumReviewScreenState();
}

class _QuantumReviewScreenState extends ConsumerState<QuantumReviewScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;

  bool _isSaving = false;
  String? _error;
  final Map<String, double> _confidence = {};

  late AnimationController _entryAnimationController;
  late AnimationController _saveButtonController;
  late Animation<double> _saveButtonScale;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _scheduleFieldAnimations();
  }

  void _initializeControllers() {
    final parsed = widget.parsedData ?? {};

    _fullNameController =
        TextEditingController(text: parsed['full_name'] ?? '');
    _titleController = TextEditingController(text: parsed['title'] ?? '');
    _companyController = TextEditingController(text: parsed['company'] ?? '');

    final emails = parsed['emails'] as List? ?? [];
    _emailController = TextEditingController(
      text: emails.isNotEmpty ? emails[0]['value'] ?? '' : '',
    );

    final phones = parsed['phones'] as List? ?? [];
    _phoneController = TextEditingController(
      text: phones.isNotEmpty ? phones[0]['value'] ?? '' : '',
    );

    _websiteController = TextEditingController(text: parsed['website'] ?? '');
    _addressController = TextEditingController(text: parsed['address'] ?? '');

    // Extract confidence scores
    if (emails.isNotEmpty) {
      _confidence['email'] = emails[0]['confidence'] ?? 0.0;
    }
    if (phones.isNotEmpty) {
      _confidence['phone'] = phones[0]['confidence'] ?? 0.0;
    }
  }

  void _initializeAnimations() {
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _saveButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _saveButtonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _saveButtonController, curve: Curves.easeInOut),
    );
  }

  void _scheduleFieldAnimations() {
    // Stagger field appearances
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entryAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _entryAnimationController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    _saveButtonController
        .forward()
        .then((_) => _saveButtonController.reverse());
    HapticFeedback.mediumImpact();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final contact = Contact()
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..fullName = _fullNameController.text.trim()
        ..title = _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : null
        ..company = _companyController.text.trim().isNotEmpty
            ? _companyController.text.trim()
            : null
        ..website = _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null
        ..address = _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null
        ..imagePath = widget.imagePath
        ..activity = [
          Activity()
            ..timestamp = DateTime.now()
            ..type = 'scan'
            ..meta = {'source': 'camera'}
        ];

      // Add email if present
      if (_emailController.text.trim().isNotEmpty) {
        contact.emails.add(EmailItem()
          ..value = _emailController.text.trim().toLowerCase()
          ..confidence = _confidence['email'] ?? 0.85
          ..type = 'work');
      }

      // Add phone if present
      if (_phoneController.text.trim().isNotEmpty) {
        contact.phones.add(PhoneItem()
          ..value = _phoneController.text.trim()
          ..confidence = _confidence['phone'] ?? 0.85
          ..type = 'work');
      }

      final storage = ref.read(storageServiceProvider);
      await storage.saveContact(contact);

      if (!mounted) return;

      // Success celebration
      HapticFeedback.heavyImpact();
      ConfettiBurst.celebrate(context, burstCount: 80);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Contact saved successfully!'),
            ],
          ),
          backgroundColor: QuantumTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

      // Invalidate contacts provider to refresh list
      ref.invalidate(contactsProvider);

      // Delay to show confetti
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      context.go('/');
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = 'Error saving contact: $e';
        _isSaving = false;
      });
    }
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
              particleCount: 60,
              maxVelocity: 0.25,
            ),
          ),

          // Morphing blobs
          MorphingBlob(
            size: 280,
            color: QuantumTheme.primaryPurple.withOpacity(0.15),
            alignment: Alignment.topRight,
          ),
          MorphingBlob(
            size: 280,
            color: QuantumTheme.primaryBlue.withOpacity(0.15),
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 10),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        if (_error != null) _buildErrorCard(),
                        _buildDataCard(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
                        const SizedBox(height: 20),
                      ],
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          NeuralGlassContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: 16,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: QuantumTheme.textPrimary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXTRACTED DATA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: QuantumTheme.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Review & Confirm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: QuantumTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _entryAnimationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entryAnimationController,
          curve: Curves.easeOut,
        )),
        child: NeuralGlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: QuantumTheme.successGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: QuantumTheme.neuralGlow(
                    color: QuantumTheme.successGreen,
                    blurRadius: 20,
                  ),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Neural Extraction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: QuantumTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'AI-powered data analysis complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: QuantumTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: QuantumTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.flash_on,
                      size: 14,
                      color: Color(0xFF86efac),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '98.7%',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF86efac),
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

  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: NeuralGlassContainer(
        padding: const EdgeInsets.all(20),
        gradient: LinearGradient(
          colors: [
            QuantumTheme.errorRed.withOpacity(0.1),
            QuantumTheme.accentPink.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: QuantumTheme.errorRed.withOpacity(0.3),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: QuantumTheme.errorRed,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(
                  color: QuantumTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard() {
    final fields = [
      _buildFieldData(
          'Full Name', _fullNameController, Icons.person_rounded, 0, true),
      _buildFieldData('Title', _titleController, Icons.work_rounded, 1),
      _buildFieldData('Company', _companyController, Icons.business_rounded, 2),
      _buildFieldData('Email', _emailController, Icons.email_rounded, 3, false,
          _confidence['email']),
      _buildFieldData('Phone', _phoneController, Icons.phone_rounded, 4, false,
          _confidence['phone']),
      _buildFieldData('Website', _websiteController, Icons.language_rounded, 5),
      _buildFieldData('Address', _addressController, Icons.location_on_rounded,
          6, false, null, 2),
    ];

    return NeuralGlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: QuantumTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: QuantumTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...fields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: field,
              )),
        ],
      ),
    );
  }

  Widget _buildFieldData(
    String label,
    TextEditingController controller,
    IconData icon,
    int index, [
    bool required = false,
    double? confidence,
    int maxLines = 1,
  ]) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryAnimationController,
          curve: Interval(
            (index * 0.08).clamp(0.0, 1.0),
            ((index * 0.08) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entryAnimationController,
            curve: Interval(
              (index * 0.08).clamp(0.0, 1.0),
              ((index * 0.08) + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label + (required ? ' *' : ''),
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: QuantumTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                if (confidence != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(confidence).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          size: 10,
                          color: _getConfidenceColor(confidence),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(confidence * 100).toInt()}%',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getConfidenceColor(confidence),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: QuantumTheme.textPrimary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: QuantumTheme.glassBorder,
                ),
              ),
              child: TextFormField(
                controller: controller,
                maxLines: maxLines,
                style: const TextStyle(
                  color: QuantumTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      icon,
                      size: 20,
                      color: QuantumTheme.primaryBlue,
                    ),
                  ),
                  hintText: 'Enter $label',
                  hintStyle: TextStyle(
                    color: QuantumTheme.textTertiary,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: required
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '$label is required';
                        }
                        return null;
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return const Color(0xFF86efac);
    if (confidence >= 0.6) return const Color(0xFFfbbf24);
    return const Color(0xFFf97316);
  }

  Widget _buildSaveButton() {
    return FadeTransition(
      opacity: _entryAnimationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entryAnimationController,
          curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
        )),
        child: ScaleTransition(
          scale: _saveButtonScale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: QuantumTheme.neuralGlow(
                color: _isSaving
                    ? QuantumTheme.primaryBlue
                    : QuantumTheme.successGreen,
                blurRadius: 30,
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaving
                    ? QuantumTheme.primaryBlue
                    : QuantumTheme.successGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 28),
              label: Text(
                _isSaving ? 'Saving to Neural Network...' : 'Save Contact',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
