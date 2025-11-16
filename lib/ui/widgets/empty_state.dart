import 'package:flutter/material.dart';
import 'package:card_scan/ui/quantum_theme.dart';

/// Beautiful empty state widget with call-to-action
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with glow effect
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    (iconColor ?? QuantumTheme.primaryBlue).withOpacity(0.3),
                    (iconColor ?? QuantumTheme.primaryBlue).withOpacity(0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (iconColor ?? QuantumTheme.primaryBlue).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 60,
                color: iconColor ?? QuantumTheme.primaryBlue,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor ?? QuantumTheme.accentPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: (iconColor ?? QuantumTheme.accentPink).withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Factory for contacts empty state
  factory EmptyState.contacts({VoidCallback? onScan}) {
    return EmptyState(
      icon: Icons.contacts_outlined,
      title: 'No Contacts Yet',
      message: 'Start building your network by scanning your first business card',
      actionLabel: 'Scan Card',
      onAction: onScan,
      iconColor: QuantumTheme.primaryBlue,
    );
  }

  /// Factory for search empty state
  factory EmptyState.search(String query) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: 'No contacts match "$query". Try a different search term.',
      iconColor: QuantumTheme.primaryPurple,
    );
  }

  /// Factory for tags empty state
  factory EmptyState.tags() {
    return const EmptyState(
      icon: Icons.label_outline,
      title: 'No Tags Yet',
      message: 'Tags help you organize contacts. Add tags to your contacts to see them here.',
      iconColor: QuantumTheme.accentPink,
    );
  }

  /// Factory for groups empty state
  factory EmptyState.groups({VoidCallback? onCreate}) {
    return EmptyState(
      icon: Icons.folder_outlined,
      title: 'No Groups Yet',
      message: 'Create groups to organize your contacts by project, event, or any category',
      actionLabel: 'Create Group',
      onAction: onCreate,
      iconColor: QuantumTheme.successGreen,
    );
  }

  /// Factory for reminders empty state
  factory EmptyState.reminders({VoidCallback? onCreate}) {
    return EmptyState(
      icon: Icons.notifications_none,
      title: 'No Reminders',
      message: 'Set reminders to follow up with your contacts and never miss an opportunity',
      actionLabel: 'Add Reminder',
      onAction: onCreate,
      iconColor: QuantumTheme.accentPink,
    );
  }

  /// Factory for interactions empty state
  factory EmptyState.interactions() {
    return const EmptyState(
      icon: Icons.history,
      title: 'No Interactions Yet',
      message: 'Log your calls, meetings, and notes to track your networking history',
      iconColor: QuantumTheme.primaryPurple,
    );
  }
}
