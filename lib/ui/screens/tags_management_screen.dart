import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/haptic_service.dart';
import '../quantum_theme.dart';
import '../widgets/glass_container.dart';

/// Tags management screen for organizing contacts
class TagsManagementScreen extends ConsumerStatefulWidget {
  const TagsManagementScreen({super.key});

  @override
  ConsumerState<TagsManagementScreen> createState() =>
      _TagsManagementScreenState();
}

class _TagsManagementScreenState extends ConsumerState<TagsManagementScreen> {
  final TextEditingController _tagController = TextEditingController();
  final List<TagItem> _tags = [
    TagItem(name: 'Client', count: 45, color: QuantumTheme.primaryBlue),
    TagItem(name: 'Prospect', count: 28, color: QuantumTheme.accentPurple),
    TagItem(name: 'Partner', count: 12, color: QuantumTheme.successGreen),
    TagItem(name: 'Vendor', count: 8, color: QuantumTheme.secondaryPink),
    TagItem(name: 'Conference', count: 34, color: Colors.orange),
    TagItem(name: 'VIP', count: 15, color: Colors.amber),
  ];

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    if (_tagController.text.trim().isEmpty) return;

    setState(() {
      _tags.add(TagItem(
        name: _tagController.text.trim(),
        count: 0,
        color: _getRandomColor(),
      ));
      _tagController.clear();
    });

    HapticService().successImpact();
    Navigator.pop(context);
  }

  void _deleteTag(TagItem tag) {
    setState(() {
      _tags.remove(tag);
    });
    HapticService().lightImpact();
    _showSuccess('Tag deleted');
  }

  Color _getRandomColor() {
    final colors = [
      QuantumTheme.primaryBlue,
      QuantumTheme.accentPurple,
      QuantumTheme.secondaryPink,
      QuantumTheme.successGreen,
      Colors.orange,
      Colors.amber,
    ];
    return colors[DateTime.now().millisecond % colors.length];
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QuantumTheme.darkPurple,
        title: const Text(
          'Create Tag',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _tagController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tag name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _tagController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addTag,
            style: ElevatedButton.styleFrom(
              backgroundColor: QuantumTheme.primaryBlue,
            ),
            child: const Text('Create'),
          ),
        ],
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
                      'Tags',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _showAddTagDialog,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _tags.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tags.length,
                        itemBuilder: (context, index) {
                          return _buildTagCard(_tags[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTagDialog,
        backgroundColor: QuantumTheme.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('New Tag'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.label_outline,
            size: 120,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No tags yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create tags to organize your contacts',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagCard(TagItem tag) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to contacts with this tag
              HapticService().lightImpact();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tag.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.label,
                      color: tag.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tag.count} contact${tag.count == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: QuantumTheme.errorRed.withOpacity(0.7),
                    ),
                    onPressed: () => _deleteTag(tag),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TagItem {
  final String name;
  final int count;
  final Color color;

  TagItem({
    required this.name,
    required this.count,
    required this.color,
  });
}
