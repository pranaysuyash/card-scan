import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/haptic_service.dart';
import '../quantum_theme.dart';
import '../widgets/glass_container.dart';

/// Help center and support screen
class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  int? _expandedIndex;

  final List<HelpTopic> _topics = [
    HelpTopic(
      icon: Icons.credit_card_outlined,
      title: 'Getting Started',
      items: [
        HelpItem(
          question: 'How do I scan a business card?',
          answer:
              'Tap the scan button on the home screen, position the card in the frame, and the app will automatically capture and extract the information.',
        ),
        HelpItem(
          question: 'How accurate is the OCR?',
          answer:
              'Our advanced OCR technology achieves 95% accuracy on most business cards. For best results, ensure good lighting and hold the card steady.',
        ),
        HelpItem(
          question: 'Can I edit scanned information?',
          answer:
              'Yes! Tap any contact to view details, then tap the edit button to make changes to any field.',
        ),
      ],
    ),
    HelpTopic(
      icon: Icons.collections_outlined,
      title: 'Batch Scanning',
      items: [
        HelpItem(
          question: 'How do I scan multiple cards at once?',
          answer:
              'Use the Batch Scan feature from the menu. You can add multiple card images and process them all together.',
        ),
        HelpItem(
          question: 'What is the limit for batch scanning?',
          answer:
              'Pro users can scan up to 100 cards in a single session. Free users are limited to 10 cards per batch.',
        ),
      ],
    ),
    HelpTopic(
      icon: Icons.cloud_outlined,
      title: 'Cloud Sync',
      items: [
        HelpItem(
          question: 'How does cloud sync work?',
          answer:
              'Cloud sync automatically backs up your contacts to Firebase. Your data stays in sync across all your devices.',
        ),
        HelpItem(
          question: 'Is my data secure?',
          answer:
              'Yes! All data is encrypted in transit and at rest. We use industry-standard security practices to protect your information.',
        ),
        HelpItem(
          question: 'How do I enable auto-sync?',
          answer:
              'Go to Settings > Sync & Backup and toggle on "Auto Sync". Your contacts will sync automatically when connected to the internet.',
        ),
      ],
    ),
    HelpTopic(
      icon: Icons.qr_code,
      title: 'QR Codes',
      items: [
        HelpItem(
          question: 'How do I generate a QR code?',
          answer:
              'View any contact and tap the QR code icon. You can share your digital business card via QR code.',
        ),
        HelpItem(
          question: 'Can I scan QR codes?',
          answer:
              'Yes! Use the QR scanner from the menu to scan and import contacts from QR codes.',
        ),
      ],
    ),
    HelpTopic(
      icon: Icons.workspace_premium,
      title: 'Subscription',
      items: [
        HelpItem(
          question: 'What features are included in Pro?',
          answer:
              'Pro includes unlimited contacts, batch processing, cloud sync, QR codes, voice notes, analytics, and no ads.',
        ),
        HelpItem(
          question: 'How do I upgrade to Pro?',
          answer:
              'Tap on Settings > Subscription to view plans and upgrade. You can choose monthly or yearly billing.',
        ),
        HelpItem(
          question: 'Can I cancel my subscription?',
          answer:
              'Yes, you can cancel anytime from your account settings. Your Pro features will remain active until the end of your billing period.',
        ),
      ],
    ),
  ];

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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Help Center',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassContainer(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for help...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: QuantumTheme.primaryBlue,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Topics
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _topics.length,
                  itemBuilder: (context, index) {
                    return _buildTopicCard(_topics[index], index);
                  },
                ),
              ),

              // Contact support button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticService().lightImpact();
                      // Open email client or support form
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Contact Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuantumTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildTopicCard(HelpTopic topic, int index) {
    final isExpanded = _expandedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expandedIndex = isExpanded ? null : index;
                  });
                  HapticService().lightImpact();
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: QuantumTheme.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          topic.icon,
                          color: QuantumTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          topic.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded) ...[
              Divider(height: 1, color: Colors.white.withOpacity(0.1)),
              ...topic.items.map((item) => _buildHelpItem(item)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(HelpItem item) {
    return ExpansionTile(
      title: Text(
        item.question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            item.answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ),
      ],
      iconColor: QuantumTheme.primaryBlue,
      collapsedIconColor: Colors.white.withOpacity(0.5),
    );
  }
}

class HelpTopic {
  final IconData icon;
  final String title;
  final List<HelpItem> items;

  HelpTopic({
    required this.icon,
    required this.title,
    required this.items,
  });
}

class HelpItem {
  final String question;
  final String answer;

  HelpItem({
    required this.question,
    required this.answer,
  });
}
