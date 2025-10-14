import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../providers/contact_provider.dart';
import '../../services/monetization/ad_service.dart';
import '../widgets/contact_tile.dart';

class EnhancedHomeScreen extends ConsumerStatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  ConsumerState<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends ConsumerState<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fabScaleAnimation;
  final AdService _adService = AdService();
  
  int _scanCount = 0;
  static const int _adFrequency = 3; // Show ad every 3 scans

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAds();
  }

  void _initializeAnimations() {
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

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  void _initializeAds() {
    _adService.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    _pulseAnimationController.dispose();
    _cardAnimationController.dispose();
    _adService.disposeBannerAd();
    super.dispose();
  }

  void _onScanPressed() {
    _scanCount++;
    
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    
    // Show interstitial ad every few scans
    if (_scanCount % _adFrequency == 0) {
      _adService.showInterstitialAd(
        onAdDismissed: () => context.push('/scan'),
      );
    } else {
      context.push('/scan');
    }
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
            Theme.of(context).colorScheme.primary.withOpacity(0.08),
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            _buildHeaderSection(contactCount),
            _buildSearchBar(searchQuery),
            _buildAdBanner(),
            _buildContactsList(contactsAsync, searchQuery),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildEnhancedScanButton(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: AnimatedBuilder(
        animation: _cardAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _cardAnimationController.value)),
            child: Opacity(
              opacity: _cardAnimationController.value,
              child: const Text(
                'My Cards',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        AnimatedBuilder(
          animation: _cardAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _cardAnimationController.value,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    // Premium upgrade button (for monetization)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade400,
                                Colors.orange.shade500,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: () => _showPremiumDialog(context),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.settings_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderSection(AsyncValue<int> contactCount) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _cardAnimationController.value)),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: contactCount.when(
                      data: (count) => TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: count),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$value',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                              ),
                              Text(
                                value == 1 ? 'Contact Saved' : 'Contacts Saved',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  // Quick stats or actions
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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

  Widget _buildSearchBar(String searchQuery) {
    return Padding(
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
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, company, or skills...',
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 12),
                      child: Icon(
                        Icons.search_rounded,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
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
      ),
    );
  }

  Widget _buildAdBanner() {
    if (_adService.isBannerAdLoaded && _adService.bannerAd != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: _adService.bannerAd!.size.width.toDouble(),
        height: _adService.bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _adService.bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildContactsList(AsyncValue<List<dynamic>> contactsAsync, String searchQuery) {
    return Expanded(
      child: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return _buildEmptyState(searchQuery);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(contactsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 120),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: ContactTile(
                    contact: contacts[index],
                    onTap: () => context.push('/contact/${contacts[index].id}'),
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
    );
  }

  Widget _buildEmptyState(String searchQuery) {
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
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          Theme.of(context).colorScheme.primary.withOpacity(0.0),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        searchQuery.isEmpty
                            ? Icons.contact_page_outlined
                            : Icons.search_off_rounded,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    searchQuery.isEmpty ? 'Ready to Network?' : 'No Matches Found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      searchQuery.isEmpty
                          ? 'Scan your first business card to start building your professional network!'
                          : 'Try searching for a different name, company, or skill',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                            height: 1.6,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (searchQuery.isEmpty) ...[
                    const SizedBox(height: 32),
                    _buildFeatureHighlights(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureHighlights() {
    final features = [
      {
        'icon': Icons.camera_alt_rounded,
        'title': 'Smart Scanning',
        'subtitle': 'AI-powered OCR',
      },
      {
        'icon': Icons.cloud_off_rounded,
        'title': 'Private & Secure',
        'subtitle': 'Local-first storage',
      },
      {
        'icon': Icons.share_rounded,
        'title': 'Easy Export',
        'subtitle': 'Multiple formats',
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: features.map((feature) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              feature['title'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              feature['subtitle'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: 11,
                  ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEnhancedScanButton(BuildContext context) {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimationController,
        builder: (context, child) {
          final pulseValue = _pulseAnimationController.value;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.3 + (pulseValue * 0.2)),
                  blurRadius: 20 + (pulseValue * 15),
                  spreadRadius: 3,
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: _onScanPressed,
              icon: const Icon(Icons.camera_alt_rounded, size: 26),
              label: const Text(
                'Scan New Card',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              elevation: 0,
              extendedPadding:
                  const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            ),
          );
        },
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: Colors.amber.shade600,
            ),
            const SizedBox(width: 8),
            const Text('Go Premium'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unlock premium features:'),
            const SizedBox(height: 16),
            _buildPremiumFeature('Remove all ads'),
            _buildPremiumFeature('Unlimited scans'),
            _buildPremiumFeature('Advanced export options'),
            _buildPremiumFeature('Cloud sync (optional)'),
            _buildPremiumFeature('Premium support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle premium upgrade
              Navigator.pop(context);
              _showRewardedAd();
            },
            child: const Text('Watch Ad for Preview'),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }

  void _showRewardedAd() {
    _adService.showRewardedAd(
      onRewarded: (reward) {
        // Temporarily unlock premium features or give bonus
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks! Premium features unlocked for 24 hours!'),
            backgroundColor: Colors.green,
          ),
        );
      },
      onAdDismissed: () {
        // Handle ad dismissed
      },
    );
  }
}
