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
    {'id': 'All', 'label': 'All Sectors', 'icon': Icons.apps_rounded, 'color': AppTheme.primaryBlue},
    {'id': 'Education', 'label': 'Student & Education', 'icon': Icons.school_rounded, 'color': Colors.blue},
    {'id': 'Agriculture', 'label': 'Farmer & Agriculture', 'icon': Icons.agriculture_rounded, 'color': Colors.green},
    {'id': 'Skill', 'label': 'Job Seeker & Skill', 'icon': Icons.work_rounded, 'color': Colors.amber},
    {'id': 'Entrepreneurship', 'label': 'Business & MSME', 'icon': Icons.store_rounded, 'color': Colors.purple},
    {'id': 'Women', 'label': 'Women & Family', 'icon': Icons.female_rounded, 'color': Colors.pink},
    {'id': 'Senior', 'label': 'Senior Citizen & Pension', 'icon': Icons.elderly_rounded, 'color': Colors.teal},
    {'id': 'General', 'label': 'Housing & Welfare', 'icon': Icons.home_rounded, 'color': Colors.indigo},
  ];

  static const List<String> _kPopularTags = [
    'Scholarship',
    'PM Kisan',
    'MUDRA Loan',
    'Housing',
    'Pension',
    'Skill',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedJurisdiction = '';
      _selectedState = 'Maharashtra';
      _selectedSector = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileType = ref.watch(selectedProfileTypeProvider);
    final repo = ref.watch(schemeRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance_rounded, size: 26, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text(
              'Schemora',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.stars_rounded, color: AppTheme.warningOrange),
            tooltip: 'My Eligible Matches',
            onPressed: () => context.push('/recommendations'),
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy_rounded, color: AppTheme.primaryBlue),
            tooltip: 'AI Assistant',
            onPressed: () => context.push('/assistant'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'Saved Schemes',
            onPressed: () => context.push('/saved-schemes'),
          ),
          IconButton(
            icon: const Icon(Icons.person_pin_rounded, color: AppTheme.primaryNavy),
            tooltip: 'Change Profile Category',
            onPressed: () => context.push('/profile-type'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/assistant'),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.support_agent_rounded),
        label: const Text('Ask AI', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: CustomScrollView(
            slivers: [
              // Top Welcome Banner & Service Quick Links
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Banner Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryNavy, AppTheme.primaryBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryNavy.withAlpha(50),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withAlpha(40),
                                radius: 24,
                                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome back, Citizen!',
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Text(
                                          'Category: ',
                                          style: TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(40),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            profileType.displayName,
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => context.push('/profile-type'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white60),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                label: const Text('Switch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 12),
                          // Service Highlights Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickHeaderAction(
                                context,
                                icon: Icons.stars_rounded,
                                color: AppTheme.warningOrange,
                                label: 'My Matches',
                                onTap: () => context.push('/recommendations'),
                              ),
                              _buildQuickHeaderAction(
                                context,
                                icon: Icons.smart_toy_rounded,
                                color: Colors.cyanAccent,
                                label: 'AI Chat',
                                onTap: () => context.push('/assistant'),
                              ),
                              _buildQuickHeaderAction(
                                context,
                                icon: Icons.bookmark_added_rounded,
                                color: Colors.greenAccent,
                                label: 'Saved Schemes',
                                onTap: () => context.push('/saved-schemes'),
                              ),
                              _buildQuickHeaderAction(
                                context,
                                icon: Icons.shield_rounded,
                                color: Colors.lightBlueAccent,
                                label: 'Doc Masker',
                                onTap: () => context.push('/documents/upload'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search & Filters Box
                    Container(
                      color: Theme.of(context).cardColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Box
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search schemes by keyword, benefit, or provider...',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
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
                              filled: true,
                              fillColor: AppTheme.surfaceLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 8),

                          // Popular Tags Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const Text('Popular:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(width: 6),
                                ..._kPopularTags.map((tag) {
                                  final isSelected = _searchController.text == tag;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: ActionChip(
                                      label: Text(tag, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.primaryNavy)),
                                      backgroundColor: isSelected ? AppTheme.primaryBlue : AppTheme.surfaceLight,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        setState(() {
                                          if (isSelected) {
                                            _searchController.clear();
                                          } else {
                                            _searchController.text = tag;
                                          }
                                        });
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Scope Selector (All / Central / State)
                          Row(
                            children: [
                              const Text('Scope:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('All'),
                                selected: _selectedJurisdiction == '',
                                selectedColor: AppTheme.primaryBlue,
                                labelStyle: TextStyle(
                                  color: _selectedJurisdiction == '' ? Colors.white : AppTheme.primaryNavy,
                                  fontWeight: _selectedJurisdiction == '' ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) => setState(() => _selectedJurisdiction = ''),
                              ),
                              const SizedBox(width: 6),
                              FilterChip(
                                avatar: Icon(
                                  Icons.flag_rounded,
                                  size: 14,
                                  color: _selectedJurisdiction == 'Central' ? Colors.white : AppTheme.primaryNavy,
                                ),
                                label: const Text('Central'),
                                selected: _selectedJurisdiction == 'Central',
                                selectedColor: AppTheme.primaryNavy,
                                labelStyle: TextStyle(
                                  color: _selectedJurisdiction == 'Central' ? Colors.white : AppTheme.primaryNavy,
                                  fontWeight: _selectedJurisdiction == 'Central' ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) => setState(() => _selectedJurisdiction = 'Central'),
                              ),
                              const SizedBox(width: 6),
                              FilterChip(
                                avatar: Icon(
                                  Icons.location_city_rounded,
                                  size: 14,
                                  color: _selectedJurisdiction == 'State' ? Colors.white : Colors.teal.shade800,
                                ),
                                label: const Text('State'),
                                selected: _selectedJurisdiction == 'State',
                                selectedColor: Colors.teal,
                                labelStyle: TextStyle(
                                  color: _selectedJurisdiction == 'State' ? Colors.white : Colors.teal.shade800,
                                  fontWeight: _selectedJurisdiction == 'State' ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) => setState(() => _selectedJurisdiction = 'State'),
                              ),
                            ],
                          ),

                          // State Dropdown
                          if (_selectedJurisdiction == 'State' || _selectedJurisdiction == '') ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.map_rounded, size: 16, color: AppTheme.primaryBlue),
                                const SizedBox(width: 6),
                                const Text('Filter State:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceLight,
                                      border: Border.all(color: Colors.grey.shade300),
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

                          // Sector Header & Horizontal List
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Sectors / Beneficiaries:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              if (_selectedSector != 'All' || _selectedJurisdiction != '' || _searchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: _resetFilters,
                                  child: const Text('Reset All', style: TextStyle(fontSize: 12, color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                                  avatar: Icon(
                                    sector['icon'] as IconData,
                                    size: 16,
                                    color: isSelected ? Colors.white : (sector['color'] as Color),
                                  ),
                                  label: Text(sector['label'] as String),
                                  selected: isSelected,
                                  selectedColor: sector['color'] as Color,
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
                  ],
                ),
              ),

              // Scheme Cards List
              FutureBuilder<List<SchemeModel>>(
                future: repo.getSchemes(
                  query: _searchController.text,
                  jurisdiction: _selectedJurisdiction,
                  state: _selectedJurisdiction == 'State' ? _selectedState : null,
                  category: _selectedSector == 'All' ? null : _selectedSector,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: LoadingStateWidget(message: 'Loading schemes...'),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: ErrorStateWidget(
                        message: 'Failed to load schemes: ${snapshot.error}',
                        onRetry: () => setState(() {}),
                      ),
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
                    return SliverFillRemaining(
                      child: EmptyStateWidget(
                        title: 'No Matching Schemes Found',
                        description: 'Try adjusting your search keywords, jurisdiction, or sector filters.',
                        icon: Icons.search_off_rounded,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final scheme = schemes[index];
                          final isCentral = scheme.jurisdiction.toLowerCase() == 'central';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
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
                                              color: isCentral ? AppTheme.primaryBlue.withAlpha(25) : Colors.teal.withAlpha(25),
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
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),

                                      // Bottom Actions Bar
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Provider: ${scheme.provider}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.checklist_rtl_rounded, size: 18, color: AppTheme.primaryNavy),
                                            tooltip: 'Checklist',
                                            onPressed: () => context.push('/checklist/${scheme.id}'),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () => context.push('/catalog/${scheme.id}'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryBlue,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.auto_fix_high_rounded, size: 15),
                                            label: const Text(
                                              'Auto-Fill & Details',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: schemes.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickHeaderAction(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
