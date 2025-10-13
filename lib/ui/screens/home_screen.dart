import 'dart:ui';

import 'package:flutter/foundation.dart';
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
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late AnimationController _pulseAnimationController;
  late AnimationController _shimmerController;
  late ScrollController _scrollController;
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();
  final List<Contact> _animatedContacts = [];
  int _listChangeId = 0;

  @override
  void initState() {
    super.initState();
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

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    _pulseAnimationController.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(searchResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final contactCount = ref.watch(contactCountProvider);

    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(contactsProvider);
          },
          displacement: 80,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildHeroAppBar(context, searchQuery, contactCount),
              ..._buildContactSlivers(
                context,
                contactsAsync,
                searchQuery,
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildScanButton(context),
      ),
    );
  }

  SliverAppBar _buildHeroAppBar(
    BuildContext context,
    String searchQuery,
    AsyncValue<int> contactCount,
  ) {
    final theme = Theme.of(context);
    const expandedHeight = 260.0;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: expandedHeight,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            onPressed: () => context.push('/settings'),
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.biggest.height;
          final t = ((maxHeight - kToolbarHeight) /
                  (expandedHeight - kToolbarHeight))
              .clamp(0.0, 1.0);
          final collapse = 1 - t;
          final searchAlignmentY = lerpDouble(0.9, 0.1, t)!;
          final horizontalPadding = lerpDouble(24, 16, collapse)!;
          final topPadding = MediaQuery.of(context).padding.top + 16;

          return Stack(
            fit: StackFit.expand,
            children: [
              _GradientBackground(theme: theme, t: t),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(top: topPadding, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: (1 - collapse * 1.6).clamp(0.0, 1.0),
                          child: Text(
                            'My Cards',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment(0, searchAlignmentY.clamp(-1.0, 1.0)),
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: _SearchField(
                            controller: _searchController,
                            searchQuery: searchQuery,
                            onChanged: (value) {
                              ref.read(searchQueryProvider.notifier).state =
                                  value;
                            },
                            onClear: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: contactCount.when(
                          data: (count) => _ContactCountChip(count: count),
                          loading: () => const _ContactCountSkeleton(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildContactSlivers(
    BuildContext context,
    AsyncValue<List<Contact>> contactsAsync,
    String searchQuery,
  ) {
    return contactsAsync.when(
      data: (contacts) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncAnimatedContacts(contacts);
        });

        if (contacts.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(searchQuery: searchQuery),
            ),
          ];
        }

        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 140),
            sliver: SliverAnimatedList(
              key: _listKey,
              initialItemCount: _animatedContacts.length,
              itemBuilder: (context, index, animation) {
                final contact = _animatedContacts[index];
                return _buildAnimatedContactTile(
                  context,
                  contact,
                  animation,
                  index,
                );
              },
            ),
          ),
        ];
      },
      loading: () => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ],
      error: (error, stackTrace) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text('Error: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedContactTile(
    BuildContext context,
    Contact contact,
    Animation<double> animation,
    int index,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: ContactTile(
          contact: contact,
          onTap: () => context.push('/contact/${contact.id}'),
        ),
      ),
    );
  }

  void _syncAnimatedContacts(List<Contact> contacts) {
    final listState = _listKey.currentState;
    if (listState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncAnimatedContacts(contacts);
      });
      return;
    }

    final newIds = contacts.map((c) => c.id).toList();
    final currentIds = _animatedContacts.map((c) => c.id).toList();

    if (listEquals(newIds, currentIds)) {
      for (int i = 0; i < contacts.length; i++) {
        _animatedContacts[i] = contacts[i];
      }
      return;
    }

    _listChangeId++;
    final changeId = _listChangeId;
    final contactsCopy = List<Contact>.from(contacts);

    for (int i = _animatedContacts.length - 1; i >= 0; i--) {
      final removedContact = _animatedContacts.removeAt(i);
      listState.removeItem(
        i,
        (context, animation) => _buildAnimatedContactTile(
          context,
          removedContact,
          animation,
          i,
        ),
        duration: const Duration(milliseconds: 220),
      );
    }

    if (contactsCopy.isEmpty) {
      return;
    }

    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted || changeId != _listChangeId) {
        return;
      }
      for (int i = 0; i < contactsCopy.length; i++) {
        final contact = contactsCopy[i];
        _animatedContacts.insert(i, contact);
        listState.insertItem(
          i,
          duration: Duration(milliseconds: 280 + (i * 60)),
        );
      }
    });
  }

  Widget _buildScanButton(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimationController,
          _shimmerController,
        ]),
        builder: (context, child) {
          final pulseValue = _pulseAnimationController.value;
          final shimmerValue = _shimmerController.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary
                          .withOpacity(0.25 + (pulseValue * 0.2)),
                      theme.colorScheme.primary.withOpacity(0),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary
                          .withOpacity(0.35 + (pulseValue * 0.2)),
                      blurRadius: 20 + (pulseValue * 16),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (rect) {
                    final shimmerOffset = rect.width * shimmerValue;
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                        theme.colorScheme.primary,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      transform: GradientTranslation(Offset(shimmerOffset, 0)),
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.srcATop,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      _fabAnimationController.forward().then((_) {
                        if (mounted) {
                          _fabAnimationController.reverse();
                        }
                      });
                      context.push('/scan');
                    },
                    icon: const Icon(Icons.camera_alt_rounded, size: 24),
                    label: const Text(
                      'Scan New Card',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    elevation: 0,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    extendedPadding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
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
                color: theme.colorScheme.surface.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: controller,
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
                          onPressed: onClear,
                        )
                      : null,
                  border: InputBorder.none,
                ),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCountChip extends StatelessWidget {
  final int count;

  const _ContactCountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: count),
            duration: const Duration(milliseconds: 450),
            builder: (context, value, _) {
              return Text(
                '$value ${value == 1 ? 'contact' : 'contacts'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ContactCountSkeleton extends StatelessWidget {
  const _ContactCountSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(32),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String searchQuery;

  const _EmptyState({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.15),
                    theme.colorScheme.primary.withOpacity(0.0),
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
                      color:
                          theme.colorScheme.primary.withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.contact_page_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searchQuery.isEmpty ? 'No Contacts Yet' : 'No Matches Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              searchQuery.isEmpty
                  ? 'Tap "Scan New Card" to add your first contact'
                  : 'Try searching for a different name or company',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  final ThemeData theme;
  final double t;

  const _GradientBackground({required this.theme, required this.t});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.25),
                theme.colorScheme.primaryContainer.withOpacity(0.2),
              ],
            ),
          ),
        ),
        Positioned(
          top: -60 * t,
          left: -40,
          child: _BlurBlob(
            size: 180,
            colors: [
              theme.colorScheme.secondary.withOpacity(0.45),
              theme.colorScheme.primary.withOpacity(0.3),
            ],
          ),
        ),
        Positioned(
          bottom: -40,
          right: -30,
          child: _BlurBlob(
            size: 200,
            colors: [
              theme.colorScheme.tertiary.withOpacity(0.4),
              theme.colorScheme.primary.withOpacity(0.2),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _BlurBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: colors),
          ),
        ),
      ),
    );
  }
}

class GradientTranslation extends GradientTransform {
  final Offset offset;

  const GradientTranslation(this.offset);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.identity()..translate(offset.dx, offset.dy);
  }
}
