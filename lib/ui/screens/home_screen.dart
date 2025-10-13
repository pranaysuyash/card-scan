import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/contact.dart';
import '../../providers/contact_provider.dart';
import '../widgets/contact_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final ScrollController _scrollController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late AnimationController _pulseAnimationController;
  double _scrollOffset = 0;
  static const double _expandedHeight = 280;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(_handleScrollUpdate);
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_handleScrollUpdate);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _handleScrollUpdate() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(searchResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final contactCount = ref.watch(contactCountProvider);

    final normalizedScroll = (_scrollOffset / _expandedHeight).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildScanButton(context),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ],
                stops: const [0.0, 0.4, 0.8, 1.0],
              ),
            ),
          ),
          IgnorePointer(
            child: SizedBox.expand(
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    top: -120 + (normalizedScroll * 60),
                    left: -80 + (normalizedScroll * 30),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: (1 - normalizedScroll * 0.6).clamp(0.0, 1.0),
                      child: _DecorativeBlob(
                        size: 220,
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.25),
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.15),
                        ],
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    right: -40 + (normalizedScroll * 60),
                    bottom: 140 - (normalizedScroll * 40),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: (0.8 - normalizedScroll * 0.6).clamp(0.0, 0.8),
                      child: _DecorativeBlob(
                        size: 160,
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.2),
                          Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withOpacity(0.12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(contactsProvider);
            },
            edgeOffset: kToolbarHeight + 24,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  stretch: true,
                  expandedHeight: _expandedHeight,
                  title: const Text(
                    'My Cards',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        onPressed: () => context.push('/settings'),
                      ),
                    ),
                  ],
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableHeight =
                          (constraints.maxHeight - kToolbarHeight)
                              .clamp(0.0, _expandedHeight);
                      final expandRatio = _expandedHeight <= kToolbarHeight
                          ? 0.0
                          : (availableHeight /
                                  (_expandedHeight - kToolbarHeight))
                              .clamp(0.0, 1.0);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildHeroHeader(
                            context,
                            expandRatio,
                            contactCount,
                            contactsAsync,
                            searchQuery,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                _buildContactsSliver(
                  context,
                  contactsAsync,
                  searchQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimationController,
        builder: (context, child) {
          final pulseValue = _pulseAnimationController.value;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.3 + (pulseValue * 0.2)),
                  blurRadius: 15 + (pulseValue * 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                _fabAnimationController.forward().then((_) {
                  _fabAnimationController.reverse();
                });
                context.push('/scan');
              },
              icon: const Icon(Icons.camera_alt_rounded, size: 24),
              label: const Text('Scan New Card',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5)),
              elevation: 0,
              extendedPadding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    double expandRatio,
    AsyncValue<int> contactCount,
    AsyncValue<List<Contact>> contactsAsync,
    String searchQuery,
  ) {
    final theme = Theme.of(context);
    final resultsCount = contactsAsync.maybeWhen(
      data: (contacts) => contacts.length,
      orElse: () => null,
    );
    final totalCount = contactCount.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );

    return ClipPath(
      clipper: _HeroCurveClipper(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.secondary.withOpacity(0.6),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: expandRatio,
                      child: const Text(
                        'My Cards',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Opacity(
                      opacity: expandRatio,
                      child: _buildSummaryChip(
                        context,
                        contactCount,
                        resultsCount,
                        totalCount,
                        searchQuery,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchField(context, searchQuery),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(
    BuildContext context,
    AsyncValue<int> contactCount,
    int? resultsCount,
    int? totalCount,
    String searchQuery,
  ) {
    final theme = Theme.of(context);
    return Hero(
      tag: 'contact-summary',
      child: Material(
        color: Colors.transparent,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Container(
            key: ValueKey(
              searchQuery.isEmpty
                  ? 'count_${totalCount ?? 'loading'}'
                  : 'search_${searchQuery}_${resultsCount ?? 'loading'}',
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.2,
              ),
            ),
            child: contactCount.when(
              data: (count) {
                final label = searchQuery.isEmpty
                    ? '$count ${count == 1 ? 'contact' : 'contacts'} saved'
                    : '${resultsCount ?? 0} results for "$searchQuery"';
                return Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                );
              },
              loading: () => SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              error: (_, __) => Text(
                'Contacts unavailable',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, String searchQuery) {
    final theme = Theme.of(context);
    return Hero(
      tag: 'search-bar',
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    child: Icon(
                      Icons.search_rounded,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  SliverPadding _buildContactsSliver(
    BuildContext context,
    AsyncValue<List<Contact>> contactsAsync,
    String searchQuery,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
      sliver: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context, searchQuery),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration:
                      Duration(milliseconds: 400 + (index.clamp(0, 8) * 75)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: ContactTile(
                      contact: contacts[index],
                      onTap: () =>
                          context.push('/contact/${contacts[index].id}'),
                    ),
                  ),
                );
              },
              childCount: contacts.length,
            ),
          );
        },
        loading: () => SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        error: (error, stack) => SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String searchQuery) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.15),
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      blurRadius: 20,
                    )
                  ],
                ),
                child: Icon(
                  Icons.contact_page_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searchQuery.isEmpty ? 'No Contacts Yet' : 'No Matches Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                searchQuery.isEmpty
                    ? 'Tap "Scan New Card" to add your first contact'
                    : 'Try searching for a different name or company',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width,
      size.height - 70,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DecorativeBlob extends StatelessWidget {
  const _DecorativeBlob({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
        ),
      ),
    );
  }
}
