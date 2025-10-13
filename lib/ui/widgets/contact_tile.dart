import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../theme_constants.dart';

class ContactTile extends StatefulWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool? isSelected; // null means not in selection mode

  const ContactTile({
    super.key,
    required this.contact,
    this.onTap,
    this.onLongPress,
    this.isSelected,
  });

  @override
  State<ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _buildInitials(widget.contact.fullName);
    final subtitle = _buildSubtitle(widget.contact);
    final inSelectionMode = widget.isSelected != null;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) {
          _controller.forward();
        },
        onTapUp: (_) {
          _controller.reverse();
        },
        onTapCancel: () {
          _controller.reverse();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: DesignTokens.blurSigma,
                  sigmaY: DesignTokens.blurSigma),
              child: Container(
                decoration: DesignTokens.glassDecoration(context,
                    selected: widget.isSelected == true),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    borderRadius: BorderRadius.circular(
                        DesignTokens.borderRadiusExtraLarge),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          // Leading Avatar
                          Hero(
                            tag: 'contact-avatar-${widget.contact.id}',
                            child: inSelectionMode
                                ? Checkbox(
                                    value: widget.isSelected,
                                    onChanged: (_) => widget.onTap?.call(),
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
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          // Title and Subtitle
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
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Trailing Icon
                          if (!inSelectionMode) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.chevron_right_rounded,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.3),
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
