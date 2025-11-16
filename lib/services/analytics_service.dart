import 'package:isar/isar.dart';
import 'package:card_scan/models/contact.dart';
import 'package:card_scan/models/contact_interaction.dart';
import 'logger_service.dart';

/// Service for computing contact statistics and analytics
class AnalyticsService {
  final Isar _isar;
  final LoggerService _logger = LoggerService();

  AnalyticsService(this._isar);

  /// Get total number of contacts
  Future<int> getTotalContacts() async {
    try {
      return await _isar.contacts.count();
    } catch (e) {
      _logger.error('Error getting total contacts', error: e);
      return 0;
    }
  }

  /// Get contacts added this week
  Future<int> getContactsAddedThisWeek() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      return await _isar.contacts
          .filter()
          .createdAtGreaterThan(startDate)
          .count();
    } catch (e) {
      _logger.error('Error getting weekly contacts', error: e);
      return 0;
    }
  }

  /// Get contacts added this month
  Future<int> getContactsAddedThisMonth() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      return await _isar.contacts
          .filter()
          .createdAtGreaterThan(startOfMonth)
          .count();
    } catch (e) {
      _logger.error('Error getting monthly contacts', error: e);
      return 0;
    }
  }

  /// Get top companies by contact count
  Future<Map<String, int>> getTopCompaniesByCount({int limit = 5}) async {
    try {
      final contacts = await _isar.contacts.where().findAll();
      final companyCount = <String, int>{};

      for (final contact in contacts) {
        if (contact.company != null && contact.company!.isNotEmpty) {
          companyCount[contact.company!] = (companyCount[contact.company!] ?? 0) + 1;
        }
      }

      final sortedEntries = companyCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedEntries.take(limit));
    } catch (e) {
      _logger.error('Error getting top companies', error: e);
      return {};
    }
  }

  /// Get top tags by usage
  Future<Map<String, int>> getTopTagsByUsage({int limit = 10}) async {
    try {
      final contacts = await _isar.contacts.where().findAll();
      final tagCount = <String, int>{};

      for (final contact in contacts) {
        for (final tag in contact.tags) {
          tagCount[tag] = (tagCount[tag] ?? 0) + 1;
        }
      }

      final sortedEntries = tagCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedEntries.take(limit));
    } catch (e) {
      _logger.error('Error getting top tags', error: e);
      return {};
    }
  }

  /// Get contacts by month for chart
  Future<Map<String, int>> getContactsByMonth({int months = 12}) async {
    try {
      final now = DateTime.now();
      final monthCounts = <String, int>{};

      for (int i = months - 1; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';

        final nextMonth = DateTime(month.year, month.month + 1, 1);

        final count = await _isar.contacts
            .filter()
            .createdAtBetween(month, nextMonth)
            .count();

        monthCounts[monthKey] = count;
      }

      return monthCounts;
    } catch (e) {
      _logger.error('Error getting contacts by month', error: e);
      return {};
    }
  }

  /// Get recent contacts
  Future<List<Contact>> getRecentContacts({int limit = 10}) async {
    try {
      return await _isar.contacts
          .where()
          .sortByCreatedAtDesc()
          .limit(limit)
          .findAll();
    } catch (e) {
      _logger.error('Error getting recent contacts', error: e);
      return [];
    }
  }

  /// Get contacts without interactions in X days
  Future<List<Contact>> getContactsNeedingFollowUp({int days = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final allContacts = await _isar.contacts.where().findAll();
      final needFollowUp = <Contact>[];

      for (final contact in allContacts) {
        // Check if contact has recent interactions
        final interactionCount = await _isar.contactInteractions
            .filter()
            .contactIdEqualTo(contact.id)
            .timestampGreaterThan(cutoffDate)
            .count();

        if (interactionCount == 0) {
          needFollowUp.add(contact);
        }
      }

      return needFollowUp;
    } catch (e) {
      _logger.error('Error getting contacts needing follow up', error: e);
      return [];
    }
  }

  /// Get interaction statistics
  Future<Map<String, dynamic>> getInteractionStats() async {
    try {
      final totalInteractions = await _isar.contactInteractions.count();

      final thisWeek = DateTime.now().subtract(const Duration(days: 7));
      final interactionsThisWeek = await _isar.contactInteractions
          .filter()
          .timestampGreaterThan(thisWeek)
          .count();

      final byType = <InteractionType, int>{};
      for (final type in InteractionType.values) {
        final count = await _isar.contactInteractions
            .filter()
            .typeEqualTo(type)
            .count();
        if (count > 0) {
          byType[type] = count;
        }
      }

      return {
        'total': totalInteractions,
        'thisWeek': interactionsThisWeek,
        'byType': byType,
      };
    } catch (e) {
      _logger.error('Error getting interaction stats', error: e);
      return {
        'total': 0,
        'thisWeek': 0,
        'byType': <InteractionType, int>{},
      };
    }
  }

  /// Get networking score (0-100)
  Future<int> getNetworkingScore() async {
    try {
      final totalContacts = await getTotalContacts();
      final weeklyContacts = await getContactsAddedThisWeek();
      final totalInteractions = (await getInteractionStats())['total'] as int;

      // Simple scoring algorithm
      int score = 0;

      // Contact count (max 40 points)
      score += (totalContacts / 10).clamp(0, 40).toInt();

      // Recent activity (max 30 points)
      score += (weeklyContacts * 5).clamp(0, 30).toInt();

      // Interaction count (max 30 points)
      score += (totalInteractions / 5).clamp(0, 30).toInt();

      return score.clamp(0, 100);
    } catch (e) {
      _logger.error('Error calculating networking score', error: e);
      return 0;
    }
  }

  /// Get dashboard summary
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final total = await getTotalContacts();
      final thisWeek = await getContactsAddedThisWeek();
      final thisMonth = await getContactsAddedThisMonth();
      final topCompanies = await getTopCompaniesByCount(limit: 3);
      final topTags = await getTopTagsByUsage(limit: 5);
      final networkingScore = await getNetworkingScore();
      final needFollowUp = await getContactsNeedingFollowUp(days: 30);

      return DashboardSummary(
        totalContacts: total,
        contactsThisWeek: thisWeek,
        contactsThisMonth: thisMonth,
        topCompanies: topCompanies,
        topTags: topTags,
        networkingScore: networkingScore,
        contactsNeedingFollowUp: needFollowUp.length,
      );
    } catch (e) {
      _logger.error('Error getting dashboard summary', error: e);
      return DashboardSummary.empty();
    }
  }
}

/// Dashboard summary data class
class DashboardSummary {
  final int totalContacts;
  final int contactsThisWeek;
  final int contactsThisMonth;
  final Map<String, int> topCompanies;
  final Map<String, int> topTags;
  final int networkingScore;
  final int contactsNeedingFollowUp;

  DashboardSummary({
    required this.totalContacts,
    required this.contactsThisWeek,
    required this.contactsThisMonth,
    required this.topCompanies,
    required this.topTags,
    required this.networkingScore,
    required this.contactsNeedingFollowUp,
  });

  factory DashboardSummary.empty() {
    return DashboardSummary(
      totalContacts: 0,
      contactsThisWeek: 0,
      contactsThisMonth: 0,
      topCompanies: {},
      topTags: {},
      networkingScore: 0,
      contactsNeedingFollowUp: 0,
    );
  }
}
