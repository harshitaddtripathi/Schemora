import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/core/widgets/scheme_image_helper.dart';
import 'package:schemora_frontend/features/auth/data/auth_repository.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type_provider.dart';
import 'package:schemora_frontend/features/schemes/data/scheme_repository.dart';
import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';

// ── Main shell with bottom navigation ─────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.list_alt_rounded, label: 'Schemes'),
    _NavItem(icon: Icons.smart_toy_rounded, label: 'AI Chat'),
    _NavItem(icon: Icons.bookmark_rounded, label: 'Saved'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  void _navigateTo(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(onNavigate: _navigateTo),
          _SchemesTab(),
          _AiChatTab(),
          _SavedTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isActive = _currentIndex == index;
              return _NavButton(item: item, isActive: isActive, onTap: () => setState(() => _currentIndex = index));
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _NavButton({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue.withAlpha(15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22, color: isActive ? AppTheme.primaryBlue : const Color(0xFF94A3B8)),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primaryBlue : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// HOME TAB
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _HomeTab extends ConsumerStatefulWidget {
  final void Function(int) onNavigate;
  const _HomeTab({required this.onNavigate});

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final _searchController = TextEditingController();
  String _selectedSector = 'All';
  String _selectedJurisdiction = '';
  String _selectedState = 'Maharashtra';
  final Set<String> _savedSchemeIds = {};

  static const List<Map<String, dynamic>> _kSectors = [
    {'id': 'All',             'label': 'All',         'icon': Icons.apps_rounded,        'color': AppTheme.primaryBlue},
    {'id': 'Education',       'label': 'Education',   'icon': Icons.school_rounded,      'color': Color(0xFF2563EB)},
    {'id': 'Agriculture',     'label': 'Agriculture', 'icon': Icons.agriculture_rounded, 'color': Color(0xFF059669)},
    {'id': 'Entrepreneurship','label': 'Business',    'icon': Icons.store_rounded,       'color': Color(0xFF7C3AED)},
    {'id': 'Women',           'label': 'Women',       'icon': Icons.female_rounded,      'color': Color(0xFFDB2777)},
    {'id': 'Skill',           'label': 'Skills',      'icon': Icons.work_rounded,        'color': Color(0xFFD97706)},
    {'id': 'Senior',          'label': 'Senior',      'icon': Icons.elderly_rounded,     'color': Color(0xFF0D9488)},
    {'id': 'General',         'label': 'Housing',     'icon': Icons.home_rounded,        'color': Color(0xFF4F46E5)},
  ];

  static const List<String> _kIndianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
    'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
    'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
    'West Bengal', 'Andaman and Nicobar Islands', 'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu', 'Delhi',
    'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
  ];

  static const List<String> _kPopularTags = [
    'Scholarship', 'PM Kisan', 'MUDRA Loan', 'Housing Grant', 'Pension', 'Skill Training',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilter =>
      _selectedSector != 'All' || _selectedJurisdiction != '' || _searchController.text.isNotEmpty;

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedJurisdiction = '';
      _selectedState = 'Maharashtra';
      _selectedSector = 'All';
    });
  }

  void _toggleSaveScheme(String schemeId) {
    setState(() {
      if (_savedSchemeIds.contains(schemeId)) {
        _savedSchemeIds.remove(schemeId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from bookmarks'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating));
      } else {
        _savedSchemeIds.add(schemeId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to bookmarks!'), duration: Duration(seconds: 2), backgroundColor: AppTheme.successGreen, behavior: SnackBarBehavior.floating));
      }
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        selectedJurisdiction: _selectedJurisdiction,
        selectedState: _selectedState,
        selectedTag: _searchController.text,
        kIndianStates: _kIndianStates,
        kPopularTags: _kPopularTags,
        onApply: (jurisdiction, state, tag) {
          setState(() {
            _selectedJurisdiction = jurisdiction;
            _selectedState = state;
            if (tag.isNotEmpty) _searchController.text = tag;
          });
        },
        onReset: _resetFilters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileType = ref.watch(selectedProfileTypeProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(profileType),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: AppTheme.primaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildSectorPills()),
            SliverToBoxAdapter(child: _buildSectionHeader()),
            ..._buildSchemeList(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(dynamic profileType) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.account_balance_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Schemora', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A), letterSpacing: -0.3)),
              Text(profileType.displayName, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.tune_rounded, color: _hasActiveFilter ? AppTheme.primaryBlue : const Color(0xFF475569)),
              tooltip: 'Filter',
              onPressed: _openFilterSheet,
            ),
            if (_hasActiveFilter)
              Positioned(
                top: 10, right: 10,
                child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.warningOrange, shape: BoxShape.circle)),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF475569)),
          tooltip: 'AI Recommendations',
          onPressed: () => context.push('/recommendations'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Search schemes, benefits...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)), onPressed: () => setState(() => _searchController.clear()))
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSectorPills() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 16),
          itemCount: _kSectors.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, idx) {
            final sector = _kSectors[idx];
            final isSelected = _selectedSector == sector['id'];
            final color = sector['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _selectedSector = sector['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0)),
                  boxShadow: isSelected ? [BoxShadow(color: color.withAlpha(50), blurRadius: 6, offset: const Offset(0, 2))] : [],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(sector['icon'] as IconData, size: 13, color: isSelected ? Colors.white : color),
                  const SizedBox(width: 5),
                  Text(sector['label'] as String, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF374151))),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_selectedSector == 'All' ? 'All Schemes' : '$_selectedSector Schemes',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          if (_hasActiveFilter)
            GestureDetector(
              onTap: _resetFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.errorRed.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.close_rounded, size: 12, color: AppTheme.errorRed),
                  SizedBox(width: 3),
                  Text('Reset', style: TextStyle(fontSize: 11, color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
                ]),
              ),
            )
          else
            Text('Tap to view details', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  List<Widget> _buildSchemeList() {
    return [
      ...ref.watch(allSchemesProvider).when(
        loading: () => const [SliverFillRemaining(child: LoadingStateWidget(message: 'Loading schemes...'))],
        error: (err, _) => [SliverFillRemaining(child: ErrorStateWidget(message: 'Failed to load schemes: $err', onRetry: () => ref.invalidate(allSchemesProvider)))],
        data: (allSchemes) {
          var schemes = List<SchemeModel>.from(allSchemes);
          if (_selectedJurisdiction.isNotEmpty) {
            schemes = schemes.where((s) => s.jurisdiction.toLowerCase() == _selectedJurisdiction.toLowerCase()).toList();
          }
          if (_selectedJurisdiction == 'State') {
            schemes = schemes.where((s) => s.state == null || s.state!.toLowerCase() == _selectedState.toLowerCase()).toList();
          }
          if (_selectedSector != 'All') {
            final q = _selectedSector.toLowerCase();
            schemes = schemes.where((s) => s.title.toLowerCase().contains(q) || s.shortDescription.toLowerCase().contains(q) || s.benefitSummary.toLowerCase().contains(q)).toList();
          }
          if (_searchController.text.isNotEmpty) {
            final q = _searchController.text.toLowerCase();
            schemes = schemes.where((s) => s.title.toLowerCase().contains(q) || s.shortDescription.toLowerCase().contains(q) || s.benefitSummary.toLowerCase().contains(q) || s.provider.toLowerCase().contains(q)).toList();
          }
          if (schemes.isEmpty) {
            return [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade400),
                      const SizedBox(height: 14),
                      const Text('No schemes found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                      const SizedBox(height: 6),
                      Text('Try adjusting the filters or search term.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      const SizedBox(height: 18),
                      TextButton.icon(onPressed: _resetFilters, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Reset Filters')),
                    ]),
                  ),
                ),
              ),
            ];
          }
          return [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _SchemeCard(
                    scheme: schemes[index],
                    isSaved: _savedSchemeIds.contains(schemes[index].id),
                    selectedSector: _selectedSector,
                    selectedState: _selectedState,
                    onSave: () => _toggleSaveScheme(schemes[index].id),
                    onTap: () => context.push('/catalog/${schemes[index].id}'),
                    onChecklist: () => context.push('/checklist/${schemes[index].id}'),
                  ),
                  childCount: schemes.length,
                ),
              ),
            ),
          ];
        },
      ),
    ];
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// FILTER BOTTOM SHEET
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _FilterSheet extends StatefulWidget {
  final String selectedJurisdiction;
  final String selectedState;
  final String selectedTag;
  final List<String> kIndianStates;
  final List<String> kPopularTags;
  final void Function(String, String, String) onApply;
  final VoidCallback onReset;

  const _FilterSheet({
    required this.selectedJurisdiction,
    required this.selectedState,
    required this.selectedTag,
    required this.kIndianStates,
    required this.kPopularTags,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _jurisdiction;
  late String _state;
  late String _tag;

  @override
  void initState() {
    super.initState();
    _jurisdiction = widget.selectedJurisdiction;
    _state = widget.selectedState;
    _tag = widget.selectedTag;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 18),
          Row(children: [
            const Icon(Icons.tune_rounded, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 10),
            const Text('Filter Schemes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const Spacer(),
            TextButton(
              onPressed: () { widget.onReset(); Navigator.pop(context); },
              child: const Text('Reset all', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 18),
          const Text('SCOPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Row(children: [
            _FChip(label: 'All', isSelected: _jurisdiction == '', onTap: () => setState(() => _jurisdiction = '')),
            const SizedBox(width: 8),
            _FChip(label: 'Central Govt', isSelected: _jurisdiction == 'Central', onTap: () => setState(() => _jurisdiction = 'Central')),
            const SizedBox(width: 8),
            _FChip(label: 'State Govt', isSelected: _jurisdiction == 'State', onTap: () => setState(() => _jurisdiction = 'State')),
          ]),
          if (_jurisdiction == 'State' || _jurisdiction == '') ...[
            const SizedBox(height: 16),
            const Text('STATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true, isDense: true, value: _state,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                  items: widget.kIndianStates.map((st) => DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))))).toList(),
                  onChanged: (val) { if (val != null) setState(() => _state = val); },
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('QUICK TAGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: widget.kPopularTags.map((tag) {
              final isSelected = _tag == tag;
              return GestureDetector(
                onTap: () => setState(() => _tag = isSelected ? '' : tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isSelected) ...[const Icon(Icons.check_rounded, size: 12, color: Colors.white), const SizedBox(width: 4)],
                    Text(tag, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF374151))),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { widget.onApply(_jurisdiction, _state, _tag); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Apply Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF374151))),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SCHEMES TAB
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _SchemesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('All Schemes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF0F172A))),
        actions: [
          IconButton(icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF475569)), tooltip: 'AI Recommendations', onPressed: () => context.push('/recommendations')),
          const SizedBox(width: 4),
        ],
      ),
      body: ref.watch(allSchemesProvider).when(
        loading: () => const LoadingStateWidget(message: 'Loading schemes...'),
        error: (err, _) => ErrorStateWidget(message: 'Failed to load: $err', onRetry: () => ref.invalidate(allSchemesProvider)),
        data: (schemes) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: schemes.length,
          itemBuilder: (context, i) => _SchemeCard(
            scheme: schemes[i],
            isSaved: false,
            selectedSector: 'All',
            selectedState: '',
            onSave: () {},
            onTap: () => context.push('/catalog/${schemes[i].id}'),
            onChecklist: () => context.push('/checklist/${schemes[i].id}'),
          ),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// AI CHAT TAB
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _AiChatTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Row(children: [
          Icon(Icons.smart_toy_rounded, color: Colors.cyanAccent, size: 20),
          SizedBox(width: 8),
          Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF0F172A))),
        ]),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 38, color: Colors.cyanAccent),
            ),
            const SizedBox(height: 20),
            const Text('AI Scheme Assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('Ask anything about government schemes, eligibility, or how to apply.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: const Text('Start Chat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                onPressed: () => context.push('/assistant'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('AI Recommendations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                onPressed: () => context.push('/recommendations'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryBlue, side: const BorderSide(color: AppTheme.primaryBlue), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SAVED TAB
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _SavedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Saved Schemes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF0F172A))),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppTheme.primaryBlue.withAlpha(15), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.bookmark_rounded, size: 36, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 18),
            const Text('Your Saved Schemes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('View all the schemes you have bookmarked.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bookmark_rounded, size: 18),
                label: const Text('View Saved Schemes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                onPressed: () => context.push('/saved-schemes'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// PROFILE TAB
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _ProfileTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileType = ref.watch(selectedProfileTypeProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF0F172A))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const CircleAvatar(radius: 28, backgroundColor: Color(0xFF3B82F6), child: Icon(Icons.person_rounded, color: Colors.white, size: 30)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Citizen Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                  child: Text(profileType.displayName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          _PMenuItem(icon: Icons.person_outline_rounded, label: 'Edit Profile', subtitle: 'Update your profile type and details', onTap: () => context.push('/profile-type')),
          _PMenuItem(icon: Icons.shield_outlined, label: 'Document Vault', subtitle: 'Manage your uploaded documents', onTap: () => context.push('/documents/upload')),
          _PMenuItem(icon: Icons.bookmark_outline_rounded, label: 'Saved Schemes', subtitle: 'View all your bookmarked schemes', onTap: () => context.push('/saved-schemes')),
          _PMenuItem(icon: Icons.auto_awesome_rounded, label: 'AI Recommendations', subtitle: 'See schemes matched to your profile', onTap: () => context.push('/recommendations')),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          _PMenuItem(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            subtitle: 'Log out of your account',
            isDestructive: true,
            onTap: () { ref.read(authProvider.notifier).logout(); context.go('/login'); },
          ),
        ],
      ),
    );
  }
}

