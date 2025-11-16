import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:card_scan/services/analytics_service.dart';
import 'package:card_scan/providers/contact_provider.dart';
import 'package:card_scan/ui/quantum_theme.dart';
import 'package:card_scan/ui/widgets/glass_container.dart';

/// Dashboard screen showing networking statistics and insights
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    final isar = ref.read(isarProvider);
    final analyticsService = AnalyticsService(isar);

    final summary = await analyticsService.getDashboardSummary();

    setState(() {
      _summary = summary;
      _isLoading = false;
    });
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
              QuantumTheme.primaryBlue.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadDashboard,
            color: QuantumTheme.accentPink,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: QuantumTheme.accentPink,
                      ),
                    ),
                  )
                else if (_summary != null)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildNetworkingScore(_summary!),
                        const SizedBox(height: 16),
                        _buildStatsGrid(_summary!),
                        const SizedBox(height: 16),
                        _buildTopCompanies(_summary!),
                        const SizedBox(height: 16),
                        _buildTopTags(_summary!),
                        const SizedBox(height: 16),
                        _buildFollowUpAlert(_summary!),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Dashboard',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadDashboard,
        ),
      ],
    );
  }

  Widget _buildNetworkingScore(DashboardSummary summary) {
    final score = summary.networkingScore;
    final scoreColor = score >= 70
        ? QuantumTheme.successGreen
        : score >= 40
            ? Colors.orange
            : Colors.red;

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Networking Score',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      score >= 70
                          ? 'Excellent!'
                          : score >= 40
                              ? 'Good'
                              : 'Getting Started',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Keep networking to improve your score',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardSummary summary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Contacts',
          summary.totalContacts.toString(),
          Icons.contacts,
          QuantumTheme.primaryBlue,
        ),
        _buildStatCard(
          'This Week',
          summary.contactsThisWeek.toString(),
          Icons.trending_up,
          QuantumTheme.successGreen,
        ),
        _buildStatCard(
          'This Month',
          summary.contactsThisMonth.toString(),
          Icons.calendar_today,
          QuantumTheme.primaryPurple,
        ),
        _buildStatCard(
          'Need Follow-up',
          summary.contactsNeedingFollowUp.toString(),
          Icons.notifications_active,
          QuantumTheme.accentPink,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCompanies(DashboardSummary summary) {
    if (summary.topCompanies.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: QuantumTheme.primaryBlue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Top Companies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...summary.topCompanies.entries.map((entry) {
              final maxCount = summary.topCompanies.values.reduce((a, b) => a > b ? a : b);
              final percentage = entry.value / maxCount;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        QuantumTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTags(DashboardSummary summary) {
    if (summary.topTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label, color: QuantumTheme.accentPink, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Popular Tags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.topTags.entries.map((entry) {
                return Chip(
                  label: Text(
                    '${entry.key} (${entry.value})',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: QuantumTheme.accentPink.withOpacity(0.3),
                  side: BorderSide(
                    color: QuantumTheme.accentPink.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpAlert(DashboardSummary summary) {
    if (summary.contactsNeedingFollowUp == 0) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: QuantumTheme.accentPink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: QuantumTheme.accentPink,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Follow-up Reminder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.contactsNeedingFollowUp} contacts haven\'t been contacted in 30+ days',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
