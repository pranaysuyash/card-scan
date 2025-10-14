import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/contact.dart';
import 'showcase/showcase_home.dart';
import 'showcase/scan_variants/scan_variant_a.dart';
import 'showcase/scan_variants/scan_variant_b.dart';
import 'showcase/scan_variants/scan_variant_c.dart';
import 'showcase/scan_variants/scan_variant_d.dart';
import 'showcase/scan_variants/scan_variant_e.dart';
import 'showcase/review_variants/review_variant_a.dart';
import 'showcase/review_variants/review_variant_b.dart';
import 'showcase/review_variants/review_variant_c.dart';
import 'showcase/review_variants/review_variant_d.dart';
import 'showcase/home_variants/home_variant_a.dart';
import 'showcase/home_variants/home_variant_b.dart';
import 'showcase/home_variants/home_variant_c.dart';
import 'showcase/other_variants/contact_tile_enhanced.dart';
import 'ui/screens/contact_detail_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/review_screen.dart';
import 'ui/screens/scan_screen.dart';
import 'ui/screens/settings_screen.dart';

final showcaseRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ShowcaseHome(),
    ),
    // Scan variants
    GoRoute(
      path: '/showcase/scan/a',
      builder: (context, state) => const ScanScreenVariantA(),
    ),
    GoRoute(
      path: '/showcase/scan/b',
      builder: (context, state) => const ScanScreenVariantB(),
    ),
    GoRoute(
      path: '/showcase/scan/c',
      builder: (context, state) => const ScanScreenVariantC(),
    ),
    GoRoute(
      path: '/showcase/scan/d',
      builder: (context, state) => const ScanScreenVariantD(),
    ),
    GoRoute(
      path: '/showcase/scan/e',
      builder: (context, state) => const ScanScreenVariantE(),
    ),
    // Review variants
    GoRoute(
      path: '/showcase/review/a',
      builder: (context, state) => const ReviewScreenVariantA(
        imagePath: null,
        ocrLines: [],
        parsedData: null,
      ),
    ),
    GoRoute(
      path: '/showcase/review/b',
      builder: (context, state) => const ReviewScreenVariantB(
        imagePath: null,
        ocrLines: [],
        parsedData: null,
      ),
    ),
    GoRoute(
      path: '/showcase/review/c',
      builder: (context, state) => const ReviewScreenVariantC(
        imagePath: null,
        ocrLines: [],
        parsedData: null,
      ),
    ),
    GoRoute(
      path: '/showcase/review/d',
      builder: (context, state) => const ReviewScreenVariantD(
        imagePath: null,
        ocrLines: [],
        parsedData: null,
      ),
    ),
    // Home variants
    GoRoute(
      path: '/showcase/home/a',
      builder: (context, state) => const HomeScreenVariantA(),
    ),
    GoRoute(
      path: '/showcase/home/b',
      builder: (context, state) => const HomeScreenVariantB(),
    ),
    GoRoute(
      path: '/showcase/home/c',
      builder: (context, state) => const HomeScreenVariantC(),
    ),
    // Component experiments
    GoRoute(
      path: '/showcase/contact-tile',
      builder: (context, state) => const ContactTileVariantPreview(),
    ),
    GoRoute(
      path: '/showcase/theme',
      builder: (context, state) => const ThemeTokensVariantPreview(),
    ),
    // --- Production app mounted beneath /app ---
    GoRoute(
      path: '/app',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/app/scan',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ScanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/app/review',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ReviewScreen(
            imagePath: extra?['imagePath'] as String?,
            ocrLines: (extra?['lines'] as List?)?.cast<String>() ?? [],
            parsedData: extra?['parsed'] as Map<String, dynamic>?,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            final offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/app/contact/:id',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CustomTransitionPage(
          key: state.pageKey,
          child: ContactDetailScreen(contactId: id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            final offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/app/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    ),
  ],
);

class ContactTileVariantPreview extends StatelessWidget {
  const ContactTileVariantPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final contact = Contact()
      ..id = 1
      ..fullName = 'Taylor Ramos'
      ..company = 'Echo Labs'
      ..title = 'Lead Designer'
      ..isFavorite = true
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Tile Variant')),
      body: Center(
        child: SizedBox(
          width: 360,
          child: ContactTileEnhanced(
            contact: contact,
            onTap: () {},
            onLongPress: () {},
            isSelected: false,
            emphasize: true,
          ),
        ),
      ),
    );
  }
}

class ThemeTokensVariantPreview extends StatelessWidget {
  const ThemeTokensVariantPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swatches = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.surface,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Variant Preview')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enhanced Theme Tokens',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final color in swatches)
                  _ColorSwatch(title: _describeColor(color), color: color),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Refer to other_variants/app_theme_enhanced.dart for the full implementation.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _describeColor(Color color) =>
      '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
