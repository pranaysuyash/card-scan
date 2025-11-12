import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger_service.dart';

/// Biometric authentication service for securing sensitive data
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();

  factory BiometricAuthService() => _instance;

  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LoggerService _logger = LoggerService();

  static const String _biometricEnabledKey = 'biometric_auth_enabled';
  static const String _appLockEnabledKey = 'app_lock_enabled';

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (e) {
      _logger.error('Error checking biometric availability', error: e);
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _logger.error('Error getting available biometrics', error: e);
      return [];
    }
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      _logger.error('Error reading biometric enabled status', error: e);
      return false;
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      // First verify the user can authenticate
      final authenticated = await authenticate(
        reason: 'Enable biometric authentication',
      );

      if (authenticated) {
        await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
        _logger.info('Biometric authentication enabled');
        return true;
      }

      return false;
    } catch (e) {
      _logger.error('Error enabling biometric', error: e);
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      await _secureStorage.write(key: _biometricEnabledKey, value: 'false');
      _logger.info('Biometric authentication disabled');
    } catch (e) {
      _logger.error('Error disabling biometric', error: e);
    }
  }

  /// Check if app lock is enabled
  Future<bool> isAppLockEnabled() async {
    try {
      final value = await _secureStorage.read(key: _appLockEnabledKey);
      return value == 'true';
    } catch (e) {
      _logger.error('Error reading app lock status', error: e);
      return false;
    }
  }

  /// Enable app lock
  Future<void> setAppLock(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _appLockEnabledKey,
        value: enabled.toString(),
      );
      _logger.info('App lock ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      _logger.error('Error setting app lock', error: e);
    }
  }

  /// Authenticate user with biometrics
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _logger.warning('Biometric authentication not available on this device');
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Allow PIN/password as fallback
        ),
      );
    } on PlatformException catch (e) {
      _logger.error('Biometric authentication error', error: e);

      if (e.code == 'NotAvailable') {
        _logger.warning('Biometric authentication not available');
      } else if (e.code == 'NotEnrolled') {
        _logger.warning('No biometrics enrolled on device');
      } else if (e.code == 'LockedOut') {
        _logger.warning('Biometric authentication locked out');
      } else if (e.code == 'PermanentlyLockedOut') {
        _logger.warning('Biometric authentication permanently locked out');
      }

      return false;
    } catch (e) {
      _logger.error('Unexpected biometric authentication error', error: e);
      return false;
    }
  }

  /// Authenticate for sensitive operation
  Future<bool> authenticateForSensitiveOperation(String operation) async {
    final isEnabled = await isBiometricEnabled();

    if (!isEnabled) {
      // Biometric not enabled, allow operation
      return true;
    }

    return await authenticate(
      reason: 'Authenticate to $operation',
      useErrorDialogs: true,
      stickyAuth: true,
    );
  }

  /// Authenticate before viewing contact
  Future<bool> authenticateForViewContact() async {
    return await authenticateForSensitiveOperation('view contact details');
  }

  /// Authenticate before exporting contacts
  Future<bool> authenticateForExport() async {
    return await authenticateForSensitiveOperation('export contacts');
  }

  /// Authenticate before deleting contact
  Future<bool> authenticateForDelete() async {
    return await authenticateForSensitiveOperation('delete contact');
  }

  /// Authenticate before accessing settings
  Future<bool> authenticateForSettings() async {
    return await authenticateForSensitiveOperation('access settings');
  }

  /// Authenticate at app launch (if app lock is enabled)
  Future<bool> authenticateAtLaunch() async {
    final isAppLockEnabled = await isAppLockEnabled();

    if (!isAppLockEnabled) {
      return true; // No app lock, allow access
    }

    final isBiometricAvailable = await isBiometricAvailable();

    if (!isBiometricAvailable) {
      _logger.warning('App lock enabled but biometric not available');
      return true; // Fail open - don't lock user out
    }

    return await authenticate(
      reason: 'Unlock Quantum Card Scanner',
      useErrorDialogs: true,
      stickyAuth: true,
    );
  }

  /// Get user-friendly biometric type name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Biometric';
      case BiometricType.weak:
        return 'Basic Biometric';
    }
  }

  /// Get available biometric types as human-readable string
  Future<String> getAvailableBiometricsDescription() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.isEmpty) {
      return 'No biometric authentication available';
    }

    final names = biometrics.map((type) => getBiometricTypeName(type)).toList();

    if (names.length == 1) {
      return names.first;
    }

    return names.join(', ');
  }

  /// Check if specific biometric type is available
  Future<bool> isBiometricTypeAvailable(BiometricType type) async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(type);
  }

  /// Cancel any ongoing authentication
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      _logger.error('Error stopping authentication', error: e);
    }
  }
}
