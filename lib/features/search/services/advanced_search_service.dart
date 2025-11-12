import 'package:isar/isar.dart';
import '../../../models/contact.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/either.dart';

/// Advanced search and filtering service
/// Provides faceted search, filters, and sorting options
class AdvancedSearchService {
  final Isar isar;

  AdvancedSearchService(this.isar);

  /// Perform advanced search with multiple filters
  Future<Either<Failure, SearchResults>> search(SearchQuery query) async {
    try {
      var queryBuilder = isar.contacts.filter();

      // Text search (name, company, email, phone)
      if (query.searchText.isNotEmpty) {
        final searchLower = query.searchText.toLowerCase();
        queryBuilder = queryBuilder
            .fullNameContains(searchLower, caseSensitive: false)
            .or()
            .companyContains(searchLower, caseSensitive: false);
      }

      // Company filter
      if (query.companies.isNotEmpty) {
        queryBuilder = queryBuilder.anyOf(
          query.companies,
          (q, company) => q.companyContains(company, caseSensitive: false),
        );
      }

      // Tags filter
      if (query.tags.isNotEmpty) {
        queryBuilder = queryBuilder.anyOf(
          query.tags,
          (q, tag) => q.tagsElementContains(tag, caseSensitive: false),
        );
      }

      // Industry filter
      if (query.industries.isNotEmpty) {
        queryBuilder = queryBuilder.anyOf(
          query.industries,
          (q, industry) => q.industryContains(industry, caseSensitive: false),
        );
      }

      // Favorites filter
      if (query.favoritesOnly) {
        queryBuilder = queryBuilder.isFavoriteEqualTo(true);
      }

      // Date range filter
      if (query.dateFrom != null) {
        queryBuilder = queryBuilder.createdAtGreaterThan(query.dateFrom!);
      }
      if (query.dateTo != null) {
        queryBuilder = queryBuilder.createdAtLessThan(query.dateTo!);
      }

      // Apply sorting
      final results = await _applySorting(queryBuilder, query.sortBy, query.ascending);

      // Get facets for filter UI
      final facets = await _getFacets();

      return Right(SearchResults(
        contacts: results,
        totalCount: results.length,
        facets: facets,
        query: query,
      ));
    } on IsarError catch (e) {
      return Left(StorageFailure(
        message: 'Search failed: ${e.message}',
        code: 'SEARCH_ERROR',
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Unexpected error during search',
        details: e,
      ));
    }
  }

  /// Apply sorting to query
  Future<List<Contact>> _applySorting(
    QueryBuilder<Contact, Contact, QFilterCondition> queryBuilder,
    SortBy sortBy,
    bool ascending,
  ) async {
    switch (sortBy) {
      case SortBy.name:
        return ascending
            ? await queryBuilder.sortByFullName().findAll()
            : await queryBuilder.sortByFullNameDesc().findAll();
      case SortBy.company:
        return ascending
            ? await queryBuilder.sortByCompany().findAll()
            : await queryBuilder.sortByCompanyDesc().findAll();
      case SortBy.dateCreated:
        return ascending
            ? await queryBuilder.sortByCreatedAt().findAll()
            : await queryBuilder.sortByCreatedAtDesc().findAll();
      case SortBy.dateUpdated:
        return ascending
            ? await queryBuilder.sortByUpdatedAt().findAll()
            : await queryBuilder.sortByUpdatedAtDesc().findAll();
      case SortBy.contactScore:
        return ascending
            ? await queryBuilder.sortByContactScore().findAll()
            : await queryBuilder.sortByContactScoreDesc().findAll();
    }
  }