class _PMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  const _PMenuItem({required this.icon, required this.label, required this.subtitle, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.errorRed : AppTheme.primaryBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDestructive ? AppTheme.errorRed : const Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ])),
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
            ]),
          ),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SHARED: SCHEME CARD
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _SchemeCard extends StatelessWidget {
  final SchemeModel scheme;
  final bool isSaved;
  final String selectedSector;
  final String selectedState;
  final VoidCallback onSave;
  final VoidCallback onTap;
  final VoidCallback onChecklist;

  const _SchemeCard({
    required this.scheme,
    required this.isSaved,
    required this.selectedSector,
    required this.selectedState,
    required this.onSave,
    required this.onTap,
    required this.onChecklist,
  });

  @override
  Widget build(BuildContext context) {
    final isCentral = scheme.jurisdiction.toLowerCase() == 'central';
    final schemeTheme = SchemeImageHelper.getSchemeTheme(title: scheme.title, category: selectedSector);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: schemeTheme.gradient, begin: Alignment.centerLeft, end: Alignment.centerRight)),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                      child: Icon(schemeTheme.icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(schemeTheme.label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      const SizedBox(height: 2),
                      Text(
                        isCentral ? 'ðŸ› Central Government' : 'ðŸ—º State â€” ${scheme.state ?? selectedState}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ])),
                    GestureDetector(
                      onTap: onSave,
                      child: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isSaved ? const Color(0xFFFBBF24) : Colors.white70,
                        size: 20,
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFFDE68A))),
                      child: Text(scheme.benefitType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                    ),
                    const SizedBox(height: 8),
                    Text(scheme.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.3)),
                    const SizedBox(height: 5),
                    Text(scheme.shortDescription, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Row(children: [
                        const Icon(Icons.card_giftcard_rounded, size: 16, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(child: Text(scheme.benefitSummary, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.verified_rounded, size: 13, color: Colors.blue.shade500),
                      const SizedBox(width: 4),
                      Expanded(child: Text(scheme.provider, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
                      OutlinedButton(
                        onPressed: onChecklist,
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE2E8F0)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), visualDensity: VisualDensity.compact, minimumSize: Size.zero),
                        child: const Text('Checklist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), visualDensity: VisualDensity.compact, minimumSize: Size.zero),
                        child: const Text('Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
