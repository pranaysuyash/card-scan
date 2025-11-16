import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/contact.dart';
import '../../features/deduplication/services/deduplication_service.dart';
import '../../core/repositories/contact_repository.dart';
import '../../services/haptic_service.dart';
import '../quantum_theme.dart';
import '../widgets/glass_container.dart';

/// Duplicate detection and merge screen
class DuplicateMergeScreen extends ConsumerStatefulWidget {
  final Contact? contact;

  const DuplicateMergeScreen({
    super.key,
    this.contact,
  });

  @override
  ConsumerState<DuplicateMergeScreen> createState() =>
      _DuplicateMergeScreenState();
}

class _DuplicateMergeScreenState extends ConsumerState<DuplicateMergeScreen> {
  final DeduplicationService _deduplicationService = DeduplicationService();
  List<DuplicateMatch>? _duplicates;
  bool _isLoading = true;
  String? _error;
  int _reviewedCount = 0;

  @override
  void initState() {
    super.initState();
    _findDuplicates();
  }

  Future<void> _findDuplicates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(contactRepositoryProvider);
      final result = await repository.getAll();

      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
        (contacts) async {
          if (widget.contact != null) {
            // Find duplicates for specific contact
            final duplicatesResult = await _deduplicationService
                .findPotentialDuplicates(widget.contact!, contacts);

            duplicatesResult.fold(
              (failure) {
                setState(() {
                  _error = failure.message;
                  _isLoading = false;
                });
              },
              (duplicates) {
                setState(() {
                  _duplicates = duplicates;
                  _isLoading = false;
                });
              },
            );
          } else {
            // Find all duplicates in database
            final allDuplicates = <DuplicateMatch>[];
            for (final contact in contacts) {
              final duplicatesResult = await _deduplicationService
                  .findPotentialDuplicates(contact, contacts);

              duplicatesResult.fold(
                (failure) {},
                (duplicates) {
                  allDuplicates.addAll(duplicates);
                },
              );
            }

            // Remove reverse duplicates (A->B and B->A)
            final unique = <String, DuplicateMatch>{};
            for (final match in allDuplicates) {
              final key1 = '${match.contact.id}';
              final key2 = '${widget.contact?.id ?? 0}';
              final combinedKey = [key1, key2]..sort();
              final uniqueKey = combinedKey.join('-');

              if (!unique.containsKey(uniqueKey)) {
                unique[uniqueKey] = match;
              }
            }

            setState(() {
              _duplicates = unique.values.toList();
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to find duplicates: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _mergeContacts(Contact primary, Contact secondary) async {
    try {
      final repository = ref.read(contactRepositoryProvider);
      final mergedResult = await repository.merge(primary, secondary);

      mergedResult.fold(
        (failure) {
          _showError('Failed to merge contacts: ${failure.message}');
        },
        (merged) {
          HapticService().successImpact();
          _showSuccess('Contacts merged successfully');
          setState(() {
            _reviewedCount++;
            _duplicates?.removeWhere(
              (match) =>
                  match.contact.id == secondary.id ||
                  match.contact.id == primary.id,
            );
          });
        },
      );
    } catch (e) {
      _showError('Failed to merge contacts: $e');
    }
  }

  Future<void> _keepBoth(DuplicateMatch match) async {
    HapticService().lightImpact();
    setState(() {
      _reviewedCount++;
      _duplicates?.remove(match);
    });
    _showSuccess('Kept both contacts');
  }

  Future<void> _skipDuplicate(DuplicateMatch match) async {
    HapticService().lightImpact();
    setState(() {
      _duplicates?.remove(match);
    });
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
                child: _isLoading
                    ? _buildLoading()
                    : _error != null
                        ? _buildError()
                        : _duplicates == null || _duplicates!.isEmpty
                            ? _buildNoDuplicates()
                            : _buildDuplicatesList(),
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
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Duplicate Detection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_duplicates != null && _duplicates!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: QuantumTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: QuantumTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${_duplicates!.length} found',
                    style: const TextStyle(
                      color: QuantumTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (_reviewedCount > 0) ...[
            const SizedBox(height: 16),
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: QuantumTheme.successGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_reviewedCount duplicate${_reviewedCount == 1 ? '' : 's'} reviewed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(QuantumTheme.primaryBlue),
          ),
          SizedBox(height: 24),
          Text(
            'Analyzing contacts for duplicates...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: QuantumTheme.errorRed.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Finding Duplicates',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _findDuplicates,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: QuantumTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDuplicates() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.done_all,
            size: 120,
            color: QuantumTheme.successGreen.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Duplicates Found',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your contacts are clean and organized!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicatesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _duplicates!.length,
      itemBuilder: (context, index) {
        final match = _duplicates![index];
        return _buildDuplicateCard(match);
      },
    );
  }

  Widget _buildDuplicateCard(DuplicateMatch match) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Confidence badge
              Row(
                children: [
                  _buildConfidenceBadge(match.confidence),
                  const SizedBox(width: 12),
                  Text(
                    '${match.percentSimilarity}% Match',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Comparison
              if (widget.contact != null)
                _buildComparison(widget.contact!, match.contact)
              else
                _buildSingleContactInfo(match.contact),

              const SizedBox(height: 16),

              // Reasons
              if (match.reasons.isNotEmpty) ...[
                const Text(
                  'Matching fields:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ...match.reasons.map((reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: QuantumTheme.successGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _skipDuplicate(match),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Skip'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _keepBoth(match),
                      icon: const Icon(Icons.content_copy, size: 18),
                      label: const Text('Keep Both'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: QuantumTheme.primaryBlue,
                        side: const BorderSide(
                          color: QuantumTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.contact != null
                          ? () => _mergeContacts(widget.contact!, match.contact)
                          : null,
                      icon: const Icon(Icons.merge, size: 18),
                      label: const Text('Merge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: QuantumTheme.successGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(DuplicateConfidence confidence) {
    final config = _getConfidenceConfig(confidence);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  _ConfidenceConfig _getConfidenceConfig(DuplicateConfidence confidence) {
    switch (confidence) {
      case DuplicateConfidence.veryHigh:
        return _ConfidenceConfig(
          label: 'Very High',
          color: QuantumTheme.errorRed,
          icon: Icons.warning,
        );
      case DuplicateConfidence.high:
        return _ConfidenceConfig(
          label: 'High',
          color: Colors.orange,
          icon: Icons.priority_high,
        );
      case DuplicateConfidence.medium:
        return _ConfidenceConfig(
          label: 'Medium',
          color: Colors.yellow,
          icon: Icons.info_outline,
        );
      case DuplicateConfidence.low:
        return _ConfidenceConfig(
          label: 'Low',
          color: QuantumTheme.primaryBlue,
          icon: Icons.help_outline,
        );
    }
  }

  Widget _buildComparison(Contact primary, Contact secondary) {
    return Column(
      children: [
        // Names
        _buildComparisonRow(
          'Name',
          primary.fullName,
          secondary.fullName,
        ),

        // Company
        if (primary.company != null || secondary.company != null)
          _buildComparisonRow(
            'Company',
            primary.company ?? '-',
            secondary.company ?? '-',
          ),

        // Email
        if (primary.emails.isNotEmpty || secondary.emails.isNotEmpty)
          _buildComparisonRow(
            'Email',
            primary.emails.isNotEmpty ? primary.emails.first.value : '-',
            secondary.emails.isNotEmpty ? secondary.emails.first.value : '-',
          ),

        // Phone
        if (primary.phones.isNotEmpty || secondary.phones.isNotEmpty)
          _buildComparisonRow(
            'Phone',
            primary.phones.isNotEmpty ? primary.phones.first.value : '-',
            secondary.phones.isNotEmpty ? secondary.phones.first.value : '-',
          ),

        // Title
        if (primary.title != null || secondary.title != null)
          _buildComparisonRow(
            'Title',
            primary.title ?? '-',
            secondary.title ?? '-',
          ),
      ],
    );
  }

  Widget _buildComparisonRow(String label, String value1, String value2) {
    final isMatch =
        value1.toLowerCase().trim() == value2.toLowerCase().trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMatch
                        ? QuantumTheme.successGreen.withOpacity(0.1)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMatch
                          ? QuantumTheme.successGreen.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    value1,
                    style: TextStyle(
                      color: isMatch ? QuantumTheme.successGreen : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  isMatch ? Icons.check_circle : Icons.arrow_forward,
                  color: isMatch
                      ? QuantumTheme.successGreen
                      : Colors.white.withOpacity(0.3),
                  size: 20,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMatch
                        ? QuantumTheme.successGreen.withOpacity(0.1)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMatch
                          ? QuantumTheme.successGreen.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    value2,
                    style: TextStyle(
                      color: isMatch ? QuantumTheme.successGreen : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleContactInfo(Contact contact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contact.fullName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (contact.company != null) ...[
          const SizedBox(height: 4),
          Text(
            contact.company!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
        if (contact.emails.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            contact.emails.first.value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

class _ConfidenceConfig {
  final String label;
  final Color color;
  final IconData icon;

  _ConfidenceConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}

// Provider for contact repository
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  throw UnimplementedError('ContactRepository provider not initialized');
});
