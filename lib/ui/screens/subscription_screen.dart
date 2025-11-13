import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/subscription/services/subscription_service.dart';
import '../quantum_theme.dart';
import '../widgets/glass_container.dart';

/// Subscription and pricing screen
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isYearly = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _purchaseSubscription(String productId) async {
    setState(() {
      _isLoading = true;
    });

    final subscriptionService = SubscriptionService();
    final result = await subscriptionService.purchaseSubscription(productId);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: QuantumTheme.errorRed,
          ),
        );
      },
      (customerInfo) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated!'),
            backgroundColor: QuantumTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      },
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              QuantumTheme.deepSpace,
              QuantumTheme.darkPurple,
              QuantumTheme.deepSpace,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Text(
                      'Choose Your Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance close button
                  ],
                ),
              ),

              // Premium badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      QuantumTheme.primaryBlue,
                      QuantumTheme.accentPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Unlock Premium Features',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Billing toggle
              GlassContainer(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildBillingOption('Monthly', !_isYearly),
                      ),
                      Expanded(
                        child: _buildBillingOption('Yearly', _isYearly, discount: '20% OFF'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Plans
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildPlanCard(
                      title: 'Free',
                      price: '\$0',
                      period: 'forever',
                      features: [
                        '50 contacts',
                        'Basic scanning',
                        'Local storage only',
                        'vCard export',
                      ],
                      isCurrentPlan: true,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    _buildPlanCard(
                      title: 'Pro',
                      price: _isYearly ? '\$49.99' : '\$4.99',
                      period: _isYearly ? 'per year' : 'per month',
                      features: [
                        'Unlimited contacts',
                        'Batch processing',
                        'Cloud sync',
                        'Advanced OCR',
                        'QR code generation',
                        'Voice notes',
                        'No ads',
                      ],
                      isRecommended: true,
                      productId: _isYearly
                          ? SubscriptionService.yearlyProProduct
                          : SubscriptionService.monthlyProProduct,
                      color: QuantumTheme.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    _buildPlanCard(
                      title: 'Business',
                      price: _isYearly ? '\$149.99' : '\$14.99',
                      period: _isYearly ? 'per year' : 'per month',
                      features: [
                        'Everything in Pro',
                        'Team sharing (10 users)',
                        'CRM integrations',
                        'Advanced analytics',
                        'API access',
                        'Priority support',
                      ],
                      productId: _isYearly
                          ? SubscriptionService.yearlyBusinessProduct
                          : SubscriptionService.monthlyBusinessProduct,
                      color: QuantumTheme.accentPurple,
                    ),
                  ],
                ),
              ),

              // Restore purchases
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () async {
                    final subscriptionService = SubscriptionService();
                    await subscriptionService.restorePurchases();
                  },
                  child: Text(
                    'Restore Purchases',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillingOption(String label, bool isSelected, {String? discount}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isYearly = label == 'Yearly';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? QuantumTheme.primaryBlue
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (discount != null && isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: QuantumTheme.successGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  discount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required Color color,
    String? productId,
    bool isRecommended = false,
    bool isCurrentPlan = false,
  }) {
    return GlassContainer(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: isRecommended
                  ? Border.all(color: QuantumTheme.primaryBlue, width: 2)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isRecommended) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              QuantumTheme.primaryBlue,
                              QuantumTheme.accentPurple,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'POPULAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        period,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan || _isLoading
                        ? null
                        : () {
                            if (productId != null) {
                              _purchaseSubscription(productId);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? Colors.white.withOpacity(0.2)
                          : color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            isCurrentPlan ? 'Current Plan' : 'Get Started',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
