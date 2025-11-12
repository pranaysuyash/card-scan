import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/either.dart';

/// Subscription and in-app purchase service
/// Manages freemium model with Pro and Business tiers
class SubscriptionService {
  static const String _revenueCatApiKey = 'YOUR_REVENUECAT_API_KEY';
  static const String _subscriptionStatusKey = 'subscription_status';

  // Entitlement IDs
  static const String proEntitlement = 'pro';
  static const String businessEntitlement = 'business';

  // Product IDs
  static const String monthlyProProduct = 'pro_monthly';
  static const String yearlyProProduct = 'pro_yearly';
  static const String monthlyBusinessProduct = 'business_monthly';
  static const String yearlyBusinessProduct = 'business_yearly';

  bool _initialized = false;
  SubscriptionTier _currentTier = SubscriptionTier.free;

  bool get isInitialized => _initialized;
  SubscriptionTier get currentTier => _currentTier;
  bool get isPro => _currentTier == SubscriptionTier.pro || _currentTier == SubscriptionTier.business;
  bool get isBusiness => _currentTier == SubscriptionTier.business;

  /// Initialize RevenueCat
  Future<Either<Failure, void>> initialize(String userId) async {
    try {
      if (_initialized) {
        return const Right(null);
      }

      await Purchases.configure(
        PurchasesConfiguration(_revenueCatApiKey)
          ..appUserID = userId,
      );

      // Check current subscription status
      await _checkSubscriptionStatus();

      _initialized = true;
      return const Right(null);
    } catch (e) {
      return Left(PaymentFailure(
        message: 'Failed to initialize subscription service',
        details: e,
      ));
    }
  }

  /// Check subscription status
  Future<Either<Failure, SubscriptionTier>> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();

      if (customerInfo.entitlements.active.containsKey(businessEntitlement)) {
        _currentTier = SubscriptionTier.business;
      } else if (customerInfo.entitlements.active.containsKey(proEntitlement)) {
        _currentTier = SubscriptionTier.pro;
      } else {
        _currentTier = SubscriptionTier.free;
      }

      // Cache subscription status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_subscriptionStatusKey, _currentTier.name);

      return Right(_currentTier);
    } catch (e) {
      return Left(PaymentFailure(
        message: 'Failed to check subscription status',
        details: e,
      ));
    }
  }

  /// Get available products
  Future<Either<Failure, List<StoreProduct>>> getProducts() async {
    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        return Left(PaymentFailure(
          message: 'No products available',
          code: 'NO_PRODUCTS',
        ));
      }

      final products = offerings.current!.availablePackages
          .map((package) => package.storeProduct)
          .toList();

      return Right(products);
    } catch (e) {
      return Left(PaymentFailure(
        message: 'Failed to fetch products',
        details: e,
      ));
    }
  }

  /// Purchase a subscription
  Future<Either<Failure, CustomerInfo>> purchaseSubscription(String productId) async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        return Left(PaymentFailure(
          message: 'No offerings available',
          code: 'NO_OFFERINGS',
        ));
      }

      final package = offerings.current!.availablePackages.firstWhere(
        (p) => p.storeProduct.identifier == productId,
        orElse: () => throw PaymentException(
          message: 'Product not found',
          code: 'PRODUCT_NOT_FOUND',
        ),
      );

      final customerInfo = await Purchases.purchasePackage(package);
      await _checkSubscriptionStatus();

      return Right(customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return Left(PaymentFailure(
          message: 'Purchase cancelled',
          code: 'CANCELLED',
        ));
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        return Left(PaymentFailure(
          message: 'Payment pending',
          code: 'PENDING',
        ));
      }

      return Left(PaymentFailure(
        message: e.message ?? 'Purchase failed',
        code: errorCode.name,
        details: e,
      ));
    } catch (e) {
      return Left(PaymentFailure(
        message: 'Unexpected purchase error',
        details: e,
      ));
    }
  }

  /// Restore purchases
  Future<Either<Failure, CustomerInfo>> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      await _checkSubscriptionStatus();
      return Right(customerInfo);
    } catch (e) {
      return Left(PaymentFailure(
        message: 'Failed to restore purchases',
        details: e,
      ));
    }
  }

  /// Check if user can access feature
  bool canAccessFeature(ProFeature feature) {
    switch (feature) {
      case ProFeature.unlimitedContacts:
        return isPro;
      case ProFeature.batchProcessing:
        return isPro;
      case ProFeature.cloudSync:
        return isPro;
      case ProFeature.advancedOcr:
        return isPro;
      case ProFeature.qrCodeGeneration:
        return isPro;
      case ProFeature.voiceNotes:
        return isPro;
      case ProFeature.noAds:
        return isPro;
      case ProFeature.teamCollaboration:
        return isBusiness;
      case ProFeature.crmIntegration:
        return isBusiness;
      case ProFeature.advancedAnalytics:
        return isBusiness;
      case ProFeature.apiAccess:
        return isBusiness;
      case ProFeature.prioritySupport:
        return isBusiness;
    }
  }

  /// Get feature limits
  FeatureLimits getFeatureLimits() {
    switch (_currentTier) {
      case SubscriptionTier.free:
        return const FeatureLimits(
          maxContacts: 50,
          maxBatchSize: 0,
          cloudStorageGB: 0,
          teamMembers: 0,
        );
      case SubscriptionTier.pro:
        return const FeatureLimits(
          maxContacts: -1, // unlimited
          maxBatchSize: 100,
          cloudStorageGB: 10,
          teamMembers: 0,
        );
      case SubscriptionTier.business:
        return const FeatureLimits(
          maxContacts: -1, // unlimited
          maxBatchSize: 1000,
          cloudStorageGB: 100,
          teamMembers: 10,
        );
    }
  }

  /// Cancel subscription
  /// Note: Actual cancellation happens in App Store/Play Store
  Future<Either<Failure, void>> showManageSubscription() async {
    try {
      await Purchases.showManagementUI();
      return const Right(null);
    } catch (e) {
      return Left(PaymentFailure(
        message: 'Failed to show subscription management',
        details: e,
      ));
    }
  }
}

/// Subscription tiers
enum SubscriptionTier {
  free,
  pro,
  business,
}

/// Pro features
enum ProFeature {
  unlimitedContacts,
  batchProcessing,
  cloudSync,
  advancedOcr,
  qrCodeGeneration,
  voiceNotes,
  noAds,
  teamCollaboration,
  crmIntegration,
  advancedAnalytics,
  apiAccess,
  prioritySupport,
}

/// Feature limits per tier
class FeatureLimits {
  final int maxContacts; // -1 = unlimited
  final int maxBatchSize;
  final int cloudStorageGB;
  final int teamMembers;

  const FeatureLimits({
    required this.maxContacts,
    required this.maxBatchSize,
    required this.cloudStorageGB,
    required this.teamMembers,
  });

  bool get hasUnlimitedContacts => maxContacts == -1;
}

import 'package:flutter/services.dart';
import '../../../core/error/exceptions.dart';
