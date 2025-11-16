import 'package:flutter/material.dart';
import 'package:card_scan/models/contact.dart';
import 'package:card_scan/ui/quantum_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Quick actions menu for contact
class QuickActionsMenu extends StatelessWidget {
  final Contact contact;

  const QuickActionsMenu({
    super.key,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuantumTheme.deepSpace,
            QuantumTheme.primaryBlue.withOpacity(0.2),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            contact.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (contact.company != null) ...[
            const SizedBox(height: 4),
            Text(
              contact.company!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Actions
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              if (contact.phone != null)
                _buildActionButton(
                  icon: Icons.phone,
                  label: 'Call',
                  color: QuantumTheme.successGreen,
                  onTap: () => _makeCall(contact.phone!),
                ),
              if (contact.email != null)
                _buildActionButton(
                  icon: Icons.email,
                  label: 'Email',
                  color: QuantumTheme.primaryBlue,
                  onTap: () => _sendEmail(contact.email!),
                ),
              if (contact.phone != null)
                _buildActionButton(
                  icon: Icons.message,
                  label: 'Message',
                  color: QuantumTheme.accentPink,
                  onTap: () => _sendSMS(contact.phone!),
                ),
              if (contact.website != null)
                _buildActionButton(
                  icon: Icons.language,
                  label: 'Website',
                  color: QuantumTheme.primaryPurple,
                  onTap: () => _openWebsite(contact.website!),
                ),
              if (contact.linkedIn != null)
                _buildActionButton(
                  icon: Icons.work,
                  label: 'LinkedIn',
                  color: const Color(0xFF0077B5),
                  onTap: () => _openLinkedIn(contact.linkedIn!),
                ),
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                color: Colors.orange,
                onTap: () => _share(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSMS(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('sms:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWebsite(String website) async {
    var url = website;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openLinkedIn(String linkedIn) async {
    var url = linkedIn;
    if (!url.startsWith('http')) {
      url = 'https://linkedin.com/in/$url';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _share(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }
}
