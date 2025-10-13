import 'package:flutter/material.dart';

/// Displays a compact chip with the OCR confidence score.
class ConfidenceChip extends StatelessWidget {
  final double confidence;

  const ConfidenceChip({
    super.key,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = confidence.clamp(0, 1);
    final percentage = (normalized * 100).round();

    final _ConfidencePalette palette;
    if (normalized >= 0.85) {
      palette = _ConfidencePalette.high(theme);
    } else if (normalized >= 0.6) {
      palette = _ConfidencePalette.medium(theme);
    } else {
      palette = _ConfidencePalette.low(theme);
    }

    return Tooltip(
      message: 'Confidence: $percentage%',
      child: Chip(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: palette.background,
        label: Text(
          '$percentage%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ConfidencePalette {
  final Color background;
  final Color foreground;

  _ConfidencePalette({
    required this.background,
    required this.foreground,
  });

  factory _ConfidencePalette.high(ThemeData theme) {
    return _ConfidencePalette(
      background: theme.colorScheme.secondaryContainer,
      foreground: theme.colorScheme.onSecondaryContainer,
    );
  }

  factory _ConfidencePalette.medium(ThemeData theme) {
    return _ConfidencePalette(
      background: theme.colorScheme.tertiaryContainer,
      foreground: theme.colorScheme.onTertiaryContainer,
    );
  }

  factory _ConfidencePalette.low(ThemeData theme) {
    return _ConfidencePalette(
      background: theme.colorScheme.errorContainer,
      foreground: theme.colorScheme.onErrorContainer,
    );
  }
}
