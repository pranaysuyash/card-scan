import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShowcaseHome extends StatelessWidget {
  const ShowcaseHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.transparent,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Card Scan',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Design Showcase',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShowcaseInfoCard(theme: theme),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'Scan Screen Variants',
                        countLabel: '5 designs',
                        cards: const [
                          _VariantCardData(
                            route: '/showcase/scan/a',
                            title: 'Variant A — Camera UI Features',
                            description:
                                'Live camera preview with guided framing overlays.',
                            color: Colors.blue,
                          ),
                          _VariantCardData(
                            route: '/showcase/scan/b',
                            title: 'Variant B — Immersive Animations',
                            description:
                                'Animated scanning flow with layered highlights.',
                            color: Colors.purple,
                          ),
                          _VariantCardData(
                            route: '/showcase/scan/c',
                            title: 'Variant C — Effects & Atmosphere',
                            description:
                                'Glassmorphic panels with parallax and particle accents.',
                            color: Colors.indigo,
                          ),
                          _VariantCardData(
                            route: '/showcase/scan/d',
                            title: 'Variant D — Refined Flow',
                            description:
                                'Simplified controls with staged instructional states.',
                            color: Colors.teal,
                          ),
                          _VariantCardData(
                            route: '/showcase/scan/e',
                            title: 'Variant E — Guided Capture',
                            description:
                                'Updated camera gestures plus adaptive lighting cues.',
                            color: Colors.cyan,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'Review Screen Variants',
                        countLabel: '4 designs',
                        cards: const [
                          _VariantCardData(
                            route: '/showcase/review/a',
                            title: 'Variant A — Sliver Layout',
                            description:
                                'Staggered slivers with contextual actions per section.',
                            color: Colors.orange,
                          ),
                          _VariantCardData(
                            route: '/showcase/review/b',
                            title: 'Variant B — Glassmorphism',
                            description:
                                'Frosted cards, inline editing, and sticky summaries.',
                            color: Colors.pink,
                          ),
                          _VariantCardData(
                            route: '/showcase/review/c',
                            title: 'Variant C — Guided Stepper',
                            description:
                                'Stepper-based review funnel with progress affordances.',
                            color: Colors.deepPurple,
                          ),
                          _VariantCardData(
                            route: '/showcase/review/d',
                            title: 'Variant D — Hero Expansion',
                            description:
                                'Hero-driven transitions from scan to review contexts.',
                            color: Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'Home Screen Variants',
                        countLabel: '3 designs',
                        cards: const [
                          _VariantCardData(
                            route: '/showcase/home/a',
                            title: 'Variant A — Stack + Scroll',
                            description:
                                'Layered hero header with CustomScrollView content.',
                            color: Colors.green,
                          ),
                          _VariantCardData(
                            route: '/showcase/home/b',
                            title: 'Variant B — Animated Feed',
                            description:
                                'Refined list choreography and search micro-interactions.',
                            color: Colors.lightGreen,
                          ),
                          _VariantCardData(
                            route: '/showcase/home/c',
                            title: 'Variant C — Enhanced Tiles',
                            description:
                                'Blended tile animations and density controls.',
                            color: Colors.lime,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'Component Experiments',
                        countLabel: '2 items',
                        cards: const [
                          _VariantCardData(
                            route: '/showcase/contact-tile',
                            title: 'Contact Tile Animations',
                            description:
                                'Tap shimmer, hero choreography, and emphasize pulse.',
                            color: Colors.red,
                          ),
                          _VariantCardData(
                            route: '/showcase/theme',
                            title: 'Theme & Tokens',
                            description:
                                'Expanded palettes, glass constants, and dynamic blends.',
                            color: Colors.deepOrange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/app'),
        icon: const Icon(Icons.home_rounded),
        label: const Text('Back to App'),
      ),
    );
  }
}

class _ShowcaseInfoCard extends StatelessWidget {
  const _ShowcaseInfoCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'About this build',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'All experimental UI branches are consolidated here so you can compare visuals, flows, and performance without switching Git branches. Tap any card to jump straight into that variant.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.countLabel,
    required this.cards,
  });

  final String title;
  final String countLabel;
  final List<_VariantCardData> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                countLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final card in cards) ...[
          _VariantCard(data: card),
        ],
      ],
    );
  }
}

class _VariantCardData {
  const _VariantCardData({
    required this.route,
    required this.title,
    required this.description,
    required this.color,
  });

  final String route;
  final String title;
  final String description;
  final Color color;
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({required this.data});

  final _VariantCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(data.route),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: data.color.withOpacity(0.28),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.auto_fix_high_rounded,
                    color: data.color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
