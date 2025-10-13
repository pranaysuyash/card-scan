import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    _pulseAnimationController.dispose();
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
        appBar: AppBar(
          title: const Text('My Cards',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1.5),
                  ),
                  child: Icon(Icons.settings_outlined,
                      color: Theme.of(context).colorScheme.primary),
                ),
                onPressed: () => context.push('/settings'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar with animation
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Hero(
                tag: 'search-bar',
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search contacts...',
                            hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)),
                            prefixIcon: Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 12),
                              child: Icon(Icons.search_rounded,
                                  size: 24,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(searchQueryProvider.notifier)
                                          .state = '';
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            filled: false,
                          ),
                          onChanged: (value) {
                            ref.read(searchQueryProvider.notifier).state =
                                value;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Contact Count with fade animation
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    contactCount.when(
                      data: (count) => TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: count),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Text(
                            '$value ${value == 1 ? 'contact' : 'contacts'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                          );
                        },
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Contacts List with staggered animation
            Expanded(
              child: contactsAsync.when(
                data: (contacts) {
                  if (contacts.isEmpty) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Opacity(
                            opacity: value,
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    searchQuery.isEmpty
                                        ? 'No Contacts Yet'
                                        : 'No Matches Found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40.0),
                                    child: Text(
                                      searchQuery.isEmpty
                                          ? 'Tap "Scan New Card" to add your first contact'
                                          : 'Try searching for a different name or company',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
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
                          ),
                        );
                      },
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(contactsProvider);
                    },
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.only(left: 4, right: 4, bottom: 120),
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (index * 75)),
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
                          child: ContactTile(
                            contact: contacts[index],
                            onTap: () =>
                                context.push('/contact/${contacts[index].id}'),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildScanButton(context),
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
            child: Hero(
              tag: 'primary-action-cta',
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
            ),
          );
        },
      ),
    );
  }
}
