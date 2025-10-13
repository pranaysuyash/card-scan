import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/contact.dart';
import '../../providers/contact_provider.dart';
import '../../config/app_config.dart';
import '../widgets/confidence_chip.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  final List<String> ocrLines;
  final Map<String, dynamic>? parsedData;

  const ReviewScreen({
    super.key,
    this.imagePath,
    required this.ocrLines,
    this.parsedData,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
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

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact saved successfully!')),
      );

      // Invalidate contacts provider to refresh list
      ref.invalidate(contactsProvider);

      context.go('/');
    } catch (e) {
      setState(() {
        _error = 'Error saving contact: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Review & Save',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Hero(
                  tag: 'scan-preview',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(
                        File(widget.imagePath!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        height: 180,
                      ),
                    ),
                  ),
                ),
              ),
            if (_error != null)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.9 + (0.1 * value),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                ),
              ),

            // Full Name (required)
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name *',
              icon: Icons.person_rounded,
              index: 0,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              icon: Icons.work_rounded,
              index: 1,
            ),

            const SizedBox(height: 20),

            // Company
            _buildTextField(
              controller: _companyController,
              label: 'Company',
              icon: Icons.business_rounded,
              index: 2,
            ),

            const SizedBox(height: 20),

            // Email
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              confidence: _confidence['email'],
              index: 3,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!AppConstants.emailRegex.hasMatch(value)) {
                    return 'Invalid email format';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Phone
            _buildTextField(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              confidence: _confidence['phone'],
              index: 4,
            ),

            const SizedBox(height: 20),

            // Website
            _buildTextField(
              controller: _websiteController,
              label: 'Website',
              icon: Icons.language_rounded,
              keyboardType: TextInputType.url,
              index: 5,
            ),

            const SizedBox(height: 20),

            // Address
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on_rounded,
              maxLines: 2,
              index: 6,
            ),

            const SizedBox(height: 32),

            // Save Button with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveContact,
                icon: _isSaving
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
                  _isSaving ? 'Saving...' : 'Save Contact',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    double? confidence,
    String? Function(String?)? validator,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
              ),
              if (confidence != null) ...[
                const SizedBox(width: 8),
                ConfidenceChip(confidence: confidence),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  child: Icon(icon, size: 22),
                ),
                hintText: 'Enter $label',
                hintStyle: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }
}
