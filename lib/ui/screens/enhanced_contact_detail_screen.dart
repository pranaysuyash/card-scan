import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/contact.dart';
import '../../features/analytics/services/analytics_service.dart';
import '../../services/haptic_service.dart';
import '../quantum_theme.dart';
import '../widgets/glass_container.dart';

/// Enhanced contact detail screen with all actions and features
class EnhancedContactDetailScreen extends ConsumerStatefulWidget {
  final Contact contact;

  const EnhancedContactDetailScreen({
    super.key,
    required this.contact,
  });

  @override
  ConsumerState<EnhancedContactDetailScreen> createState() =>
      _EnhancedContactDetailScreenState();
}

class _EnhancedContactDetailScreenState
    extends ConsumerState<EnhancedContactDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRecordingVoiceNote = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Track screen view
    final analytics = AnalyticsService();
    analytics.trackScreenView('contact_detail');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      final analytics = AnalyticsService();
      analytics.trackFeatureUsed('call_contact');
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      final analytics = AnalyticsService();
      analytics.trackFeatureUsed('email_contact');
    }
  }

  Future<void> _openWebsite(String website) async {
    final uri = Uri.parse(website.startsWith('http') ? website : 'https://$website');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareContact() async {
    await Share.share(
      'Contact: ${widget.contact.fullName}\n'
      '${widget.contact.company ?? ""}\n'
      '${widget.contact.emails.isNotEmpty ? widget.contact.emails.first.value : ""}',
      subject: 'Business Card - ${widget.contact.fullName}',
    );
    final analytics = AnalyticsService();
    analytics.trackFeatureUsed('share_contact');
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
              // Header with actions
              _buildHeader(),

              // Contact info card
              _buildContactCard(),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: QuantumTheme.primaryBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.5),
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Activity'),
                    Tab(text: 'Notes'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(),
                    _buildActivityTab(),
                    _buildNotesTab(),
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
          const Spacer(),
          IconButton(
            icon: Icon(
              widget.contact.isFavorite ? Icons.star : Icons.star_outline,
              color: widget.contact.isFavorite
                  ? QuantumTheme.accentPurple
                  : Colors.white,
            ),
            onPressed: () {
              HapticService().mediumImpact();
              // Toggle favorite
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // Navigate to edit screen
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: QuantumTheme.darkPurple,
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareContact();
                  break;
                case 'qr':
                  context.push('/qr-share', extra: widget.contact);
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
                case 'duplicate':
                  context.push('/find-duplicates', extra: widget.contact);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Share', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Show QR Code', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.content_copy, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Find Duplicates', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: QuantumTheme.errorRed),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: QuantumTheme.errorRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      QuantumTheme.primaryBlue,
                      QuantumTheme.accentPurple,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    _getInitials(widget.contact.fullName),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                widget.contact.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              if (widget.contact.title != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.contact.title!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              if (widget.contact.company != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.contact.company!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: QuantumTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // Quick actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (widget.contact.phones.isNotEmpty)
                    _buildQuickAction(
                      icon: Icons.phone,
                      label: 'Call',
                      onTap: () => _makeCall(widget.contact.phones.first.value),
                    ),
                  if (widget.contact.emails.isNotEmpty)
                    _buildQuickAction(
                      icon: Icons.email,
                      label: 'Email',
                      onTap: () => _sendEmail(widget.contact.emails.first.value),
                    ),
                  _buildQuickAction(
                    icon: Icons.message,
                    label: 'Message',
                    onTap: () {
                      // SMS functionality
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.qr_code,
                    label: 'QR',
                    onTap: () => context.push('/qr-share', extra: widget.contact),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService().lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: QuantumTheme.primaryBlue.withOpacity(0.2),
              border: Border.all(
                color: QuantumTheme.primaryBlue.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, color: QuantumTheme.primaryBlue),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.contact.phones.isNotEmpty) ...[
          _buildSectionTitle('Phone Numbers'),
          ...widget.contact.phones.map((phone) => _buildInfoTile(
                icon: Icons.phone,
                title: phone.value,
                subtitle: phone.type,
                onTap: () => _makeCall(phone.value),
              )),
          const SizedBox(height: 16),
        ],
        if (widget.contact.emails.isNotEmpty) ...[
          _buildSectionTitle('Email Addresses'),
          ...widget.contact.emails.map((email) => _buildInfoTile(
                icon: Icons.email,
                title: email.value,
                subtitle: email.type,
                onTap: () => _sendEmail(email.value),
              )),
          const SizedBox(height: 16),
        ],
        if (widget.contact.website != null) ...[
          _buildSectionTitle('Website'),
          _buildInfoTile(
            icon: Icons.language,
            title: widget.contact.website!,
            onTap: () => _openWebsite(widget.contact.website!),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.contact.address != null) ...[
          _buildSectionTitle('Address'),
          _buildInfoTile(
            icon: Icons.location_on,
            title: widget.contact.address!,
          ),
          const SizedBox(height: 16),
        ],
        if (widget.contact.tags.isNotEmpty) ...[
          _buildSectionTitle('Tags'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.contact.tags
                .map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: QuantumTheme.primaryBlue.withOpacity(0.2),
                      labelStyle: const TextStyle(color: Colors.white),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildActivityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Recent Activity'),
        if (widget.contact.activity.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No activity yet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          )
        else
          ...widget.contact.activity.map((activity) => _buildActivityItem(activity)),
      ],
    );
  }

  Widget _buildNotesTab() {
    return Column(
      children: [
        Expanded(
          child: widget.contact.notes.isEmpty
              ? Center(
                  child: Text(
                    'No notes yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.contact.notes.length,
                  itemBuilder: (context, index) {
                    final note = widget.contact.notes[index];
                    return GlassContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(note.timestamp),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Add note button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Show add note dialog
                  },
                  icon: const Icon(Icons.note_add),
                  label: const Text('Add Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuantumTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  context.push('/voice-notes', extra: widget.contact);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuantumTheme.accentPurple,
                  padding: const EdgeInsets.all(16),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.mic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GlassContainer(
      child: ListTile(
        leading: Icon(icon, color: QuantumTheme.primaryBlue),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              )
            : null,
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    return GlassContainer(
      child: ListTile(
        leading: Icon(
          _getActivityIcon(activity.type),
          color: QuantumTheme.primaryBlue,
        ),
        title: Text(
          activity.description,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          _formatDate(activity.timestamp),
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.note:
        return Icons.note;
      case ActivityType.call:
        return Icons.phone;
      case ActivityType.email:
        return Icons.email;
      case ActivityType.meeting:
        return Icons.event;
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QuantumTheme.darkPurple,
        title: const Text('Delete Contact?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${widget.contact.fullName}? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete contact
              Navigator.pop(context);
              context.pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: QuantumTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
