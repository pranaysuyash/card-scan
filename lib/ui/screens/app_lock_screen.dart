import 'package:flutter/material.dart';
import 'package:card_scan/services/biometric_auth_service.dart';
import 'package:card_scan/ui/quantum_theme.dart';

/// Screen shown when app lock is enabled
class AppLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AppLockScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  final BiometricAuthService _biometricService = BiometricAuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isAuthenticating = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final description = await _biometricService.getAvailableBiometricsDescription();
    setState(() {
      _biometricType = description;
    });

    // Auto-trigger authentication after a short delay
    await Future.delayed(const Duration(milliseconds: 500));
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final authenticated = await _biometricService.authenticateAtLaunch();

      if (authenticated) {
        widget.onAuthenticated();
      } else {
        setState(() {
          _isAuthenticating = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              QuantumTheme.deepSpace,
              QuantumTheme.primaryBlue.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon/Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            QuantumTheme.primaryBlue,
                            QuantumTheme.primaryPurple,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: QuantumTheme.primaryBlue.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // App Name
                    const Text(
                      'Quantum Card Scanner',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Lock Message
                    Text(
                      'Your contacts are secure',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 64),

                    // Biometric Icon
                    if (_isAuthenticating)
                      Column(
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                QuantumTheme.accentPink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Authenticating...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Icon(
                            Icons.fingerprint,
                            size: 80,
                            color: QuantumTheme.accentPink,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Tap to unlock with $_biometricType',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _authenticate,
                            icon: const Icon(Icons.lock_open),
                            label: const Text('Unlock'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: QuantumTheme.accentPink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
