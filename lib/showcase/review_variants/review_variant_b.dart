import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/contact.dart';
import '../../providers/contact_provider.dart';
import '../../config/app_config.dart';
import '../../ui/widgets/confidence_chip.dart';
import '../../ui/theme_constants.dart';

class ReviewScreenVariantB extends ConsumerStatefulWidget {
  final String? imagePath;
  final List<String> ocrLines;
  final Map<String, dynamic>? parsedData;

  const ReviewScreenVariantB({
    super.key,
    this.imagePath,
    required this.ocrLines,
    this.parsedData,
  });

  @override
  ConsumerState<ReviewScreenVariantB> createState() => _ReviewScreenVariantBState();
}

class _ReviewScreenVariantBState extends ConsumerState<ReviewScreenVariantB>
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
  late final AnimationController _pulseController;

  final Map<String, String> _initialValues = {};
  final Map<String, bool?> _fieldValidity = {};
  final Map<String, String?> _validationMessages = {};
  late final Map<String, String? Function(String?)?> _validators;
  final Set<String> _requiredFields = {'fullName'};

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

    _validators = {
      'fullName': (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Name is required';
        }
        return null;
      },
      'email': (value) {
        if (value != null && value.isNotEmpty) {
          if (!AppConstants.emailRegex.hasMatch(value)) {
            return 'Invalid email format';
          }
        }
        return null;
      },
      'title': null,
      'company': null,
      'phone': null,
      'website': null,
      'address': null,
    };

    _setupField('fullName', _fullNameController);
    _setupField('title', _titleController);
    _setupField('company', _companyController);
    _setupField('email', _emailController);
    _setupField('phone', _phoneController);
    _setupField('website', _websiteController);
    _setupField('address', _addressController);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
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

  void _setupField(String key, TextEditingController controller) {
    _initialValues[key] = controller.text;
    _validationMessages[key] = null;

    final validator = _validators[key];
    final initialValue = controller.text;
    if (initialValue.isEmpty) {
      final isRequired = _requiredFields.contains(key);
      _fieldValidity[key] = isRequired ? false : null;
      if (isRequired) {
        _validationMessages[key] = validator?.call(initialValue);
      }
    } else {
      final message = validator?.call(initialValue);
      _fieldValidity[key] = message == null;
      _validationMessages[key] = message;
    }

    controller.addListener(() {
      final value = controller.text;
      final message = validator?.call(value);
      if (!mounted) return;
      setState(() {
        if (value.isEmpty) {
          if (_requiredFields.contains(key)) {
            _fieldValidity[key] = false;
            _validationMessages[key] = validator?.call(value);
          } else {
            _fieldValidity[key] = null;
            _validationMessages[key] = null;
          }
        } else {
          _fieldValidity[key] = message == null;
          _validationMessages[key] = message;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBody: true,
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: true,
                  pinned: true,
                  stretch: true,
                  expandedHeight: 280,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding:
                        const EdgeInsetsDirectional.only(start: 20, bottom: 16),
                    title: const Text(
                      'Review & Save',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.fadeTitle,
                    ],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFEEF1FF),
                                Color(0x80EEF1FF),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 80, 20, 36),
                            child: _buildHeaderHero(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_error != null) _buildErrorBanner(),
                      _buildSection(
                        context,
                        title: 'Identity',
                        description:
                            'Confirm who you met and how they present themselves.',
                        children: [
                          _buildTextField(
                            controller: _fullNameController,
                            label: 'Full Name *',
                            icon: Icons.person_rounded,
                            index: 0,
                            fieldKey: 'fullName',
                            validator: _validators['fullName'],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _titleController,
                            label: 'Title',
                            icon: Icons.work_rounded,
                            index: 1,
                            fieldKey: 'title',
                            validator: _validators['title'],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _companyController,
                            label: 'Company',
                            icon: Icons.business_rounded,
                            index: 2,
                            fieldKey: 'company',
                            validator: _validators['company'],
                          ),
                        ],
                      ),
                      _buildSection(
                        context,
                        title: 'Contact Details',
                        description:
                            'Make sure you have the right ways to follow up.',
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            confidence: _confidence['email'],
                            index: 3,
                            fieldKey: 'email',
                            validator: _validators['email'],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone',
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            confidence: _confidence['phone'],
                            index: 4,
                            fieldKey: 'phone',
                            validator: _validators['phone'],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _addressController,
                            label: 'Address',
                            icon: Icons.location_on_rounded,
                            maxLines: 2,
                            index: 5,
                            fieldKey: 'address',
                            validator: _validators['address'],
                          ),
                        ],
                      ),
                      _buildSection(
                        context,
                        title: 'Online Presence',
                        description:
                            'Add digital touchpoints to stay in the loop.',
                        children: [
                          _buildTextField(
                            controller: _websiteController,
                            label: 'Website',
                            icon: Icons.language_rounded,
                            keyboardType: TextInputType.url,
                            index: 6,
                            fieldKey: 'website',
                            validator: _validators['website'],
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            _buildBottomPanel(theme),
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
    required String fieldKey,
  }) {
    final theme = Theme.of(context);
    final status = _fieldValidity[fieldKey];
    final message = _validationMessages[fieldKey];
    final initialValue = _initialValues[fieldKey] ?? '';
    final isEdited = controller.text.trim() != initialValue.trim();
    final borderColor = status == true
        ? theme.colorScheme.primary.withOpacity(0.6)
        : status == false
            ? theme.colorScheme.error.withOpacity(0.7)
            : Colors.white.withOpacity(0.18);
    final accentColor = status == true
        ? theme.colorScheme.primary
        : status == false
            ? theme.colorScheme.error
            : theme.colorScheme.primary.withOpacity(0.7);

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
              const Spacer(),
              AnimatedSwitcher(
                duration: DesignTokens.animationDurationMedium,
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInBack,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Container(
                  key: ValueKey<bool>(isEdited),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: (isEdited
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondaryContainer)
                        .withOpacity(0.2),
                    border: Border.all(
                      color: isEdited
                          ? theme.colorScheme.primary.withOpacity(0.5)
                          : theme.colorScheme.secondary.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEdited
                            ? Icons.edit_rounded
                            : Icons.auto_awesome_motion,
                        size: 14,
                        color: isEdited
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEdited ? 'Edited' : 'Parsed',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isEdited
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: DesignTokens.animationDurationMedium,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 16),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      DesignTokens.borderRadiusExtraLarge),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface.withOpacity(0.35),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedContainer(
                    duration: DesignTokens.animationDurationMedium,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withOpacity(0.12),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: accentColor,
                    ),
                  ),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedSwitcher(
                    duration: DesignTokens.animationDurationMedium,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: _buildValidationIcon(status, theme),
                  ),
                ),
                hintText: 'Enter $label',
                hintStyle: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                ),
                errorStyle:
                    const TextStyle(height: 0, color: Colors.transparent),
              ),
              validator: validator,
            ),
          ),
          AnimatedSwitcher(
            duration: DesignTokens.animationDurationMedium,
            child: message == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationIcon(bool? status, ThemeData theme) {
    if (status == null) {
      return Icon(
        Icons.circle,
        key: const ValueKey('neutral'),
        size: 12,
        color: theme.colorScheme.outline.withOpacity(0.4),
      );
    }
    if (status) {
      return Icon(
        Icons.check_circle_rounded,
        key: const ValueKey('valid'),
        size: 20,
        color: theme.colorScheme.primary,
      );
    }
    return Icon(
      Icons.error_outline_rounded,
      key: const ValueKey('invalid'),
      size: 20,
      color: theme.colorScheme.error,
    );
  }

  Widget _buildErrorBanner() {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: DesignTokens.animationDurationMedium,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: DesignTokens.glassDecoration(context).copyWith(
          color: theme.colorScheme.errorContainer.withOpacity(0.85),
          borderRadius:
              BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
          border: Border.all(
            color: theme.colorScheme.error.withOpacity(0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: DesignTokens.animationDurationMedium,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(DesignTokens.borderRadiusExtraLarge + 4),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.18),
              theme.colorScheme.secondary.withOpacity(0.12),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(1.6),
          decoration: DesignTokens.glassDecoration(context).copyWith(
            borderRadius:
                BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderHero(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = widget.imagePath;
    bool hasImage = false;
    if (!kIsWeb && imagePath != null && imagePath.isNotEmpty) {
      try {
        hasImage = File(imagePath).existsSync();
      } catch (_) {
        hasImage = false;
      }
    }

    final displayName = _fullNameController.text.trim().isNotEmpty
        ? _fullNameController.text.trim()
        : (_initialValues['fullName']?.trim().isNotEmpty ?? false)
            ? _initialValues['fullName']!.trim()
            : 'New Contact';

    final headline = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Tap the fields below to refine details';
    final subtitle = _companyController.text.trim();

    return Hero(
      tag: 'card-preview-${imagePath ?? displayName}',
      child: Container(
        decoration: DesignTokens.glassDecoration(context).copyWith(
          borderRadius:
              BorderRadius.circular(DesignTokens.borderRadiusExtraLarge + 4),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    DesignTokens.borderRadiusExtraLarge - 2),
                gradient: hasImage
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                boxShadow: DesignTokens.avatarShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                    DesignTokens.borderRadiusExtraLarge - 2),
                child: hasImage
                    ? Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          _initialsFromName(displayName),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: DesignTokens.animationDurationMedium,
                    child: Text(
                      displayName,
                      key: ValueKey<String>('name-$displayName'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: DesignTokens.animationDurationMedium,
                    child: Text(
                      headline,
                      key: ValueKey<String>('headline-$headline'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: DesignTokens.animationDurationMedium,
                      child: Text(
                        subtitle,
                        key: ValueKey<String>('company-$subtitle'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.ocrLines.take(3).map((line) {
                      return AnimatedContainer(
                        duration: DesignTokens.animationDurationMedium,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: theme.colorScheme.primary.withOpacity(0.08),
                        ),
                        child: Text(
                          line,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(ThemeData theme) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: AnimatedContainer(
            duration: DesignTokens.animationDurationMedium,
            decoration: DesignTokens.glassDecoration(context).copyWith(
              borderRadius:
                  BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildPulseIcon(theme),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to capture this connection?',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "We'll store everything securely. You can always edit later.",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  duration: DesignTokens.animationDurationMedium,
                  opacity: _isSaving ? 0.8 : 1,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveContact,
                    icon: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: AnimatedSwitcher(
                      duration: DesignTokens.animationDurationMedium,
                      child: Text(
                        _isSaving ? 'Saving...' : 'Save Contact',
                        key: ValueKey<bool>(_isSaving),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            DesignTokens.borderRadiusLarge),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulseIcon(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 0.92 + (_pulseController.value * 0.12);
        final opacity = 0.5 + (_pulseController.value * 0.5);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
              theme.colorScheme.tertiary ?? theme.colorScheme.primaryContainer,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(' +'))
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'SC';
    }
    final buffer = StringBuffer();
    for (final part in parts.take(2)) {
      buffer.write(part[0].toUpperCase());
    }
    return buffer.toString();
  }
}
