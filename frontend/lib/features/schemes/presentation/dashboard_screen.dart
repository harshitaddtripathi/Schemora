import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type_provider.dart';
import 'package:schemora_frontend/features/schemes/data/scheme_repository.dart';
import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();

  String _selectedJurisdiction = ''; // '', 'Central', 'State'
  String _selectedState = 'Maharashtra';
  String _selectedSector = 'All'; // 'All', 'Education', 'Agriculture', 'Skill', 'Entrepreneurship', 'Women', 'Senior', 'General'

  static const List<String> _kIndianStates = [
    'Maharashtra',
    'Uttar Pradesh',
    'Gujarat',
    'Karnataka',
    'Tamil Nadu',
    'West Bengal',
    'Delhi',
    'Bihar',
    'Rajasthan',
    'Madhya Pradesh',
    'Kerala',
    'Punjab',
  ];

  static const List<Map<String, dynamic>> _kSectors = [
    {'id': 'All', 'label': 'All Sectors', 'icon': Icons.apps_rounded},
    {'id': 'Education', 'label': 'Student & Education', 'icon': Icons.school_rounded},
    {'id': 'Agriculture', 'label': 'Farmer & Agriculture', 'icon': Icons.agriculture_rounded},
    {'id': 'Skill', 'label': 'Job Seeker & Skill', 'icon': Icons.work_rounded},
    {'id': 'Entrepreneurship', 'label': 'Business & MSME', 'icon': Icons.store_rounded},
    {'id': 'Women', 'label': 'Women & Family', 'icon': Icons.female_rounded},
    {'id': 'Senior', 'label': 'Senior Citizen & Pension', 'icon': Icons.elderly_rounded},
    {'id': 'General', 'label': 'Housing & Welfare', 'icon': Icons.home_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileType = ref.watch(selectedProfileTypeProvider);
    final repo = ref.watch(schemeRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance_rounded, size: 24, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Schemora Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.stars_rounded, color: AppTheme.warningOrange),
            tooltip: 'My Recommendations',
            onPressed: () => context.push('/recommendations'),
          ),
          IconButton(
            icon: const Icon(Icons.person_pin_rounded, color: AppTheme.primaryBlue),
            tooltip: 'Change Profile Type',
            onPressed: () => context.push('/profile-type'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'Saved Schemes',
            onPressed: () => context.push('/saved-schemes'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Welcome Card Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryNavy,
                    AppTheme.primaryBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withAlpha(40),
                    radius: 24,
                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, Citizen!',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active Profile: ${profileType.displayName}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/recommendations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('Matches', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Section
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Keyword Search Box
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search schemes (e.g. scholarship, PM Kisan, MUDRA loan)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 12),

                  // 1. Jurisdiction Options (State-wise vs Central-wise)
                  Row(
                    children: [
                      const Text('Scope:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedJurisdiction == '',
                        onSelected: (_) => setState(() => _selectedJurisdiction = ''),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        avatar: const Icon(Icons.flag_rounded, size: 14),
                        label: const Text('Central Schemes'),
                        selected: _selectedJurisdiction == 'Central',
                        onSelected: (_) => setState(() => _selectedJurisdiction = 'Central'),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        avatar: const Icon(Icons.location_city_rounded, size: 14),
                        label: const Text('State Schemes'),
                        selected: _selectedJurisdiction == 'State',
                        onSelected: (_) => setState(() => _selectedJurisdiction = 'State'),
                      ),
                    ],
                  ),

                  // State Selection Dropdown when State Schemes or All is active
                  if (_selectedJurisdiction == 'State' || _selectedJurisdiction == '') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.map_rounded, size: 16, color: AppTheme.primaryBlue),
                        const SizedBox(width: 6),
                        const Text('State:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isDense: true,
                                value: _selectedState,
                                items: _kIndianStates
                                    .map((st) => DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 13))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedState = val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 2. Sector-wise Options Header & Horizontal Bar
                  const Text('Select Sector / Scheme Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _kSectors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, idx) {
                        final sector = _kSectors[idx];
                        final isSelected = _selectedSector == sector['id'];
                        return FilterChip(
                          avatar: Icon(sector['icon'] as IconData, size: 16, color: isSelected ? Colors.white : AppTheme.primaryNavy),
                          label: Text(sector['label'] as String),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.primaryNavy,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _selectedSector = sector['id'] as String),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scheme Cards List
            Expanded(
              child: FutureBuilder<List<SchemeModel>>(
                future: repo.getSchemes(
                  query: _searchController.text,
                  jurisdiction: _selectedJurisdiction,
                  state: _selectedJurisdiction == 'State' ? _selectedState : null,
                  category: _selectedSector == 'All' ? null : _selectedSector,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingStateWidget(message: 'Loading schemes for your selection...');
                  }
                  if (snapshot.hasError) {
                    return ErrorStateWidget(
                      message: 'Failed to load schemes: ${snapshot.error}',
                      onRetry: () => setState(() {}),
                    );
                  }

                  var schemes = snapshot.data ?? [];

                  // Apply client-side sector filter if backend returned full catalog
                  if (_selectedSector != 'All') {
                    final secLower = _selectedSector.toLowerCase();
                    schemes = schemes.where((s) {
                      final title = s.title.toLowerCase();
                      final desc = s.shortDescription.toLowerCase();
                      final ben = s.benefitSummary.toLowerCase();
                      return title.contains(secLower) || desc.contains(secLower) || ben.contains(secLower);
                    }).toList();
                  }

                  if (schemes.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No Matching Schemes Found',
                      description: 'Try adjusting your search keywords, jurisdiction, or sector filters.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: schemes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final scheme = schemes[index];
                      final isCentral = scheme.jurisdiction.toLowerCase() == 'central';

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push('/catalog/${scheme.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Badges Row
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCentral
                                            ? AppTheme.primaryBlue.withAlpha(25)
                                            : Colors.teal.withAlpha(25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isCentral ? Icons.flag_rounded : Icons.location_city_rounded,
                                            size: 13,
                                            color: isCentral ? AppTheme.primaryNavy : Colors.teal.shade800,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isCentral ? 'Central Scheme' : 'State Scheme (${scheme.state ?? _selectedState})',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isCentral ? AppTheme.primaryNavy : Colors.teal.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warningOrange.withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        scheme.benefitType,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.warningOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Title
                                Text(
                                  scheme.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Short Description
                                Text(
                                  scheme.shortDescription,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),

                                // Benefit Highlight
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.card_giftcard_rounded, size: 18, color: AppTheme.primaryBlue),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          scheme.benefitSummary,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Bottom CTA Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Provider: ${scheme.provider}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => context.push('/catalog/${scheme.id}'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primaryBlue,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      ),
                                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                                      label: const Text(
                                        'Auto-Fill & Details',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
