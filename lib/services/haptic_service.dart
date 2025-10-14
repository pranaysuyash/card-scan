import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();

  factory HapticService() => _instance;

  HapticService._internal();

  bool _isHapticEnabled = true;

  void lightImpact() {
    if (!_isHapticEnabled) return;
    HapticFeedback.lightImpact();
  }

  void mediumImpact() {
    if (!_isHapticEnabled) return;
    HapticFeedback.mediumImpact();
  }

  void heavyImpact() {
    if (!_isHapticEnabled) return;
    HapticFeedback.heavyImpact();
  }

  void selectionClick() {
    if (!_isHapticEnabled) return;
    HapticFeedback.selectionClick();
  }

  void vibrate() {
    if (!_isHapticEnabled) return;
    HapticFeedback.vibrate();
  }

  void setHapticEnabled(bool enabled) {
    _isHapticEnabled = enabled;
  }

  bool isHapticEnabled() => _isHapticEnabled;
}

class HapticButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Function(HapticService hapticService)? onHaptic;
  final bool enabled;

  const HapticButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.onHaptic,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return GestureDetector(
      onTap: enabled
          ? () {
              onHaptic?.call(hapticService);
              onPressed?.call();
            }
          : null,
      child: child,
    );
  }
}

class HapticIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Function(HapticService hapticService)? onHaptic;
  final bool enabled;
  final double size;
  final Color? color;

  const HapticIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.onHaptic,
    this.enabled = true,
    this.size = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return HapticButton(
      enabled: enabled,
      onHaptic: onHaptic ?? (haptic) => haptic.lightImpact(),
      onPressed: onPressed,
      child: Icon(
        icon,
        size: size,
        color: color ?? Theme.of(context).iconTheme.color,
      ),
    );
  }
}