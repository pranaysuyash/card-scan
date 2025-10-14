import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../providers/contact_provider.dart';
import '../../models/contact.dart';
import '../../services/vcard_service.dart';
import 'package:intl/intl.dart';
import '../theme_constants.dart';

class ContactDetailScreen extends ConsumerWidget {
  final int contactId;

  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactByIdProvider(contactId));

    return contactAsync.when(
      data: (contact) {
        if (contact == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Contact not found')),
          );
        }

        return _ContactDetailView(contact: contact);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _ContactDetailView extends ConsumerWidget {
  final Contact contact;

  const _ContactDetailView({required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(contact.fullName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delete_rounded,
                    color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () => _deleteContact(context, ref),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and gradient
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Hero(
                tag: 'contact-card-${contact.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.borderRadiusExtraLarge + 8,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.95),
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.15),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 36,
                      ),
                      child: Column(
                        children: [
                          Hero(
                            tag: 'contact-avatar-${contact.id}',
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  contact.fullName.isNotEmpty
                                      ? contact.fullName[0].toUpperCase()
                                      : '?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            contact.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          if (contact.title != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              contact.title!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (contact.company != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              contact.company!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withOpacity(0.7),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Quick Actions with animation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (contact.emails.isNotEmpty)
                    _buildAnimatedQuickAction(
                      context,
                      index: 0,
                      child: _QuickActionButton(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        onPressed: () =>
                            _launchEmail(contact.emails.first.value),
                      ),
                    ),
                  if (contact.phones.isNotEmpty)
                    _buildAnimatedQuickAction(
                      context,
                      index: 1,
                      child: _QuickActionButton(
                        icon: Icons.phone_rounded,
                        label: 'Call',
                        onPressed: () =>
                            _launchPhone(contact.phones.first.value),
                      ),
                    ),
                  _buildAnimatedQuickAction(
                    context,
                    index: 2,
                    child: _QuickActionButton(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onPressed: () => _shareContact(context, contact),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Contact Info
            _buildSection(
              context,
              'Contact Information',
              [
                if (contact.emails.isNotEmpty)
                  for (final email in contact.emails)
                    _InfoTile(
                      icon: Icons.email,
                      title: email.value,
                      subtitle: email.type,
                      onTap: () => _launchEmail(email.value),
                    ),
                if (contact.phones.isNotEmpty)
                  for (final phone in contact.phones)
                    _InfoTile(
                      icon: Icons.phone,
                      title: phone.value,
                      subtitle: phone.type,
                      onTap: () => _launchPhone(phone.value),
                    ),
                if (contact.website != null)
                  _InfoTile(
                    icon: Icons.language,
                    title: contact.website!,
                    onTap: () => _launchUrl(contact.website!),
                  ),
                if (contact.address != null)
                  _InfoTile(
                    icon: Icons.location_on,
                    title: contact.address!,
                  ),
              ],
            ),

            // Notes
            if (contact.notes.isNotEmpty) ...[
              const Divider(),
              _buildSection(
                context,
                'Notes',
                contact.notes
                    .map((note) => ListTile(
                          leading: Icon(
                            note.audioPath != null ? Icons.mic : Icons.note,
                          ),
                          title: Text(
                            note.text ?? note.transcript ?? 'Voice note',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy').format(note.createdAt),
                          ),
                        ))
                    .toList(),
              ),
            ],

            // Activity
            const Divider(),
            _buildSection(
              context,
              'Activity',
              [
                _InfoTile(
                  icon: Icons.calendar_today,
                  title: 'Created',
                  subtitle: DateFormat('MMM d, yyyy, h:mm a')
                      .format(contact.createdAt),
                ),
                _InfoTile(
                  icon: Icons.update,
                  title: 'Last Updated',
                  subtitle: DateFormat('MMM d, yyyy, h:mm a')
                      .format(contact.updatedAt),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedQuickAction(BuildContext context,
      {required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
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

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareContact(BuildContext context, Contact contact) async {
    try {
      final vcardService = VCardService();
      await vcardService.exportSingleContact(contact);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing contact: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteContact(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storage = ref.read(storageServiceProvider);
      await storage.deleteContact(contact.id);
      ref.invalidate(contactsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted')),
        );
        context.go('/');
      }
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                      size: 20, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
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
    );
  }
}
