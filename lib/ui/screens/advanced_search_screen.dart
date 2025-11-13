import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/search/services/advanced_search_service.dart';
import '../../models/contact.dart';
import '../quantum_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/contact_tile.dart';
import '../widgets/empty_states.dart';

/// Advanced search screen with filters and facets
class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchQuery _searchQuery = const SearchQuery();
  SearchResults? _results;
  bool _isLoading = false;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    // Would use the actual service here
    // For now, simulating
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      // _results would be populated from service
    });
  }

  void _toggleFilter(String filterType, String value) {
    setState(() {
      switch (filterType) {
        case 'company':
          final companies = List<String>.from(_searchQuery.companies);
          if (companies.contains(value)) {
            companies.remove(value);
          } else {
            companies.add(value);
          }
          _searchQuery = _searchQuery.copyWith(companies: companies);
          break;
        case 'tag':
          final tags = List<String>.from(_searchQuery.tags);
          if (tags.contains(value)) {
            tags.remove(value);
          } else {
            tags.add(value);
          }
          _searchQuery = _searchQuery.copyWith(tags: tags);
          break;
        case 'industry':
          final industries = List<String>.from(_searchQuery.industries);
          if (industries.contains(value)) {
            industries.remove(value);
          } else {
            industries.add(value);
          }
          _searchQuery = _searchQuery.copyWith(industries: industries);
          break;
      }
    });
    _performSearch();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = SearchQuery(searchText: _searchController.text);
    });
    _performSearch();
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
              // Header with search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search contacts...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white54,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) {
                                _searchQuery = _searchQuery.copyWith(searchText: value);
                                _performSearch();
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _showFilters ? Icons.filter_list_off : Icons.filter_list,
                            color: _showFilters ? QuantumTheme.primaryBlue : Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                        ),
                      ],
                    ),

                    // Active filters chips
                    if (_searchQuery.hasActiveFilters)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._searchQuery.companies.map((company) => _buildFilterChip(
                                  label: company,
                                  onRemove: () => _toggleFilter('company', company),
                                )),
                            ..._searchQuery.tags.map((tag) => _buildFilterChip(
                                  label: tag,
                                  onRemove: () => _toggleFilter('tag', tag),
                                )),
                            ..._searchQuery.industries.map((industry) => _buildFilterChip(
                                  label: industry,
                                  onRemove: () => _toggleFilter('industry', industry),
                                )),
                            if (_searchQuery.favoritesOnly)
                              _buildFilterChip(
                                label: 'Favorites',
                                onRemove: () {
                                  setState(() {
                                    _searchQuery = _searchQuery.copyWith(
                                      favoritesOnly: false,
                                    );
                                  });
                                  _performSearch();
                                },
                              ),
                            TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear All'),
                              style: TextButton.styleFrom(
                                foregroundColor: QuantumTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Filters panel
              if (_showFilters)
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: _buildFiltersPanel(),
                ),

              // Results count
              if (_results != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${_results!.totalCount} contacts found',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      DropdownButton<SortBy>(
                        value: _searchQuery.sortBy,
                        dropdownColor: QuantumTheme.darkPurple,
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        onChanged: (sortBy) {
                          if (sortBy != null) {
                            setState(() {
                              _searchQuery = _searchQuery.copyWith(sortBy: sortBy);
                            });
                            _performSearch();
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: SortBy.name,
                            child: Text('Sort by Name'),
                          ),
                          DropdownMenuItem(
                            value: SortBy.company,
                            child: Text('Sort by Company'),
                          ),
                          DropdownMenuItem(
                            value: SortBy.dateCreated,
                            child: Text('Sort by Created'),
                          ),
                          DropdownMenuItem(
                            value: SortBy.dateUpdated,
                            child: Text('Sort by Updated'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Results list
              Expanded(
                child: _isLoading
                    ? const LoadingSkeleton()
                    : _results == null || _results!.contacts.isEmpty
                        ? EmptyStates.noSearchResults()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results!.contacts.length,
                            itemBuilder: (context, index) {
                              final contact = _results!.contacts[index];
                              return ContactTile(contact: contact);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersPanel() {
    // Mock facets data
    final facets = SearchFacets(
      companies: {'Google': 5, 'Apple': 3, 'Microsoft': 2},
      tags: {'Conference': 8, 'Client': 5, 'Partner': 3},
      industries: {'Technology': 10, 'Finance': 4, 'Healthcare': 2},
      totalContacts: 100,
      favoriteCount: 15,
    );

    return GlassContainer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Favorites toggle
          CheckboxListTile(
            value: _searchQuery.favoritesOnly,
            onChanged: (value) {
              setState(() {
                _searchQuery = _searchQuery.copyWith(
                  favoritesOnly: value ?? false,
                );
              });
              _performSearch();
            },
            title: const Text(
              'Favorites Only',
              style: TextStyle(color: Colors.white),
            ),
            activeColor: QuantumTheme.primaryBlue,
            checkColor: Colors.white,
          ),

          const Divider(color: Colors.white24),

          // Company filters
          ExpansionTile(
            title: const Text(
              'Company',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            children: facets.companies.entries.map((entry) {
              final isSelected = _searchQuery.companies.contains(entry.key);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => _toggleFilter('company', entry.key),
                title: Text(
                  entry.key,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${entry.value} contacts',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
                activeColor: QuantumTheme.primaryBlue,
              );
            }).toList(),
          ),

          // Tag filters
          ExpansionTile(
            title: const Text(
              'Tags',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            children: facets.tags.entries.map((entry) {
              final isSelected = _searchQuery.tags.contains(entry.key);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => _toggleFilter('tag', entry.key),
                title: Text(
                  entry.key,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${entry.value} contacts',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
                activeColor: QuantumTheme.primaryBlue,
              );
            }).toList(),
          ),

          // Industry filters
          ExpansionTile(
            title: const Text(
              'Industry',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            children: facets.industries.entries.map((entry) {
              final isSelected = _searchQuery.industries.contains(entry.key);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => _toggleFilter('industry', entry.key),
                title: Text(
                  entry.key,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${entry.value} contacts',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
                activeColor: QuantumTheme.primaryBlue,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        labelStyle: const TextStyle(color: Colors.white),
        deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
        onDeleted: onRemove,
        backgroundColor: QuantumTheme.primaryBlue.withOpacity(0.3),
        deleteIconColor: Colors.white,
      ),
    );
  }
}
