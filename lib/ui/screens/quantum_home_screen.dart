import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../providers/contact_provider.dart';
import '../../services/monetization/ad_service.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import '../quantum_theme.dart';
import '../widgets/contact_tile.dart';
import '../widgets/particle_system.dart';
import '../widgets/neural_glass_container.dart';

class QuantumHomeScreen extends ConsumerStatefulWidget {
  const QuantumHomeScreen({super.key});

  @override
  ConsumerState<QuantumHomeScreen> createState() => _QuantumHomeScreenState();
}

class _QuantumHomeScreenState extends ConsumerState<QuantumHomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _entryAnimationController;
  late Animation<double> _fabScaleAnimation;
  final AdService _adService = AdService();

  int _scanCount = 0;
  static const int _adFrequency = 3;

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
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _entryAnimationController = AnimationController(
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
    _entryAnimationController.dispose();
    _adService.disposeBannerAd();
    super.dispose();
  }

  void _onScanPressed() async {
    final soundManager = SoundManager();
    final hapticService = HapticService();

    hapticService.lightImpact();
    await soundManager.playTap();

    _scanCount++;

    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });

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

    return Scaffold(
      backgroundColor: QuantumTheme.deepSpace,
      body: Stack(
        children: [
          // Particle background
          const Positioned.fill(
            child: ParticleSystem(
              particleCount: 80,
              maxVelocity: 0.3,
            ),
          ),

          // Morphing blobs
          MorphingBlob(
            size: 320,
            color: QuantumTheme.primaryPurple.withOpacity(0.2),
            alignment: Alignment.topLeft,
          ),
          MorphingBlob(
            size: 320,
            color: QuantumTheme.primaryBlue.withOpacity(0.2),
            alignment: Alignment.bottomRight,
            duration: const Duration(seconds: 10),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildHeaderSection(contactCount),
                _buildSearchBar(searchQuery),
                _buildAdBanner(),
                _buildContactsList(contactsAsync, searchQuery),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildQuantumScanButton(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and title
          FadeTransition(
            opacity: _entryAnimationController,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.2, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _entryAnimationController,
                curve: Curves.easeOut,
              )),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: QuantumTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: QuantumTheme.neuralGlow(blurRadius: 20),
                    ),
                    child: const Icon(
                      Icons.contact_page_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUANTUM',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: QuantumTheme.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Neural Network',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: QuantumTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          FadeTransition(
            opacity: _entryAnimationController,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _entryAnimationController,
                curve: Curves.easeOut,
              )),
              child: Row(
                children: [
                  // Premium button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFfbbf24), Color(0xFFf97316)],
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
                    child: IconButton(
                      icon: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _showPremiumDialog(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Settings button
                  NeuralGlassContainer(
                    padding: const EdgeInsets.all(10),
                    borderRadius: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: QuantumTheme.primaryBlue,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => context.push('/settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(AsyncValue<int> contactCount) {
    return FadeTransition(
      opacity: _entryAnimationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entryAnimationController,
          curve: Curves.easeOut,
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: NeuralGlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 24,
            child: Row(
              children: [
                Expanded(
                  child: contactCount.when(
                    data: (count) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              QuantumTheme.primaryGradient.createShader(bounds),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          count == 1 ? 'Contact Saved' : 'Contacts Saved',
                          style: TextStyle(
                            fontSize: 14,
                            color: QuantumTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading count'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: QuantumTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: QuantumTheme.neuralGlow(),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(String searchQuery) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: FadeTransition(
        opacity: _entryAnimationController,
        child: NeuralGlassContainer(
          padding: EdgeInsets.zero,
          borderRadius: 20,
          blur: 10,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: QuantumTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name, company, or skills...',
              hintStyle: TextStyle(color: QuantumTheme.textTertiary),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 20, right: 12),
                child: Icon(
                  Icons.search_rounded,
                  size: 24,
                  color: QuantumTheme.primaryBlue,
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
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

  Widget _buildContactsList(
    AsyncValue<List<dynamic>> contactsAsync,
    String searchQuery,
  ) {
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
            backgroundColor: QuantumTheme.deepSpace,
            color: QuantumTheme.primaryBlue,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 120),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _entryAnimationController,
                      curve: Interval(
                        (index * 0.1).clamp(0.0, 1.0),
                        ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _entryAnimationController,
                        curve: Interval(
                          (index * 0.1).clamp(0.0, 1.0),
                          ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: ContactTile(
                      contact: contacts[index],
                      onTap: () =>
                          context.push('/contact/${contacts[index].id}'),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: QuantumTheme.primaryBlue,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: QuantumTheme.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String searchQuery) {
    return Center(
      child: FadeTransition(
        opacity: _entryAnimationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    QuantumTheme.primaryBlue.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: QuantumTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: QuantumTheme.neuralGlow(blurRadius: 30),
                ),
                child: Icon(
                  searchQuery.isEmpty
                      ? Icons.contact_page_outlined
                      : Icons.search_off_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              searchQuery.isEmpty ? 'Ready to Network?' : 'No Matches Found',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: QuantumTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                searchQuery.isEmpty
                    ? 'Scan your first business card to start building your professional network!'
                    : 'Try searching for a different name, company, or skill',
                style: TextStyle(
                  fontSize: 16,
                  color: QuantumTheme.textSecondary,
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
                color: QuantumTheme.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: QuantumTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              feature['title'] as String,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: QuantumTheme.textPrimary,
              ),
            ),
            Text(
              feature['subtitle'] as String,
              style: TextStyle(
                fontSize: 11,
                color: QuantumTheme.textTertiary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildQuantumScanButton() {
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
                  color: QuantumTheme.primaryBlue
                      .withOpacity(0.3 + (pulseValue * 0.2)),
                  blurRadius: 20 + (pulseValue * 15),
                  spreadRadius: 3,
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: _onScanPressed,
              backgroundColor: QuantumTheme.primaryBlue,
              icon: const Icon(Icons.camera_alt_rounded, size: 26),
              label: const Text(
                'Neural Scan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              elevation: 0,
            ),
          );
        },
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeuralGlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFfbbf24), Color(0xFFf97316)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Go Premium',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: QuantumTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Unlock premium features:',
                style: TextStyle(
                  color: QuantumTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                'Remove all ads',
                'Unlimited scans',
                'Advanced export options',
                'Cloud sync (optional)',
                'Premium support',
              ].map((feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: QuantumTheme.successGreen,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          feature,
                          style: const TextStyle(
                            color: QuantumTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Maybe Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showRewardedAd();
                      },
                      child: const Text('Watch Ad'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRewardedAd() {
    _adService.showRewardedAd(
      onRewarded: (reward) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Premium features unlocked for 24 hours!'),
            backgroundColor: QuantumTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onAdDismissed: () {},
    );
  }
}
