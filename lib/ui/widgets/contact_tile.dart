import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../theme_constants.dart';

class ContactTile extends StatefulWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool? isSelected; // null means not in selection mode
  final bool emphasize;

  const ContactTile({
    super.key,
    required this.contact,
    this.onTap,
    this.onLongPress,
    this.isSelected,
    this.emphasize = false,
  });

  @override
  State<ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerProgress;
  late Animation<double> _shimmerAngle;
  bool _isPointerDown = false;
  bool _isEmphasisInFlight = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 420),
    );
    _shimmerProgress = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );
    _shimmerAngle = Tween<double>(
      begin: -0.35,
      end: 0.45,
    ).animate(_shimmerProgress);

    if (widget.emphasize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerEmphasisPulse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ContactTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emphasize && !oldWidget.emphasize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerEmphasisPulse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _buildInitials(widget.contact.fullName);
    final subtitle = _buildSubtitle(widget.contact);
    final inSelectionMode = widget.isSelected != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Hero(
        tag: 'contact-${widget.contact.id}',
        child: Material(
          type: MaterialType.transparency,
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Listener(
                onPointerDown: (_) => _handlePressStart(),
                onPointerUp: (_) => _handlePressEnd(),
                onPointerCancel: (_) => _handlePressCancel(),
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    final shimmerValue = _shimmerProgress.value;
                    final bool isSelected = widget.isSelected == true;
                    final Color baseSurface = isSelected
                        ? theme.colorScheme.primaryContainer
                            .withOpacity(0.96)
                        : (theme.cardTheme.color ??
                                theme.colorScheme.surface)
                            .withOpacity(0.9);
                    final double highlightStop =
                        (0.35 + shimmerValue * 0.4).clamp(0.0, 1.0);
                    final LinearGradient gradient = LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: GradientRotation(_shimmerAngle.value),
                      colors: [
                        baseSurface.withOpacity(isSelected ? 0.92 : 0.78),
                        Color.lerp(
                              theme.colorScheme.primary
                                  .withOpacity(isSelected ? 0.35 : 0.16),
                              theme.colorScheme.secondary
                                  .withOpacity(isSelected ? 0.25 : 0.12),
                              shimmerValue,
                            ) ??
                            theme.colorScheme.primary
                                .withOpacity(isSelected ? 0.3 : 0.14),
                        baseSurface.withOpacity(isSelected ? 0.98 : 0.86),
                      ],
                      stops: [0.0, highlightStop, 1.0],
                    );

                    final double blurSigma =
                        DesignTokens.blurSigma + (shimmerValue * 6);
                    final double borderOpacity =
                        0.14 + (shimmerValue * (isSelected ? 0.25 : 0.18));
                    final List<BoxShadow> shadows = [
                      BoxShadow(
                        color: theme.colorScheme.primary
                            .withOpacity(isSelected
                                ? 0.35
                                : 0.08 + (0.14 * shimmerValue)),
                        blurRadius: 20 + (14 * shimmerValue),
                        offset: const Offset(0, 10),
                      ),
                    ];

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(
                            DesignTokens.borderRadiusExtraLarge),
                        border: Border.all(
                          color: Colors.white.withOpacity(borderOpacity),
                          width: 1,
                        ),
                        boxShadow: shadows,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            DesignTokens.borderRadiusExtraLarge),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: blurSigma,
                            sigmaY: blurSigma,
                          ),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _TileInterior(
                    contact: widget.contact,
                    inSelectionMode: inSelectionMode,
                    initials: initials,
                    subtitle: subtitle,
                    isSelected: widget.isSelected,
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePressStart() {
    _isPointerDown = true;
    _controller.forward();
    _activateShimmer();
  }

  void _handlePressEnd() {
    _isPointerDown = false;
    if (!_isEmphasisInFlight) {
      _controller.reverse();
      _deactivateShimmer();
    }
  }

  void _handlePressCancel() {
    _isPointerDown = false;
    if (!_isEmphasisInFlight) {
      _controller.reverse();
      _deactivateShimmer();
    }
  }

  void _handleHover(bool isHovering) {
    if (_isPointerDown) {
      return;
    }
    if (isHovering) {
      _activateShimmer();
    } else if (!_isEmphasisInFlight) {
      _deactivateShimmer();
    }
  }

  void _activateShimmer() {
    if (!_shimmerController.isAnimating &&
        _shimmerController.status != AnimationStatus.forward) {
      _shimmerController.forward();
    } else if (_shimmerController.status == AnimationStatus.reverse) {
      _shimmerController.forward();
    }
  }

  void _deactivateShimmer() {
    if (!_shimmerController.isAnimating &&
        _shimmerController.status == AnimationStatus.dismissed) {
      return;
    }
    _shimmerController.reverse();
  }

  void _triggerEmphasisPulse() {
    if (_isPointerDown || _isEmphasisInFlight) {
      return;
    }
    _isEmphasisInFlight = true;
    _controller.forward();
    _shimmerController.forward().whenComplete(() async {
      await Future.delayed(const Duration(milliseconds: 140));
      if (!mounted) {
        return;
      }
      _controller.reverse();
      _shimmerController.reverse().whenComplete(() {
        if (mounted) {
          _isEmphasisInFlight = false;
        }
      });
    });
  }

  String _buildInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return _firstLetter(parts.first);
    }

    final firstLetter = _firstLetter(parts.first);
    final lastLetter = _firstLetter(parts.last);
    return '$firstLetter$lastLetter';
  }

  String _firstLetter(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }

    final firstCodePoint = trimmed.runes.isEmpty ? null : trimmed.runes.first;
    if (firstCodePoint == null) {
      return '?';
    }

    return String.fromCharCode(firstCodePoint).toUpperCase();
  }

  String? _buildSubtitle(Contact contact) {
    final details = <String>[];

    if (contact.title != null && contact.title!.trim().isNotEmpty) {
      details.add(contact.title!.trim());
    }

    if (contact.company != null && contact.company!.trim().isNotEmpty) {
      details.add(contact.company!.trim());
    }

    if (contact.emails.isNotEmpty) {
      details.add(contact.emails.first.value);
    } else if (contact.phones.isNotEmpty) {
      details.add(contact.phones.first.value);
    }

    if (details.isEmpty) {
      return null;
    }

    if (details.length <= 2) {
      return details.join(' · ');
    }

    return '${details[0]} · ${details[1]}\n${details.sublist(2).join(' · ')}';
  }
}

class _TileInterior extends StatelessWidget {
  final Contact contact;
  final bool inSelectionMode;
  final String initials;
  final String? subtitle;
  final bool? isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _TileInterior({
    required this.contact,
    required this.inSelectionMode,
    required this.initials,
    required this.subtitle,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius:
            BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Hero(
                tag: 'contact-avatar-${contact.id}',
                child: inSelectionMode
                    ? Checkbox(
                        value: isSelected,
                        onChanged: (_) => onTap?.call(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: DesignTokens.avatarGradient,
                          shape: BoxShape.circle,
                          boxShadow: DesignTokens.avatarShadow,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (contact.isFavorite && !inSelectionMode)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Colors.amber.shade600,
                            ),
                          ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!inSelectionMode) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
