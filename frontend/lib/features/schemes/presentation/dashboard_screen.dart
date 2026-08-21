import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/core/widgets/scheme_image_helper.dart';
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
  String _selectedSector = 'All';
  final Set<String> _savedSchemeIds = {};

  static const List<String> _kIndianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  static const List<Map<String, dynamic>> _kSectors = [
    {'id': 'All', 'label': 'All Schemes', 'icon': Icons.apps_rounded, 'color': AppTheme.primaryBlue, 'image': null},
    {'id': 'Education', 'label': 'Education & Scholarship', 'icon': Icons.school_rounded, 'color': Color(0xFF2563EB), 'image': 'assets/images/scholarship_card.png'},
    {'id': 'Agriculture', 'label': 'Agriculture & Farmers', 'icon': Icons.agriculture_rounded, 'color': Color(0xFF059669), 'image': 'assets/images/agriculture_card.png'},
    {'id': 'Entrepreneurship', 'label': 'Business & MSME', 'icon': Icons.store_rounded, 'color': Color(0xFF7C3AED), 'image': 'assets/images/business_card.png'},
    {'id': 'Women', 'label': 'Women & Child Welfare', 'icon': Icons.female_rounded, 'color': Color(0xFFDB2777), 'image': 'assets/images/women_card.png'},
    {'id': 'Skill', 'label': 'Employment & Skill', 'icon': Icons.work_rounded, 'color': Color(0xFFD97706), 'image': null},
    {'id': 'Senior', 'label': 'Senior Citizen & Pension', 'icon': Icons.elderly_rounded, 'color': Color(0xFF0D9488), 'image': null},
    {'id': 'General', 'label': 'Housing & Social Security', 'icon': Icons.home_rounded, 'color': Color(0xFF4F46E5), 'image': null},
  ];


  static const List<String> _kPopularTags = [
    'Scholarship',
    'PM Kisan',
    'MUDRA Loan',
    'Housing Grant',
    'Pension Scheme',
    'Skill Training',
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

  void _toggleSaveScheme(String schemeId) {
    setState(() {
      if (_savedSchemeIds.contains(schemeId)) {
        _savedSchemeIds.remove(schemeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheme removed from saved bookmarks'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _savedSchemeIds.add(schemeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheme saved to your bookmarks!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileType = ref.watch(selectedProfileTypeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_rounded, size: 24, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schemora Portal',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppTheme.primaryNavy,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'National & State Scheme Discovery',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.bookmark_outline_rounded, color: AppTheme.primaryNavy),
                if (_savedSchemeIds.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.warningOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_savedSchemeIds.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Saved Schemes',
            onPressed: () => context.push('/saved-schemes'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.primaryNavy),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new updates. All scheme statuses are up to date!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/assistant'),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.smart_toy_rounded, color: Colors.cyanAccent),
        label: const Text('Ask AI Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Banner & Citizen Profile Summary Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withAlpha(60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Profile Header Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white38, width: 2),
                              ),
                              child: const CircleAvatar(
                                backgroundColor: Color(0xFF3B82F6),
                                radius: 22,
                                child: Icon(Icons.person_rounded, color: Colors.white, size: 26),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome, Citizen!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.badge_rounded, size: 14, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Active: ',
                                        style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11),
                                      ),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(45),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            profileType.displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                                side: BorderSide(color: Colors.white.withAlpha(120)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.tune_rounded, size: 14),
                              label: const Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Stats Summary Row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withAlpha(30)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildHeaderStatItem(
                                icon: Icons.stars_rounded,
                                color: const Color(0xFFFBBF24),
                                value: 'Top 3',
                                label: 'AI Matches',
                              ),
                              Container(height: 24, width: 1, color: Colors.white24),
                              _buildHeaderStatItem(
                                icon: Icons.verified_user_rounded,
                                color: const Color(0xFF34D399),
                                value: '100%',
                                label: 'Verified Info',
                              ),
                              Container(height: 24, width: 1, color: Colors.white24),
                              _buildHeaderStatItem(
                                icon: Icons.security_rounded,
                                color: const Color(0xFF60A5FA),
                                value: 'Grounded',
                                label: 'Privacy First',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Quick Service Access Grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickHeaderActionCard(
                              context,
                              icon: Icons.auto_awesome_rounded,
                              iconColor: const Color(0xFFFBBF24),
                              bgColor: const Color(0xFFFEF3C7).withAlpha(40),
                              title: 'Eligible Matches',
                              onTap: () => context.push('/recommendations'),
                            ),
                            _buildQuickHeaderActionCard(
                              context,
                              icon: Icons.chat_bubble_outline_rounded,
                              iconColor: Colors.cyanAccent,
                              bgColor: Colors.cyan.withAlpha(40),
                              title: 'AI Assistant',
                              onTap: () => context.push('/assistant'),
                            ),
                            _buildQuickHeaderActionCard(
                              context,
                              icon: Icons.shield_rounded,
                              iconColor: const Color(0xFF60A5FA),
                              bgColor: Colors.blue.withAlpha(40),
                              title: 'Doc Vault',
                              onTap: () => context.push('/documents/upload'),
                            ),
                            _buildQuickHeaderActionCard(
                              context,
                              icon: Icons.bookmark_added_rounded,
                              iconColor: const Color(0xFF34D399),
                              bgColor: const Color(0xFF10B981).withAlpha(40),
                              title: 'Saved Schemes',
                              onTap: () => context.push('/saved-schemes'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Filter Controls & Search Bar Box
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Box
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 14, color: AppTheme.primaryNavy),
                        decoration: InputDecoration(
                          hintText: 'Search schemes by keyword, benefit, or eligibility...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue, size: 22),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 10),

                      // Popular Search Tags
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            const Text('Popular:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(width: 6),
                            ..._kPopularTags.map((tag) {
                              final isSelected = _searchController.text == tag;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _searchController.clear();
                                      } else {
                                        _searchController.text = tag;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.white : AppTheme.primaryNavy,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Scope Filter Row (All / Central / State)
                      Row(
                        children: [
                          const Text('Jurisdiction:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              children: [
                                _buildScopeChip(
                                  label: 'All',
                                  isSelected: _selectedJurisdiction == '',
                                  onTap: () => setState(() => _selectedJurisdiction = ''),
                                ),
                                const SizedBox(width: 6),
                                _buildScopeChip(
                                  label: 'Central',
                                  icon: Icons.flag_rounded,
                                  isSelected: _selectedJurisdiction == 'Central',
                                  activeColor: AppTheme.primaryNavy,
                                  onTap: () => setState(() => _selectedJurisdiction = 'Central'),
                                ),
                                const SizedBox(width: 6),
                                _buildScopeChip(
                                  label: 'State',
                                  icon: Icons.location_city_rounded,
                                  isSelected: _selectedJurisdiction == 'State',
                                  activeColor: const Color(0xFF0D9488),
                                  onTap: () => setState(() => _selectedJurisdiction = 'State'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // State Filter Dropdown
                      if (_selectedJurisdiction == 'State' || _selectedJurisdiction == '') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.map_rounded, size: 16, color: AppTheme.primaryBlue),
                            const SizedBox(width: 6),
                            const Text('State:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isDense: true,
                                    value: _selectedState,
                                    dropdownColor: Colors.white,
                                    items: _kIndianStates
                                        .map((st) => DropdownMenuItem(
                                              value: st,
                                              child: Text(st, style: const TextStyle(fontSize: 13, color: AppTheme.primaryNavy)),
                                            ))
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

                      const SizedBox(height: 14),

                      // Sector Header & Horizontal Pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sectors / Categories:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy)),
                          if (_selectedSector != 'All' || _selectedJurisdiction != '' || _searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: _resetFilters,
                              child: const Text('Reset All', style: TextStyle(fontSize: 12, color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _kSectors.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, idx) {
                            final sector = _kSectors[idx];
                            final isSelected = _selectedSector == sector['id'];
                            final color = sector['color'] as Color;

                            return InkWell(
                              onTap: () => setState(() => _selectedSector = sector['id'] as String),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? color : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? color : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      sector['icon'] as IconData,
                                      size: 15,
                                      color: isSelected ? Colors.white : color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      sector['label'] as String,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppTheme.primaryNavy,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Scheme Catalog Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.explore_rounded, size: 20, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            _selectedSector == 'All' ? 'Available Schemes' : '$_selectedSector Schemes',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Verified Portal Data',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              // Scheme Cards List
              ...ref.watch(allSchemesProvider).when(
                loading: () => const [
                  SliverFillRemaining(
                    child: LoadingStateWidget(message: 'Searching government scheme repository...'),
                  ),
                ],
                error: (err, _) => [
                  SliverFillRemaining(
                    child: ErrorStateWidget(
                      message: 'Failed to load schemes: $err',
                      onRetry: () => ref.invalidate(allSchemesProvider),
                    ),
                  ),
                ],
                data: (allSchemes) {
                  var schemes = List<SchemeModel>.from(allSchemes);

                  if (_selectedJurisdiction.isNotEmpty) {
                    schemes = schemes.where((s) => s.jurisdiction.toLowerCase() == _selectedJurisdiction.toLowerCase()).toList();
                  }
                  if (_selectedJurisdiction == 'State') {
                    schemes = schemes.where((s) => s.state == null || s.state!.toLowerCase() == _selectedState.toLowerCase()).toList();
                  }
                  if (_selectedSector != 'All') {
                    final secLower = _selectedSector.toLowerCase();
                    schemes = schemes.where((s) {
                      final title = s.title.toLowerCase();
                      final desc = s.shortDescription.toLowerCase();
                      final ben = s.benefitSummary.toLowerCase();
                      return title.contains(secLower) || desc.contains(secLower) || ben.contains(secLower);
                    }).toList();
                  }
                  if (_searchController.text.isNotEmpty) {
                    final q = _searchController.text.toLowerCase();
                    schemes = schemes.where((s) {
                      final title = s.title.toLowerCase();
                      final desc = s.shortDescription.toLowerCase();
                      final ben = s.benefitSummary.toLowerCase();
                      final prov = s.provider.toLowerCase();
                      return title.contains(q) || desc.contains(q) || ben.contains(q) || prov.contains(q);
                    }).toList();
                  }

                  if (schemes.isEmpty) {
                    return [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.primaryBlue),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Matching Schemes Found',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search keywords, switching jurisdiction, or clearing sector filters.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _resetFilters,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Reset All Filters'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryNavy,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  }

                  return [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final scheme = schemes[index];
                            final isCentral = scheme.jurisdiction.toLowerCase() == 'central';
                            final isSaved = _savedSchemeIds.contains(scheme.id);

                            final schemeTheme = SchemeImageHelper.getSchemeTheme(
                              title: scheme.title,
                              category: _selectedSector,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(8),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => context.push('/catalog/${scheme.id}'),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // ── Professional compact header bar ──────────────
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: schemeTheme.gradient,
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Category icon
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withAlpha(28),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  schemeTheme.icon,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              // Category label
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      schemeTheme.label,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 1),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withAlpha(28),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        isCentral ? '🏛 Central Government' : '🗺 State: ${scheme.state ?? _selectedState}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Save bookmark button
                                              GestureDetector(
                                                onTap: () => _toggleSaveScheme(scheme.id),
                                                child: Container(
                                                  padding: const EdgeInsets.all(7),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withAlpha(28),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                                    color: isSaved ? const Color(0xFFFBBF24) : Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF3C7),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                                    ),
                                                    child: Text(
                                                      scheme.benefitType,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFFB45309),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                               ),
                                       const SizedBox(height: 12),


                                      // Scheme Title
                                      Text(
                                        scheme.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryNavy,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Short Description
                                      Text(
                                        scheme.shortDescription,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 14),

                                      // Financial Benefit Highlight Box
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryBlue.withAlpha(20),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.card_giftcard_rounded, size: 18, color: AppTheme.primaryBlue),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Key Benefit Highlight',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    scheme.benefitSummary,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppTheme.primaryNavy,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 14),
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),

                                      // Footer Actions & Provider
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(Icons.verified_rounded, size: 14, color: Colors.blue.shade600),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    scheme.provider,
                                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => context.push('/checklist/${scheme.id}'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppTheme.primaryNavy,
                                              side: BorderSide(color: Colors.grey.shade300),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            icon: const Icon(Icons.checklist_rtl_rounded, size: 15),
                                            label: const Text('Checklist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                          ),
                                          const SizedBox(width: 6),
                                          ElevatedButton.icon(
                                            onPressed: () => context.push('/catalog/${scheme.id}'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryBlue,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                            label: const Text(
                                              'Details',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                         ],
                                       ),
                                     ],
                                   ),
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
                  ),
                ];
              },
            ),
          ],


          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStatItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickHeaderActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    Color activeColor = AppTheme.primaryBlue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : activeColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.primaryNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
