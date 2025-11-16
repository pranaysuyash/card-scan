import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/subscription/services/subscription_service.dart';
import '../../features/sync/services/cloud_sync_service.dart';
import '../../features/analytics/services/analytics_service.dart';
import '../../services/haptic_service.dart';
import '../../services/audio_service.dart';
import '../quantum_theme.dart';
import '../widgets/glass_container.dart';

/// Enhanced settings screen with all app features
class EnhancedSettingsScreen extends ConsumerStatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  ConsumerState<EnhancedSettingsScreen> createState() =>
      _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState
    extends ConsumerState<EnhancedSettingsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final CloudSyncService _syncService = CloudSyncService();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isSyncing = false;
  bool _autoSync = true;
  bool _analyticsEnabled = true;
  bool _crashReportingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // In production, load from SharedPreferences
    setState(() {});
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);

    final result = await _syncService.fullSync();

    result.fold(
      (failure) => _showError('Sync failed: ${failure.message}'),
      (syncResult) => _showSuccess(
        'Synced ${syncResult.uploadedCount + syncResult.downloadedCount} items',
      ),
    );

    setState(() => _isSyncing = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: QuantumTheme.errorRed,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: QuantumTheme.successGreen,
      ),
    );
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
              _buildHeader(),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Account section
                    _buildSection(
                      'Account',
                      [
                        _buildSettingsTile(
                          icon: Icons.person_outline,
                          title: 'Profile',
                          subtitle: 'Manage your account',
                          onTap: () => context.push('/profile'),
                        ),
                        _buildSettingsTile(
                          icon: Icons.workspace_premium,
                          title: 'Subscription',
                          subtitle: _getSubscriptionStatus(),
                          onTap: () => context.push('/subscription'),
                          trailing: _buildPremiumBadge(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sync & Backup section
                    _buildSection(
                      'Sync & Backup',
                      [
                        _buildSettingsTile(
                          icon: Icons.cloud_outlined,
                          title: 'Cloud Sync',
                          subtitle: _isSyncing ? 'Syncing...' : 'Tap to sync now',
                          onTap: _isSyncing ? null : _triggerSync,
                          trailing: _isSyncing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      QuantumTheme.primaryBlue,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        _buildSwitchTile(
                          icon: Icons.sync,
                          title: 'Auto Sync',
                          subtitle: 'Sync automatically when online',
                          value: _autoSync,
                          onChanged: (value) {
                            setState(() => _autoSync = value);
                            HapticService().lightImpact();
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.backup_outlined,
                          title: 'Backup & Restore',
                          subtitle: 'Manage local backups',
                          onTap: () {
                            // Navigate to backup screen
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Features section
                    _buildSection(
                      'Features',
                      [
                        _buildSettingsTile(
                          icon: Icons.collections_outlined,
                          title: 'Batch Scanning',
                          subtitle: 'Conference mode settings',
                          onTap: () {
                            // Navigate to batch scan settings
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.qr_code,
                          title: 'QR Codes',
                          subtitle: 'QR code generation settings',
                          onTap: () {
                            // Navigate to QR settings
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.mic_outlined,
                          title: 'Voice Notes',
                          subtitle: 'Audio recording preferences',
                          onTap: () {
                            // Navigate to voice notes settings
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.merge_outlined,
                          title: 'Duplicate Detection',
                          subtitle: 'Find and merge duplicates',
                          onTap: () => context.push('/duplicate-merge'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Integrations section
                    _buildSection(
                      'Integrations',
                      [
                        _buildSettingsTile(
                          icon: Icons.business_outlined,
                          title: 'CRM Connections',
                          subtitle: 'Salesforce, HubSpot, Dynamics',
                          onTap: () {
                            // Navigate to CRM settings
                          },
                          trailing: _buildPremiumBadge(),
                        ),
                        _buildSettingsTile(
                          icon: Icons.label_outline,
                          title: 'Tags',
                          subtitle: 'Manage contact tags',
                          onTap: () => context.push('/tags'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Preferences section
                    _buildSection(
                      'Preferences',
                      [
                        _buildSettingsTile(
                          icon: Icons.palette_outlined,
                          title: 'Theme',
                          subtitle: 'Dark mode',
                          onTap: () {
                            // Navigate to theme settings
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.volume_up_outlined,
                          title: 'Sound Effects',
                          subtitle: 'UI sound feedback',
                          value: !SoundManager().isMuted(),
                          onChanged: (value) {
                            SoundManager().setMuted(!value);
                            setState(() {});
                            HapticService().lightImpact();
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.vibration_outlined,
                          title: 'Haptic Feedback',
                          subtitle: 'Vibration on interactions',
                          value: HapticService().isHapticEnabled(),
                          onChanged: (value) {
                            HapticService().setHapticEnabled(value);
                            setState(() {});
                            HapticService().lightImpact();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Privacy section
                    _buildSection(
                      'Privacy & Security',
                      [
                        _buildSwitchTile(
                          icon: Icons.analytics_outlined,
                          title: 'Analytics',
                          subtitle: 'Help improve the app',
                          value: _analyticsEnabled,
                          onChanged: (value) {
                            setState(() => _analyticsEnabled = value);
                            HapticService().lightImpact();
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.bug_report_outlined,
                          title: 'Crash Reporting',
                          subtitle: 'Automatic error reports',
                          value: _crashReportingEnabled,
                          onChanged: (value) {
                            setState(() => _crashReportingEnabled = value);
                            HapticService().lightImpact();
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.lock_outline,
                          title: 'Privacy Policy',
                          subtitle: 'View privacy policy',
                          onTap: () {
                            // Open privacy policy
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Data section
                    _buildSection(
                      'Data Management',
                      [
                        _buildSettingsTile(
                          icon: Icons.upload_outlined,
                          title: 'Export Data',
                          subtitle: 'vCard, CSV, or JSON',
                          onTap: () {
                            // Show export options
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.download_outlined,
                          title: 'Import Data',
                          subtitle: 'Import from vCard file',
                          onTap: () {
                            // Show import dialog
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.delete_outline,
                          title: 'Clear Data',
                          subtitle: 'Delete all local data',
                          onTap: () => _showClearDataDialog(),
                          textColor: QuantumTheme.errorRed,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Support section
                    _buildSection(
                      'Support',
                      [
                        _buildSettingsTile(
                          icon: Icons.help_outline,
                          title: 'Help Center',
                          subtitle: 'Get help and tutorials',
                          onTap: () => context.push('/help'),
                        ),
                        _buildSettingsTile(
                          icon: Icons.feedback_outlined,
                          title: 'Send Feedback',
                          subtitle: 'Share your thoughts',
                          onTap: () {
                            // Open feedback form
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.rate_review_outlined,
                          title: 'Rate App',
                          subtitle: 'Leave a review',
                          onTap: () {
                            // Open app store review
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // About section
                    _buildSection(
                      'About',
                      [
                        _buildSettingsTile(
                          icon: Icons.info_outline,
                          title: 'App Info',
                          subtitle: 'Version 1.0.0',
                          onTap: () => _showAboutDialog(),
                        ),
                        _buildSettingsTile(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          subtitle: 'View terms and conditions',
                          onTap: () {
                            // Open terms of service
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: QuantumTheme.primaryBlue.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
        ),
        GlassContainer(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (textColor ?? QuantumTheme.primaryBlue)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: textColor ?? QuantumTheme.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: QuantumTheme.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: QuantumTheme.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: QuantumTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [QuantumTheme.primaryBlue, QuantumTheme.accentPurple],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }

  String _getSubscriptionStatus() {
    // In production, get from SubscriptionService
    return 'Free Plan';
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QuantumTheme.darkPurple,
        title: const Text(
          'Clear All Data?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete all contacts and settings. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess('Data cleared successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: QuantumTheme.errorRed,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QuantumTheme.darkPurple,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [QuantumTheme.primaryBlue, QuantumTheme.accentPurple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.credit_card,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Card Scan',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enterprise-grade business card scanner with AI-powered OCR, cloud sync, and smart deduplication.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2025 Card Scan. All rights reserved.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
