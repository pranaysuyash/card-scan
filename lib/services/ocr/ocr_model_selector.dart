import 'package:flutter/foundation.dart';

import 'ocr_service.dart';
import 'enhanced_ocr_service.dart';
import 'mlkit_ocr_service.dart';

class OcrModelSelector {
  static OcrService? _cachedService;

  /// Get the best available OCR service
  static OcrService getService() {
    if (_cachedService != null) {
      return _cachedService!;
    }

    // For now, use enhanced service
    // In future, could select based on device capabilities
    _cachedService = EnhancedOcrService();
    return _cachedService!;
  }

  /// Force refresh service (useful for testing)
  static void clearCache() {
    _cachedService?.dispose();
    _cachedService = null;
  }

  /// Get service based on device capabilities
  static OcrService getServiceForDevice() {
    if (kIsWeb) {
      return MlKitOcrService(); // Web doesn't support advanced local models
    }

    // Future: Check device capabilities
    // - High-end devices: Use advanced local models
    // - Low-end devices: Use basic ML Kit
    // - iOS: Use Vision framework
    // - Android: Use ML Kit with custom enhancements

    return EnhancedOcrService();
  }

  /// Get service based on user preference
  static OcrService getServiceForMode(OcrMode mode) {
    switch (mode) {
      case OcrMode.fast:
        return MlKitOcrService();
      case OcrMode.accurate:
        return EnhancedOcrService();
      case OcrMode.offline:
        return EnhancedOcrService(); // Enhanced works better offline
    }
  }
}

enum OcrMode {
  fast, // Quick scan, basic accuracy
  accurate, // Slower but more accurate
  offline, // Works without internet
}