  /// Get facets for filter UI (counts by category)
  Future<SearchFacets> _getFacets() async {
    final allContacts = await isar.contacts.where().findAll();

    // Company facets
    final companyMap = <String, int>{};
    for (final contact in allContacts) {
      if (contact.company != null && contact.company!.isNotEmpty) {
        companyMap[contact.company!] = (companyMap[contact.company!] ?? 0) + 1;
      }
    }

    // Tag facets
    final tagMap = <String, int>{};
    for (final contact in allContacts) {
      for (final tag in contact.tags) {
        tagMap[tag] = (tagMap[tag] ?? 0) + 1;
      }
    }

    // Industry facets
    final industryMap = <String, int>{};
    for (final contact in allContacts) {
      if (contact.industry != null && contact.industry!.isNotEmpty) {
        industryMap[contact.industry!] = (industryMap[contact.industry!] ?? 0) + 1;
      }
    }

    // Sort facets by count
    final sortedCompanies = companyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedTags = tagMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedIndustries = industryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SearchFacets(
      companies: Map.fromEntries(sortedCompanies),
      tags: Map.fromEntries(sortedTags),
      industries: Map.fromEntries(sortedIndustries),
      totalContacts: allContacts.length,
      favoriteCount: allContacts.where((c) => c.isFavorite).length,
    );
  }

  /// Get quick suggestions for autocomplete
  Future<Either<Failure, List<String>>> getSuggestions(String query) async {
    try {
      final suggestions = <String>{};
      final lowerQuery = query.toLowerCase();

      final contacts = await isar.contacts
          .where()
          .limit(50)
          .findAll();

      for (final contact in contacts) {
        // Name suggestions
        if (contact.fullName.toLowerCase().contains(lowerQuery)) {
          suggestions.add(contact.fullName);
        }

        // Company suggestions
        if (contact.company != null &&
            contact.company!.toLowerCase().contains(lowerQuery)) {
          suggestions.add(contact.company!);
        }

        // Tag suggestions
        for (final tag in contact.tags) {
          if (tag.toLowerCase().contains(lowerQuery)) {
            suggestions.add(tag);
          }
        }
      }

      return Right(suggestions.take(10).toList());
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to get suggestions',
        details: e,
      ));
    }
  }
}

/// Search query configuration
class SearchQuery {
  final String searchText;
  final List<String> companies;
  final List<String> tags;
  final List<String> industries;
  final bool favoritesOnly;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final SortBy sortBy;
  final bool ascending;

  const SearchQuery({
    this.searchText = '',
    this.companies = const [],
    this.tags = const [],
    this.industries = const [],
    this.favoritesOnly = false,
    this.dateFrom,
    this.dateTo,
    this.sortBy = SortBy.dateUpdated,
    this.ascending = false,
  });

  SearchQuery copyWith({
    String? searchText,
    List<String>? companies,
    List<String>? tags,
    List<String>? industries,
    bool? favoritesOnly,
    DateTime? dateFrom,
    DateTime? dateTo,
    SortBy? sortBy,
    bool? ascending,
  }) {
    return SearchQuery(
      searchText: searchText ?? this.searchText,
      companies: companies ?? this.companies,
      tags: tags ?? this.tags,
      industries: industries ?? this.industries,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  bool get hasActiveFilters =>
      searchText.isNotEmpty ||
      companies.isNotEmpty ||
      tags.isNotEmpty ||
      industries.isNotEmpty ||
      favoritesOnly ||
      dateFrom != null ||
      dateTo != null;
}

enum SortBy {
  name,
  company,
  dateCreated,
  dateUpdated,
  contactScore,
}

/// Search results with facets
class SearchResults {
  final List<Contact> contacts;
  final int totalCount;
  final SearchFacets facets;
  final SearchQuery query;

  const SearchResults({
    required this.contacts,
    required this.totalCount,
    required this.facets,
    required this.query,
  });
}

/// Facets for filtering
class SearchFacets {
  final Map<String, int> companies;
  final Map<String, int> tags;
  final Map<String, int> industries;
  final int totalContacts;
  final int favoriteCount;

  const SearchFacets({
    required this.companies,
    required this.tags,
    required this.industries,
    required this.totalContacts,
    required this.favoriteCount,
  });
}
