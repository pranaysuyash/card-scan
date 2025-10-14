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
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerShift;
  bool _isHovered = false;
  bool _isPressed = false;
  bool _hasEmphasisRun = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _shimmerController.value = 0.5;
    _shimmerShift =
        Tween<double>(begin: -0.35, end: 0.35).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine,
    ));

    if (widget.emphasize) {
      _queueEmphasis();
    }
  }

  @override
  void didUpdateWidget(covariant ContactTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emphasize && !_hasEmphasisRun) {
      _queueEmphasis();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _queueEmphasis() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _triggerEmphasis();
    });
  }

  Future<void> _triggerEmphasis() async {
    if (_hasEmphasisRun) return;
    _hasEmphasisRun = true;
    _startShimmer();
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    await _pressController.forward();
    await Future.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    await _pressController.reverse();
    if (!mounted) return;
    _stopShimmer();
  }

  void _handleHover(bool hovering) {
    if (!mounted) return;
    setState(() {
      _isHovered = hovering;
    });
    if (hovering) {
      _startShimmer();
    } else {
      _stopShimmer();
    }
  }

  void _startShimmer() {
    if (_shimmerController.isAnimating) return;
    _shimmerController.repeat(reverse: true);
  }

  void _stopShimmer() {
    if (!_shimmerController.isAnimating) return;
    if (_isHovered || _isPressed) return;
    _shimmerController
        .animateTo(
      0.5,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    )
        .whenCompleteOrCancel(() {
      if (!_isHovered && !_isPressed && mounted) {
        _shimmerController.stop(canceled: false);
      }
    });
  }

  double _highlightStrength() {
    final hoverBoost = _isHovered ? 0.35 : 0.0;
    final pressBoost = _pressController.value * 0.6;
    final shimmerBoost = _shimmerController.isAnimating ? 0.25 : 0.0;
    return (hoverBoost + pressBoost + shimmerBoost).clamp(0.0, 1.0);
  }

  LinearGradient _buildGlassGradient(ThemeData theme, double shimmerAngle) {
    final centerStop = 0.5 + (shimmerAngle * 0.4);
    return LinearGradient(
      begin: Alignment(-0.8 + shimmerAngle, -1.0),
      end: Alignment(0.8 + shimmerAngle, 1.0),
      colors: [
        theme.colorScheme.surface.withOpacity(0.75),
        theme.colorScheme.primary
            .withOpacity(0.08 + (0.04 * _highlightStrength())),
        theme.colorScheme.surface.withOpacity(0.68),
      ],
      stops: [
        0.0,
        centerStop.clamp(0.1, 0.9),
        1.0,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _buildInitials(widget.contact.fullName);
    final subtitle = _buildSubtitle(widget.contact);
    final inSelectionMode = widget.isSelected != null;

    return Hero(
      tag: 'contact-card-${widget.contact.id}',
      flightShuttleBuilder:
          (context, animation, direction, fromContext, toContext) {
        final target = direction == HeroFlightDirection.push
            ? toContext.widget
            : fromContext.widget;
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: Curves.easeInOut),
          ),
          child: target,
        );
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pressController, _shimmerController]),
          builder: (context, _) {
            final highlight = _highlightStrength();
            final blurSigma = lerpDouble(
                  DesignTokens.blurSigma,
                  DesignTokens.blurSigma + 6,
                  highlight,
                ) ??
                DesignTokens.blurSigma;
            final gradient = _buildGlassGradient(theme, _shimmerShift.value);
            final borderColor =
                Colors.white.withOpacity(0.18 + (highlight * 0.3));
            final shadowColor =
                theme.colorScheme.primary.withOpacity(0.05 + highlight * 0.25);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          DesignTokens.borderRadiusExtraLarge),
                      gradient: gradient,
                      border: Border.all(
                        width: 1.2,
                        color: widget.isSelected == true
                            ? theme.colorScheme.primary.withOpacity(
                                0.4 + (highlight * 0.2),
                              )
                            : borderColor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 16 + (highlight * 16),
                          offset: const Offset(0, 10),
                          spreadRadius: highlight * 1.5,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
                        onLongPress: widget.onLongPress,
                        onHover: _handleHover,
                        onHighlightChanged: (value) {
                          _isPressed = value;
                          if (value) {
                            _pressController.forward();
                            _startShimmer();
                          } else {
                            _pressController.reverse();
                            _stopShimmer();
                          }
                        },
                        borderRadius: BorderRadius.circular(
                            DesignTokens.borderRadiusExtraLarge),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Hero(
                                tag: 'contact-avatar-${widget.contact.id}',
                                child: inSelectionMode
                                    ? Checkbox(
                                        value: widget.isSelected,
                                        onChanged: (_) => widget.onTap?.call(),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              color:
                                                  theme.colorScheme.onPrimary,
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
                                            widget.contact.fullName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (widget.contact.isFavorite &&
                                            !inSelectionMode)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 8),
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
                                        subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
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
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.3 + highlight * 0.2),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
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
