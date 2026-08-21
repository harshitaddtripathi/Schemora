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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();

  String _selectedJurisdiction = '';
  String _selectedState = 'Maharashtra';
  String _selectedSector = 'All';
  final Set<String> _savedSchemeIds = {};

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

  static const List<Map<String, dynamic>> _kSectors = [
    {'id': 'All',            'label': 'All',          'icon': Icons.apps_rounded,        'color': AppTheme.primaryBlue},
    {'id': 'Education',      'label': 'Education',    'icon': Icons.school_rounded,      'color': Color(0xFF2563EB)},
    {'id': 'Agriculture',    'label': 'Agriculture',  'icon': Icons.agriculture_rounded, 'color': Color(0xFF059669)},
    {'id': 'Entrepreneurship','label': 'Business',    'icon': Icons.store_rounded,       'color': Color(0xFF7C3AED)},
    {'id': 'Women',          'label': 'Women',        'icon': Icons.female_rounded,      'color': Color(0xFFDB2777)},
    {'id': 'Skill',          'label': 'Skill',        'icon': Icons.work_rounded,        'color': Color(0xFFD97706)},
    {'id': 'Senior',         'label': 'Senior',       'icon': Icons.elderly_rounded,     'color': Color(0xFF0D9488)},
    {'id': 'General',        'label': 'Housing',      'icon': Icons.home_rounded,        'color': Color(0xFF4F46E5)},
  ];

  static const List<String> _kPopularTags = [
    'Scholarship', 'PM Kisan', 'MUDRA Loan', 'Housing Grant', 'Pension', 'Skill Training',
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
            content: Text('Removed from bookmarks'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _savedSchemeIds.add(schemeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to bookmarks!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  bool get _hasActiveFilter =>
      _selectedSector != 'All' ||
      _selectedJurisdiction != '' ||
      _searchController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final profileType = ref.watch(selectedProfileTypeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/assistant'),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.smart_toy_rounded, color: Colors.cyanAccent, size: 20),
        label: const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: AppTheme.primaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Welcome banner ─────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildWelcomeBanner(profileType)),

              // ── Quick actions row ──────────────────────────────────────────
              SliverToBoxAdapter(child: _buildQuickActions()),

              // ── Search + filters ───────────────────────────────────────────
              SliverToBoxAdapter(child: _buildSearchAndFilters()),

              // ── Section header ─────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildSectionHeader()),

              // ── Scheme list ────────────────────────────────────────────────
              ..._buildSchemeList(),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.account_balance_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text(
            'Schemora',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF475569)),
              if (_savedSchemeIds.isNotEmpty)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.warningOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_savedSchemeIds.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Saved Schemes',
          onPressed: () => context.push('/saved-schemes'),
        ),
        PopupMenuButton<String>(
          tooltip: 'Account',
          icon: const CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(Icons.person_rounded, size: 17, color: AppTheme.primaryBlue),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          offset: const Offset(0, 46),
          itemBuilder: (_) => [
            const PopupMenuItem<String>(
              enabled: false,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Citizen Account',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                  SizedBox(height: 2),
                  Text('+91 9876543210',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 17, color: Color(0xFFDC2626)),
                  SizedBox(width: 10),
                  Text('Sign Out',
                      style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'logout') {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            }
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Welcome banner ──────────────────────────────────────────────────────────
  Widget _buildWelcomeBanner(dynamic profileType) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFF3B82F6),
            child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Citizen!',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        profileType.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/profile-type'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withAlpha(25),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Edit Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Quick actions ───────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(icon: Icons.auto_awesome_rounded,       label: 'AI Matches',    color: const Color(0xFFF59E0B), onTap: () => context.push('/recommendations')),
      _QuickAction(icon: Icons.chat_bubble_outline_rounded, label: 'AI Chat',      color: const Color(0xFF06B6D4), onTap: () => context.push('/assistant')),
      _QuickAction(icon: Icons.shield_outlined,            label: 'Doc Vault',     color: const Color(0xFF6366F1), onTap: () => context.push('/documents/upload')),
      _QuickAction(icon: Icons.bookmark_outline_rounded,   label: 'Saved',         color: const Color(0xFF10B981), onTap: () => context.push('/saved-schemes')),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: actions.map((a) {
          return Expanded(
            child: GestureDetector(
              onTap: a.onTap,
              child: Container(
                margin: EdgeInsets.only(right: actions.last == a ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: a.color.withAlpha(24),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.icon, size: 20, color: a.color),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.label,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Search + Filters ────────────────────────────────────────────────────────
  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Search schemes...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _searchController.clear()),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 10),

          // Popular tags
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.orange.shade600),
                const SizedBox(width: 5),
                const Text('Popular:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                const SizedBox(width: 8),
                ..._kPopularTags.map((tag) {
                  final isSelected = _searchController.text == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        isSelected ? _searchController.clear() : _searchController.text = tag;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Jurisdiction chips
          Row(
            children: [
              const Text('Scope:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
              const SizedBox(width: 10),
              _buildChip('All', _selectedJurisdiction == '', () => setState(() => _selectedJurisdiction = '')),
              const SizedBox(width: 6),
              _buildChip('Central', _selectedJurisdiction == 'Central', () => setState(() => _selectedJurisdiction = 'Central')),
              const SizedBox(width: 6),
              _buildChip('State', _selectedJurisdiction == 'State', () => setState(() => _selectedJurisdiction = 'State')),
              const Spacer(),
              if (_hasActiveFilter)
                GestureDetector(
                  onTap: _resetFilters,
                  child: const Text('Reset', style: TextStyle(fontSize: 12, color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
                ),
            ],
          ),

          // State dropdown (only when relevant)
          if (_selectedJurisdiction == 'State' || _selectedJurisdiction == '') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  isDense: true,
                  value: _selectedState,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                  items: _kIndianStates
                      .map((st) => DropdownMenuItem(
                            value: st,
                            child: Text(st, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedState = val);
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Sector pills
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? color : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sector['icon'] as IconData, size: 14, color: isSelected ? Colors.white : color),
                        const SizedBox(width: 5),
                        Text(
                          sector['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF374151),
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
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  // ── Section header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _selectedSector == 'All' ? 'All Schemes' : '$_selectedSector Schemes',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          Text(
            'Tap to view details',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Scheme list ─────────────────────────────────────────────────────────────
  List<Widget> _buildSchemeList() {
    return [
      ...ref.watch(allSchemesProvider).when(
        loading: () => const [
          SliverFillRemaining(
            child: LoadingStateWidget(message: 'Loading schemes...'),
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
            schemes = schemes
                .where((s) => s.jurisdiction.toLowerCase() == _selectedJurisdiction.toLowerCase())
                .toList();
          }
          if (_selectedJurisdiction == 'State') {
            schemes = schemes
                .where((s) => s.state == null || s.state!.toLowerCase() == _selectedState.toLowerCase())
                .toList();
          }
          if (_selectedSector != 'All') {
            final q = _selectedSector.toLowerCase();
            schemes = schemes.where((s) {
              return s.title.toLowerCase().contains(q) ||
                  s.shortDescription.toLowerCase().contains(q) ||
                  s.benefitSummary.toLowerCase().contains(q);
            }).toList();
          }
          if (_searchController.text.isNotEmpty) {
            final q = _searchController.text.toLowerCase();
            schemes = schemes.where((s) {
              return s.title.toLowerCase().contains(q) ||
                  s.shortDescription.toLowerCase().contains(q) ||
                  s.benefitSummary.toLowerCase().contains(q) ||
                  s.provider.toLowerCase().contains(q);
            }).toList();
          }

          if (schemes.isEmpty) {
            return [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade400),
                        const SizedBox(height: 14),
                        const Text(
                          'No schemes found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try adjusting the filters or search term.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 18),
                        TextButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          }

          return [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
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

// ═══════════════════════════════════════════════════════════════════════════════
// _QuickAction data class
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}

// ═══════════════════════════════════════════════════════════════════════════════
// _SchemeCard
// ═══════════════════════════════════════════════════════════════════════════════

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
    final schemeTheme = SchemeImageHelper.getSchemeTheme(
      title: scheme.title,
      category: selectedSector,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                // ── Coloured header strip ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: schemeTheme.gradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(schemeTheme.icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schemeTheme.label.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCentral ? '🏛 Central Government' : '🗺 State — ${scheme.state ?? selectedState}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onSave,
                        child: Icon(
                          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: isSaved ? const Color(0xFFFBBF24) : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Card body ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Benefit type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          scheme.benefitType,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Title
                      Text(
                        scheme.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Description
                      Text(
                        scheme.shortDescription,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Benefit highlight
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.card_giftcard_rounded, size: 16, color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                scheme.benefitSummary,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Footer
                      Row(
                        children: [
                          Icon(Icons.verified_rounded, size: 13, color: Colors.blue.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              scheme.provider,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          OutlinedButton(
                            onPressed: onChecklist,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF374151),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              visualDensity: VisualDensity.compact,
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Checklist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              visualDensity: VisualDensity.compact,
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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
  }
}
