import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/contact.dart';
import '../../providers/contact_provider.dart';
import '../../config/app_config.dart';
import '../../ui/widgets/confidence_chip.dart';

class ReviewScreenVariantA extends ConsumerStatefulWidget {
  final String? imagePath;
  final List<String> ocrLines;
  final Map<String, dynamic>? parsedData;

  const ReviewScreenVariantA({
    super.key,
    this.imagePath,
    required this.ocrLines,
    this.parsedData,
  });

  @override
  ConsumerState<ReviewScreenVariantA> createState() =>
      _ReviewScreenVariantAState();
}

class _ReviewScreenVariantAState extends ConsumerState<ReviewScreenVariantA>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final ScrollController _scrollController;
  late final TabController _tabController;
  late final Map<String, FocusNode> _focusNodes;
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
  final Map<String, GlobalKey<FormFieldState<String>>> _formFieldKeys = {
    'fullName': GlobalKey<FormFieldState<String>>(),
    'title': GlobalKey<FormFieldState<String>>(),
    'company': GlobalKey<FormFieldState<String>>(),
    'email': GlobalKey<FormFieldState<String>>(),
    'phone': GlobalKey<FormFieldState<String>>(),
    'website': GlobalKey<FormFieldState<String>>(),
    'address': GlobalKey<FormFieldState<String>>(),
  };

  final Map<String, GlobalKey> _fieldCardKeys = {
    'fullName': GlobalKey(),
    'title': GlobalKey(),
    'company': GlobalKey(),
    'email': GlobalKey(),
    'phone': GlobalKey(),
    'website': GlobalKey(),
    'address': GlobalKey(),
  };

  final Map<String, int> _fieldSectionIndex = {
    'fullName': 0,
    'title': 0,
    'company': 0,
    'email': 1,
    'phone': 1,
    'website': 2,
    'address': 2,
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
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

    _focusNodes = {
      'fullName': FocusNode(),
      'title': FocusNode(),
      'company': FocusNode(),
      'email': FocusNode(),
      'phone': FocusNode(),
      'website': FocusNode(),
      'address': FocusNode(),
    };

    for (final controller in [
      _fullNameController,
      _titleController,
      _companyController,
      _emailController,
      _phoneController,
      _websiteController,
      _addressController,
    ]) {
      controller.addListener(_handleFieldChanged);
    }

    if (emails.isNotEmpty) {
      _confidence['email'] = emails[0]['confidence'] ?? 0.0;
    }
    if (phones.isNotEmpty) {
      _confidence['phone'] = phones[0]['confidence'] ?? 0.0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _fullNameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    for (final focus in _focusNodes.values) {
      focus.dispose();
    }
    super.dispose();
  }

  void _handleFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstInvalidField();
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

      if (_emailController.text.trim().isNotEmpty) {
        contact.emails.add(EmailItem()
          ..value = _emailController.text.trim().toLowerCase()
          ..confidence = _confidence['email'] ?? 0.85
          ..type = 'work');
      }

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

      ref.invalidate(contactsProvider);

      context.go('/');
    } catch (e) {
      setState(() {
        _error = 'Error saving contact: $e';
        _isSaving = false;
      });
    }
  }

  void _scrollToFirstInvalidField() {
    for (final entry in _formFieldKeys.entries) {
      final state = entry.value.currentState;
      if (state != null && state.hasError) {
        final targetTab = _fieldSectionIndex[entry.key];
        if (targetTab != null && targetTab != _tabController.index) {
          _tabController.animateTo(targetTab);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = _fieldCardKeys[entry.key]?.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              alignment: 0.2,
            );
          }
        });
        return;
      }
    }
  }

  void _showOcrBottomSheet() {
    if (widget.ocrLines.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.94),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OCR Reference',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemBuilder: (context, index) {
                        final line = widget.ocrLines[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            line,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.4),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: widget.ocrLines.length,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionConfigs = [
      _SectionConfig(
        itemCount: 3,
        child: _buildSectionScroller([
          _buildFieldCard(
            fieldKey: 'fullName',
            controller: _fullNameController,
            label: 'Full Name *',
            icon: Icons.person_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          _buildFieldCard(
            fieldKey: 'title',
            controller: _titleController,
            label: 'Title',
            icon: Icons.work_rounded,
          ),
          _buildFieldCard(
            fieldKey: 'company',
            controller: _companyController,
            label: 'Company',
            icon: Icons.business_rounded,
          ),
        ]),
      ),
      _SectionConfig(
        itemCount: 2,
        child: _buildSectionScroller([
          _buildFieldCard(
            fieldKey: 'email',
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            confidence: _confidence['email'],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!AppConstants.emailRegex.hasMatch(value)) {
                  return 'Invalid email format';
                }
              }
              return null;
            },
          ),
          _buildFieldCard(
            fieldKey: 'phone',
            controller: _phoneController,
            label: 'Phone',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            confidence: _confidence['phone'],
          ),
        ]),
      ),
      _SectionConfig(
        itemCount: 2,
        child: _buildSectionScroller([
          _buildFieldCard(
            fieldKey: 'website',
            controller: _websiteController,
            label: 'Website',
            icon: Icons.language_rounded,
            keyboardType: TextInputType.url,
          ),
          _buildFieldCard(
            fieldKey: 'address',
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_rounded,
            maxLines: 2,
          ),
        ]),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      elevation: 0,
                      pinned: true,
                      stretch: true,
                      expandedHeight: 280,
                      title: const Text(
                        'Review & Save',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      actions: [
                        IconButton(
                          tooltip: 'Show OCR lines',
                          onPressed: _showOcrBottomSheet,
                          icon: const Icon(Icons.subject_rounded),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: const [
                          StretchMode.blurBackground,
                          StretchMode.fadeTitle,
                        ],
                        background: _buildHeader(context),
                      ),
                    ),
                    if (_error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: TweenAnimationBuilder<double>(
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
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
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
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _ReviewTabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorWeight: 3,
                          splashFactory: NoSplash.splashFactory,
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          tabs: const [
                            Tab(text: 'Identity'),
                            Tab(text: 'Contact'),
                            Tab(text: 'Additional'),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: _calculateTabHeight(sectionConfigs),
                            child: TabBarView(
                              controller: _tabController,
                              physics: const BouncingScrollPhysics(),
                              children: sectionConfigs
                                  .map((config) => config.child)
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTabHeight(List<_SectionConfig> sections) {
    double lerpHeight(double value) {
      final lower = value.floor().clamp(0, sections.length - 1);
      final upper = value.ceil().clamp(0, sections.length - 1);
      final t = value - lower;
      final lowerHeight = _heightForCount(sections[lower].itemCount);
      final upperHeight = _heightForCount(sections[upper].itemCount);
      return lerpDouble(lowerHeight, upperHeight, t) ?? lowerHeight;
    }

    final animationValue = _tabController.animation?.value;
    if (animationValue != null && animationValue >= 0) {
      return lerpHeight(animationValue);
    }
    return _heightForCount(sections[_tabController.index].itemCount);
  }

  double _heightForCount(int count) {
    const baseHeight = 240.0;
    const perItem = 150.0;
    return baseHeight + math.max(0, count - 1) * perItem;
  }

  Widget _buildActionBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 16 * (1 - value)),
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'scanned-card-${widget.imagePath ?? 'preview'}',
              child: widget.imagePath != null
                  ? Image.file(
                      File(widget.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.65),
                            Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.65),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.style_rounded,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.25),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _fullNameController.text.isNotEmpty
                          ? _fullNameController.text
                          : 'Unnamed Contact',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        _titleController.text,
                        _companyController.text,
                      ]
                          .where((element) => element.trim().isNotEmpty)
                          .join(' · '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (_emailController.text.isNotEmpty)
                          _buildOverlayPill(
                            icon: Icons.email_rounded,
                            label: _emailController.text,
                            confidence: _confidence['email'],
                          ),
                        if (_phoneController.text.isNotEmpty)
                          _buildOverlayPill(
                            icon: Icons.phone_rounded,
                            label: _phoneController.text,
                            confidence: _confidence['phone'],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayPill({
    required IconData icon,
    required String label,
    double? confidence,
  }) {
    final normalized = confidence?.clamp(0, 1) ?? 0;
    final percentage = (normalized * 100).round();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (confidence != null) ...[
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionScroller(List<Widget> children) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: children,
    );
  }

  Widget _buildFieldCard({
    required String fieldKey,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    double? confidence,
    String? Function(String?)? validator,
  }) {
    final hasError = _formFieldKeys[fieldKey]?.currentState?.hasError ?? false;
    final lowConfidence = confidence != null && confidence < 0.6;
    final hasContent = controller.text.trim().isNotEmpty;
    final isFocused = _focusNodes[fieldKey]?.hasFocus ?? false;
    final showValidBadge = hasContent && !hasError;

    final Color borderColor = hasError
        ? Theme.of(context).colorScheme.error
        : lowConfidence
            ? Colors.orangeAccent
            : isFocused
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withOpacity(0.08);

    final Color glowColor = hasError
        ? Theme.of(context).colorScheme.error.withOpacity(0.18)
        : lowConfidence
            ? Colors.orangeAccent.withOpacity(0.18)
            : Theme.of(context).colorScheme.primary.withOpacity(
                  showValidBadge || isFocused ? 0.18 : 0.06,
                );

    return AnimatedContainer(
      key: _fieldCardKeys[fieldKey],
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.65),
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: borderColor, width: hasError ? 1.6 : 1.2),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Icon(icon, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (confidence != null) ConfidenceChip(confidence: confidence),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: hasError
                    ? _buildValidationBadge(
                        icon: Icons.error_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                      )
                    : showValidBadge
                        ? _buildValidationBadge(
                            icon: Icons.verified_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: _formFieldKeys[fieldKey],
            controller: controller,
            focusNode: _focusNodes[fieldKey],
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter ${label.replaceAll('*', '').trim()}',
              border: InputBorder.none,
              isCollapsed: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationBadge({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      key: ValueKey(icon),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _ReviewTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _ReviewTabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height + 16;

  @override
  double get minExtent => tabBar.preferredSize.height + 16;

  @override
  bool shouldRebuild(covariant _ReviewTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}

class _SectionConfig {
  final int itemCount;
  final Widget child;

  const _SectionConfig({required this.itemCount, required this.child});
}
