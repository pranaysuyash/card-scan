import 'package:flutter/material.dart';
import '../quantum_theme.dart';

/// Empty state widget for various screens
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
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
                    QuantumTheme.primaryBlue.withOpacity(0.2),
                    QuantumTheme.accentPurple.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.white.withOpacity(0.4),
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
            ),

            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuantumTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading skeleton for list items
class LoadingSkeleton extends StatefulWidget {
  final int itemCount;

  const LoadingSkeleton({
    super.key,
    this.itemCount = 10,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Avatar skeleton
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.2 + _controller.value * 0.1),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text skeletons
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.2 + _controller.value * 0.1),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.2 + _controller.value * 0.1),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
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
}

/// Predefined empty states for common scenarios
class EmptyStates {
  static Widget noContacts({VoidCallback? onScan}) => EmptyState(
        icon: Icons.contacts_outlined,
        title: 'No Contacts Yet',
        description: 'Start scanning business cards to build your network',
        actionText: 'Scan Your First Card',
        onAction: onScan,
      );

  static Widget noSearchResults() => const EmptyState(
        icon: Icons.search_off,
        title: 'No Results Found',
        description: 'Try adjusting your search or filters',
      );

  static Widget noBatchScans({VoidCallback? onCreate}) => EmptyState(
        icon: Icons.collections_outlined,
        title: 'No Batch Scans',
        description: 'Create a batch session to scan multiple cards at once',
        actionText: 'Create Batch',
        onAction: onCreate,
      );

  static Widget noFavorites() => const EmptyState(
        icon: Icons.star_outline,
        title: 'No Favorites',
        description: 'Mark contacts as favorites for quick access',
      );

  static Widget noVoiceNotes({VoidCallback? onRecord}) => EmptyState(
        icon: Icons.mic_none,
        title: 'No Voice Notes',
        description: 'Record meeting notes and ideas for this contact',
        actionText: 'Record Note',
        onAction: onRecord,
      );

  static Widget networkError({VoidCallback? onRetry}) => EmptyState(
        icon: Icons.cloud_off,
        title: 'Connection Error',
        description: 'Check your internet connection and try again',
        actionText: 'Retry',
        onAction: onRetry,
      );

  static Widget permissionDenied({VoidCallback? onSettings}) => EmptyState(
        icon: Icons.camera_alt_outlined,
        title: 'Camera Permission Required',
        description: 'Please grant camera access to scan business cards',
        actionText: 'Open Settings',
        onAction: onSettings,
      );
}
