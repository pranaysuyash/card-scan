import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contact_provider.dart';
import '../../services/vcard_service.dart';
import '../theme_constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _vcardService = VCardService();
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportVCard() async {
    setState(() => _isExporting = true);

    try {
      final contactsAsync = await ref.read(contactsProvider.future);

      if (contactsAsync.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No contacts to export')),
          );
        }
        return;
      }

      await _vcardService.exportContactsToVCard(contactsAsync);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${contactsAsync.length} contacts'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportCSV() async {
    setState(() => _isExporting = true);

    try {
      final contactsAsync = await ref.read(contactsProvider.future);

      if (contactsAsync.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No contacts to export')),
          );
        }
        return;
      }

      await _vcardService.exportContactsToCSV(contactsAsync);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${contactsAsync.length} contacts to CSV'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importVCard() async {
    setState(() => _isImporting = true);

    try {
      final importedContacts = await _vcardService.importContactsFromVCard();

      if (importedContacts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No contacts found in file')),
          );
        }
        return;
      }

      // Save imported contacts
      final storage = ref.read(storageServiceProvider);
      int savedCount = 0;

      for (final contact in importedContacts) {
        try {
          await storage.saveContact(contact);
          savedCount++;
        } catch (e) {
          // Skip duplicates or errors
          debugPrint('Error saving contact: $e');
        }
      }

      // Refresh contacts list
      ref.invalidate(contactsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $savedCount contacts'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Contacts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose export format',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 24),
              _ExportOptionTile(
                icon: Icons.contacts_rounded,
                title: 'vCard (.vcf)',
                subtitle: 'Compatible with iOS, Android, and most apps',
                onTap: () {
                  Navigator.pop(context);
                  _exportVCard();
                },
              ),
              const SizedBox(height: 12),
              _ExportOptionTile(
                icon: Icons.table_chart_rounded,
                title: 'CSV Spreadsheet',
                subtitle: 'For Excel, Google Sheets, etc.',
                onTap: () {
                  Navigator.pop(context);
                  _exportCSV();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: DesignTokens.backgroundGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Export/Import Section
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            _buildAnimatedSettingsTile(
              context,
              index: 0,
              child: _SettingsTile(
                icon: Icons.upload_rounded,
                title: 'Export Contacts',
                subtitle: 'Save as vCard or CSV',
                isLoading: _isExporting,
                onTap: _isExporting ? null : _showExportOptions,
              ),
            ),
            const SizedBox(height: 12),
            _buildAnimatedSettingsTile(
              context,
              index: 1,
              child: _SettingsTile(
                icon: Icons.download_rounded,
                title: 'Import Contacts',
                subtitle: 'Import from vCard file',
                isLoading: _isImporting,
                onTap: _isImporting ? null : _importVCard,
              ),
            ),
            const SizedBox(height: 24),

            // Preferences Section
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            _buildAnimatedSettingsTile(
              context,
              index: 2,
              child: _SettingsTile(
                icon: Icons.palette_rounded,
                title: 'Theme',
                subtitle: 'System default',
                onTap: null,
              ),
            ),
            const SizedBox(height: 24),

            // About Section
            Text(
              'About',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            _buildAnimatedSettingsTile(
              context,
              index: 3,
              child: _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'App Info',
                subtitle: 'Card Scan • Local-first OCR',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Card Scan',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                        'A beautiful local-first business card scanner',
                    applicationIcon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.credit_card_rounded,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSettingsTile(BuildContext context,
      {required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: DesignTokens.radiusExtraLarge,
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: DesignTokens.blurSigma, sigmaY: DesignTokens.blurSigma),
        child: Container(
          decoration: DesignTokens.glassDecoration(context),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onTap,
              borderRadius: DesignTokens.radiusExtraLarge,
              child: Padding(
                padding: DesignTokens.paddingExtraLarge,
                child: Row(
                  children: [
                    Container(
                      padding: DesignTokens.paddingMedium,
                      decoration: BoxDecoration(
                        gradient: DesignTokens.accentGradient(context),
                        borderRadius: DesignTokens.radiusMedium,
                      ),
                      child: Icon(
                        icon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    else if (onTap != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
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

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onPrimary,
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
