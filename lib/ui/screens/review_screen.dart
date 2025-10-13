import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../models/contact.dart';
import '../../providers/contact_provider.dart';
import '../widgets/confidence_chip.dart';
import '../widgets/glass_container.dart';
import '../theme_constants.dart';

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

class _ReviewScreenState extends ConsumerState<ReviewScreen>
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
  late final Map<String, String> _suggestions;

  late final PageController _pageController;
  int _currentPage = 0;

  late final AnimationController _saveSuccessController;
  late final Animation<double> _saveScaleAnimation;

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

    _suggestions = {
      'full_name': parsed['full_name'] ?? '',
      'title': parsed['title'] ?? '',
      'company': parsed['company'] ?? '',
      'email': _emailController.text,
      'phone': _phoneController.text,
      'website': parsed['website'] ?? '',
      'address': parsed['address'] ?? '',
    };

    // Extract confidence scores
    if (emails.isNotEmpty) {
      _confidence['email'] = emails[0]['confidence'] ?? 0.0;
    }
    if (phones.isNotEmpty) {
      _confidence['phone'] = phones[0]['confidence'] ?? 0.0;
    }

    _pageController = PageController();

    _saveSuccessController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _saveScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _saveSuccessController,
        curve: Curves.easeOutBack,
      ),
    );
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
    _pageController.dispose();
    _saveSuccessController.dispose();
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

    if (_saveSuccessController.isCompleted) {
      _saveSuccessController.reset();
    }

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

      setState(() {
        _isSaving = false;
      });

      // Invalidate contacts provider to refresh list
      ref.invalidate(contactsProvider);
      await _saveSuccessController.forward();
      if (!mounted) return;
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: theme.colorScheme.surface,
              title: const Text(
                'Review & Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildPreviewHeader(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) _buildErrorBanner(theme),
                    _buildStepperIndicator(theme),
                    const SizedBox(height: 20),
                    _buildPagedContent(context),
                    const SizedBox(height: 32),
                    _buildNavigationControls(theme),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: _buildSaveButton(theme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = widget.imagePath;
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'scanned-card-preview',
          child: Container(
            decoration: BoxDecoration(
              gradient: DesignTokens.backgroundGradient,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
                child: Container(
                  decoration: DesignTokens.glassDecoration(context),
                  child: imagePath != null && imagePath.isNotEmpty
                      ? Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                        )
                      : _buildIllustration(theme),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 36,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: DesignTokens.animationDurationMedium,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              borderRadius:
                  BorderRadius.circular(DesignTokens.borderRadiusLarge),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preview your scan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: theme.colorScheme.onSurface.withOpacity(0.85),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.swipe_left_alt_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Swipe to edit',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIllustration(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.35),
            theme.colorScheme.secondary.withOpacity(0.25),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.badge_outlined,
          size: 96,
          color: theme.colorScheme.onPrimary.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius:
              BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.error.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
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
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperIndicator(ThemeData theme) {
    final steps = ['Identity', 'Communication', 'Company'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentPage;
        final isCompleted = index < _currentPage;
        return Expanded(
          child: AnimatedContainer(
            duration: DesignTokens.animationDurationMedium,
            curve: Curves.easeOut,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 6,
              right: index == steps.length - 1 ? 0 : 6,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DesignTokens.borderRadiusLarge),
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      ],
                    ),
              boxShadow: isActive
                  ? DesignTokens.cardShadow
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: isActive
                        ? DesignTokens.fontWeightBold
                        : DesignTokens.fontWeightMedium,
                    color: isActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPagedContent(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: DesignTokens.animationDurationSlow,
      curve: Curves.easeInOut,
      child: SizedBox(
        height: 420,
        child: PageView(
          controller: _pageController,
          onPageChanged: (value) {
            setState(() {
              _currentPage = value;
            });
          },
          children: [
            _buildIdentityPage(theme),
            _buildCommunicationPage(theme),
            _buildCompanyPage(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityPage(ThemeData theme) {
    return _GlassSection(
      icon: Icons.badge_rounded,
      title: 'Identity',
      subtitle: 'Double check who you met and their role.',
      children: [
        _buildTextField(
          controller: _fullNameController,
          label: 'Full Name *',
          icon: Icons.person_rounded,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
          suggestionKey: 'full_name',
        ),
        _buildTextField(
          controller: _titleController,
          label: 'Title',
          icon: Icons.work_outline_rounded,
          suggestionKey: 'title',
        ),
      ],
    );
  }

  Widget _buildCommunicationPage(ThemeData theme) {
    return _GlassSection(
      icon: Icons.chat_bubble_rounded,
      title: 'Communication',
      subtitle: 'Confirm how you can get in touch.',
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!AppConstants.emailRegex.hasMatch(value)) {
                return 'Invalid email format';
              }
            }
            return null;
          },
          confidence: _confidence['email'],
          suggestionKey: 'email',
        ),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          confidence: _confidence['phone'],
          suggestionKey: 'phone',
        ),
        _buildTextField(
          controller: _websiteController,
          label: 'Website',
          icon: Icons.language_rounded,
          keyboardType: TextInputType.url,
          suggestionKey: 'website',
        ),
      ],
    );
  }

  Widget _buildCompanyPage(ThemeData theme) {
    return _GlassSection(
      icon: Icons.apartment_rounded,
      title: 'Company',
      subtitle: 'Complete their business information.',
      children: [
        _buildTextField(
          controller: _companyController,
          label: 'Company',
          icon: Icons.business_center_rounded,
          suggestionKey: 'company',
        ),
        _buildTextField(
          controller: _addressController,
          label: 'Address',
          icon: Icons.location_on_rounded,
          maxLines: 2,
          suggestionKey: 'address',
        ),
      ],
    );
  }

  Widget _buildNavigationControls(ThemeData theme) {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == 2;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedSwitcher(
          duration: DesignTokens.animationDurationMedium,
          child: isFirst
              ? const SizedBox(width: 100)
              : TextButton.icon(
                  key: const ValueKey('prev'),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: DesignTokens.animationDurationMedium,
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back'),
                ),
        ),
        AnimatedSwitcher(
          duration: DesignTokens.animationDurationMedium,
          child: isLast
              ? const SizedBox(width: 100)
              : FilledButton.icon(
                  key: const ValueKey('next'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingExtraLarge,
                      vertical: DesignTokens.spacingMedium,
                    ),
                  ),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: DesignTokens.animationDurationMedium,
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Next'),
                ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    final progress = CurvedAnimation(
      parent: _saveSuccessController,
      curve: Curves.easeInOut,
    );

    return Hero(
      tag: 'primary-action-cta',
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, child) {
          final scale = _saveScaleAnimation.value;
          final backgroundColor = Color.lerp(
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
                progress.value,
              ) ??
              theme.colorScheme.primary;
          final isCelebrating = !_isSaving && progress.value > 0.05;
          return Transform.scale(
            scale: scale,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.borderRadiusExtraLarge,
                  ),
                ),
              ),
              onPressed: _isSaving ? null : _saveContact,
              child: AnimatedSwitcher(
                duration: DesignTokens.animationDurationMedium,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: _isSaving
                    ? const SizedBox(
                        key: ValueKey('saving'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        key: ValueKey(isCelebrating ? 'saved' : 'save'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCelebrating
                                ? Icons.check_rounded
                                : Icons.check_circle_rounded,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isCelebrating ? 'Saved!' : 'Save Contact',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
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
    required String suggestionKey,
  }) {
    final theme = Theme.of(context);
    final suggestion = _suggestions[suggestionKey] ?? '';
    final normalizedSuggestion = suggestion.trim();
    final hasSuggestion = normalizedSuggestion.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: DesignTokens.animationDurationSlow,
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                if (confidence != null) ...[
                  const SizedBox(width: 8),
                  ConfidenceChip(confidence: confidence),
                ],
              ],
            ),
            const SizedBox(height: 12),
            GlassContainer(
              borderRadius:
                  BorderRadius.circular(DesignTokens.borderRadiusLarge),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(icon, size: 22),
                  hintText: 'Enter $label',
                ),
                validator: validator,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: DesignTokens.animationDurationMedium,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              ),
              child: hasSuggestion && controller.text.trim() != normalizedSuggestion
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        key: ValueKey('chip-$suggestionKey'),
                        avatar: const Icon(Icons.auto_fix_high_rounded, size: 18),
                        label: const Text('Accept OCR suggestion'),
                        onPressed: () {
                          setState(() {
                            controller.text = normalizedSuggestion;
                            controller.selection = TextSelection.collapsed(
                              offset: controller.text.length,
                            );
                          });
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _GlassSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DesignTokens.borderRadiusLarge),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.8),
                  theme.colorScheme.secondary.withOpacity(0.7),
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.onPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
