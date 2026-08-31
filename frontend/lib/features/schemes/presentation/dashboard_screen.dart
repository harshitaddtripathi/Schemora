import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/core/widgets/scheme_image_helper.dart';
import 'package:schemora_frontend/features/auth/data/auth_repository.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type_provider.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type.dart';
import 'package:schemora_frontend/features/profile/domain/profile_model.dart';
import 'package:schemora_frontend/features/profile/data/profile_repository.dart';
import 'package:schemora_frontend/features/schemes/data/scheme_repository.dart';
import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';
import 'package:schemora_frontend/core/providers/app_language_provider.dart';
import 'package:schemora_frontend/features/ai_assistant/data/voice_assistant_service.dart';
import 'package:schemora_frontend/features/news/data/news_repository.dart';
import 'package:schemora_frontend/features/saved_schemes/data/saved_scheme_repository.dart';

// ── Main shell with bottom navigation ─────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  String? _categoryFilter;

  void _navigateTo(int index, {String? category}) {
    setState(() {
      _currentIndex = index;
      if (index == 1) {
        // Only update filter when navigating to Schemes tab
        _categoryFilter = category;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeLang = ref.watch(appLanguageProvider);
    final navItems = [
      _NavItem(icon: Icons.home_rounded, label: AppTranslations.tr('nav_home', activeLang.code)),
      _NavItem(icon: Icons.list_alt_rounded, label: AppTranslations.tr('nav_schemes', activeLang.code)),
      _NavItem(icon: Icons.mic_rounded, label: AppTranslations.tr('nav_ai', activeLang.code)),
      _NavItem(icon: Icons.bookmark_rounded, label: AppTranslations.tr('nav_saved', activeLang.code)),
      _NavItem(icon: Icons.person_rounded, label: AppTranslations.tr('nav_profile', activeLang.code)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(onNavigate: _navigateTo),
          _SchemesTab(initialCategory: _categoryFilter),
          _AiChatTab(),
          _SavedTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(navItems),
    );
  }


  Widget _buildBottomNav(List<_NavItem> navItems) {
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
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive ? AppTheme.primaryBlue : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 16 REGIONAL LANGUAGES SELECTOR MODAL SHEET ─────────────────────────────

void _showLanguageSelectorModal(BuildContext context, WidgetRef ref) {
  final currentLang = ref.read(appLanguageProvider);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.g_translate_rounded, color: AppTheme.primaryBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.tr('select_lang_title', currentLang.code),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const Text(
                        '16 Indian Regional Languages Supported',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 14),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.3,
                ),
                itemCount: kSupportedLanguages.length,
                itemBuilder: (context, index) {
                  final lang = kSupportedLanguages[index];
                  final isSelected = lang.code == currentLang.code;

                  return Material(
                    color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        ref.read(appLanguageProvider.notifier).setLanguageByCode(lang.code);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('App language changed to ${lang.nativeName} (${lang.name})'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppTheme.primaryBlue,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(lang.flag, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    lang.nativeName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                      color: isSelected ? AppTheme.primaryBlue : const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    lang.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected ? AppTheme.primaryBlue.withAlpha(200) : const Color(0xFF64748B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ── HOME LANDING TAB (ACCESSIBLE & ILLITERATE FRIENDLY) ─────────────────────

class _HomeTab extends ConsumerStatefulWidget {
  final void Function(int, {String? category}) onNavigate;
  const _HomeTab({required this.onNavigate});

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final _searchController = TextEditingController();
  String? _currentlySpeakingId;

  static const List<_Announcement> _kAnnouncements = [
    _Announcement(
      id: 'a1',
      title: 'PM-Kisan 17th Installment Disbursed',
      tag: 'URGENT',
      tagColor: Color(0xFFDC2626),
      date: 'Aug 25, 2026',
      summary: 'Direct transfer of ₹2,000 credited to eligible farmers.',
      fullDetails: 'Ministry of Agriculture has disbursed the 17th installment under PM-Kisan. Ensure your bank account e-KYC is complete to receive direct benefit payments.',
      icon: Icons.agriculture_rounded,
    ),
    _Announcement(
      id: 'a2',
      title: 'National Scholarship Portal Deadline Extended',
      tag: 'DEADLINE',
      tagColor: Color(0xFFD97706),
      date: 'Aug 24, 2026',
      summary: 'Application verification window extended till September 15, 2026.',
      fullDetails: 'Students applying for Post-Matric & Merit Scholarships can submit applications up to Sept 15, 2026.',
      icon: Icons.school_rounded,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSpeakItem({required String id, required String text, required String langCode}) async {
    final voiceService = ref.read(voiceAssistantServiceProvider);
    if (_currentlySpeakingId == id) {
      await voiceService.stopSpeaking();
      setState(() => _currentlySpeakingId = null);
    } else {
      await voiceService.stopSpeaking();
      setState(() => _currentlySpeakingId = id);
      await voiceService.speak(text, languageCode: langCode);
    }
  }

  void _showAnnouncementModal(_Announcement announcement, LanguageInfo activeLang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnnouncementModalSheet(
        announcement: announcement,
        activeLang: activeLang,
        onSpeak: () => _toggleSpeakItem(id: announcement.id, text: '${announcement.title}. ${announcement.fullDetails}', langCode: activeLang.code),
        onExplore: () {
          Navigator.pop(ctx);
          widget.onNavigate(1);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLang = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(activeLang),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: AppTheme.primaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildVoiceHeroBanner(activeLang)),
            SliverToBoxAdapter(child: _buildCategoryGrid(activeLang)),
            SliverToBoxAdapter(child: _buildSearchBar(activeLang)),
            SliverToBoxAdapter(child: _buildAnnouncementsSection(activeLang)),
            SliverToBoxAdapter(child: _buildLatestNewsSection(activeLang)),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(LanguageInfo activeLang) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withAlpha(60), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.account_balance_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Schemora', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A), letterSpacing: -0.4)),
              Text('Government Welfare', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => _showLanguageSelectorModal(context, ref),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.4),
              boxShadow: [BoxShadow(color: Colors.blue.withAlpha(20), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(activeLang.flag, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 4),
                Text(
                  activeLang.nativeName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF1E40AF)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildVoiceHeroBanner(LanguageInfo activeLang) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(80),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.push('/assistant'),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(30),
                  ),
                ),
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withAlpha(120),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded, size: 38, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppTranslations.tr('voice_hero_title', activeLang.code),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.tr('voice_hero_sub', activeLang.code),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withAlpha(230),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/assistant'),
              icon: const Icon(Icons.graphic_eq_rounded, size: 20),
              label: Text(
                AppTranslations.tr('tap_to_speak', activeLang.code),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E3A8A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(LanguageInfo activeLang) {
    final categories = [
      {'id': 'Agriculture', 'label': AppTranslations.tr('farmer', activeLang.code), 'icon': Icons.agriculture_rounded, 'color': const Color(0xFF059669)},
      {'id': 'Education', 'label': AppTranslations.tr('student', activeLang.code), 'icon': Icons.school_rounded, 'color': const Color(0xFF2563EB)},
      {'id': 'Women', 'label': AppTranslations.tr('women', activeLang.code), 'icon': Icons.female_rounded, 'color': const Color(0xFFDB2777)},
      {'id': 'Entrepreneurship', 'label': AppTranslations.tr('business', activeLang.code), 'icon': Icons.store_rounded, 'color': const Color(0xFF7C3AED)},
      {'id': 'Health', 'label': AppTranslations.tr('health', activeLang.code), 'icon': Icons.medical_services_rounded, 'color': const Color(0xFFDC2626)},
      {'id': 'General', 'label': AppTranslations.tr('housing', activeLang.code), 'icon': Icons.home_rounded, 'color': const Color(0xFF4F46E5)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: Text(
            AppTranslations.tr('categories_title', activeLang.code),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              final color = cat['color'] as Color;
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => widget.onNavigate(1, category: cat['id'] as String),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
                          child: Icon(cat['icon'] as IconData, size: 24, color: color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat['label'] as String,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(LanguageInfo activeLang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Search schemes... / योजना खोजें...',
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

  Widget _buildAnnouncementsSection(LanguageInfo activeLang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.campaign_rounded, size: 18, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 8),
              Text(
                AppTranslations.tr('announcements', activeLang.code),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _kAnnouncements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final item = _kAnnouncements[idx];
              final isSpeakingThis = _currentlySpeakingId == item.id;
              return Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _showAnnouncementModal(item, activeLang),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: item.tagColor.withAlpha(15), borderRadius: BorderRadius.circular(6)),
                                child: Text(item.tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: item.tagColor)),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _toggleSpeakItem(id: item.id, text: '${item.title}. ${item.summary}', langCode: activeLang.code),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSpeakingThis ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSpeakingThis ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSpeakingThis ? Icons.stop_rounded : Icons.volume_up_rounded,
                                        size: 13,
                                        color: isSpeakingThis ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isSpeakingThis ? AppTranslations.tr('stop_label', activeLang.code) : AppTranslations.tr('listen_label', activeLang.code),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isSpeakingThis ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(item.summary, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLatestNewsSection(LanguageInfo activeLang) {
    final newsArticles = ref.watch(newsRepositoryProvider).getAllNews();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.newspaper_rounded, size: 18, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 8),
              Text(
                AppTranslations.tr('latest_news', activeLang.code),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: newsArticles.length,
          itemBuilder: (context, idx) {
            final article = newsArticles[idx];
            final localizedTitle = article.getTitle(activeLang.code);
            final localizedCategory = article.getCategory(activeLang.code);
            final localizedSummary = article.getSummary(activeLang.code);

            final isSpeakingThis = _currentlySpeakingId == article.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => context.push('/news/${article.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            article.imagePath,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 84,
                              height: 84,
                              color: article.categoryColor.withAlpha(20),
                              child: Icon(article.icon, color: article.categoryColor, size: 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: article.categoryColor.withAlpha(15), borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      localizedCategory,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: article.categoryColor),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => _toggleSpeakItem(id: article.id, text: '$localizedTitle. $localizedSummary', langCode: activeLang.code),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSpeakingThis ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isSpeakingThis ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSpeakingThis ? Icons.stop_rounded : Icons.volume_up_rounded,
                                            size: 13,
                                            color: isSpeakingThis ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isSpeakingThis ? AppTranslations.tr('stop_label', activeLang.code) : AppTranslations.tr('listen_label', activeLang.code),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isSpeakingThis ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                localizedTitle,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                localizedSummary,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.35),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
          ),
        ],
      );
  }
}

// ── ANNOUNCEMENT & NEWS MODELS AND MODAL SHEETS ──────────────────────────────

class _Announcement {
  final String id;
  final String title;
  final String tag;
  final Color tagColor;
  final String date;
  final String summary;
  final String fullDetails;
  final IconData icon;

  const _Announcement({
    required this.id,
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.date,
    required this.summary,
    required this.fullDetails,
    required this.icon,
  });
}



class _AnnouncementModalSheet extends StatelessWidget {
  final _Announcement announcement;
  final LanguageInfo activeLang;
  final VoidCallback onSpeak;
  final VoidCallback onExplore;

  const _AnnouncementModalSheet({
    required this.announcement,
    required this.activeLang,
    required this.onSpeak,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: announcement.tagColor.withAlpha(15), borderRadius: BorderRadius.circular(6)),
                child: Text(announcement.tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: announcement.tagColor)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onSpeak,
                icon: const Icon(Icons.volume_up_rounded, size: 16),
                label: Text(AppTranslations.tr('listen_label', activeLang.code), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(announcement.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.3)),

          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Text(announcement.fullDetails, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5)),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text('Explore Related Schemes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// SCHEMES TAB
// ─────────────────────────────────────────────────────────────────────────────

class _SchemesTab extends ConsumerStatefulWidget {
  final String? initialCategory;
  const _SchemesTab({this.initialCategory});

  @override
  ConsumerState<_SchemesTab> createState() => _SchemesTabState();
}

class _SchemesTabState extends ConsumerState<_SchemesTab> {
  String? _activeCategory;

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.initialCategory;
  }

  @override
  void didUpdateWidget(_SchemesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      setState(() => _activeCategory = widget.initialCategory);
    }
  }

  // Human-readable label for each category ID
  String _categoryLabel(String id) {
    switch (id) {
      case 'Agriculture': return '🌾 Farmer / Agriculture';
      case 'Education': return '🎓 Student / Education';
      case 'Women': return '👩 Women';
      case 'Entrepreneurship': return '🏪 Business / Entrepreneurship';
      case 'Health': return '❤️ Health';
      case 'General': return '🏠 Housing / General';
      default: return id;
    }
  }

  // Map category ID to keywords used for filtering
  String _categoryKeyword(String id) {
    switch (id) {
      case 'Agriculture': return 'agri';
      case 'Education': return 'scholar';
      case 'Women': return 'women';
      case 'Entrepreneurship': return 'entrepreneur';
      case 'Health': return 'health';
      case 'General': return 'housing';
      default: return id.toLowerCase();
    }
  }

  List<SchemeModel> _applyFilter(List<SchemeModel> all) {
    if (_activeCategory == null || _activeCategory!.isEmpty) return all;
    final kw = _categoryKeyword(_activeCategory!);
    return all.where((s) {
      final title = s.title.toLowerCase();
      final desc = s.shortDescription.toLowerCase();
      final benefit = s.benefitSummary.toLowerCase();
      final provider = s.provider.toLowerCase();
      // Extra category-specific keywords
      switch (_activeCategory) {
        case 'Agriculture':
          return title.contains('kisan') || title.contains('farm') || title.contains('agri') ||
              title.contains('crop') || desc.contains('farmer') || desc.contains('agri') ||
              provider.contains('agriculture');
        case 'Education':
          return title.contains('scholar') || title.contains('student') ||
              title.contains('education') || title.contains('internship') ||
              desc.contains('scholar') || desc.contains('student') ||
              provider.contains('education');
        case 'Women':
          return title.contains('women') || title.contains('mahila') ||
              title.contains('ladki') || title.contains('beti') ||
              desc.contains('women') || desc.contains('mahila');
        case 'Entrepreneurship':
          return title.contains('entrepreneur') || title.contains('mudra') ||
              title.contains('msme') || title.contains('startup') ||
              title.contains('business') || title.contains('skill') ||
              desc.contains('entrepreneur') || desc.contains('business') ||
              provider.contains('msme');
        case 'Health':
          return title.contains('health') || title.contains('ayushman') ||
              title.contains('janani') || title.contains('matri') ||
              title.contains('medical') || desc.contains('health') ||
              benefit.contains('health') || provider.contains('health');
        case 'General':
          return title.contains('housing') || title.contains('awas') ||
              title.contains('pension') || title.contains('ration') ||
              title.contains('ujjwala') || title.contains('svamitva') ||
              desc.contains('housing') || desc.contains('general');
        default:
          return title.contains(kw) || desc.contains(kw) || benefit.contains(kw);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = _activeCategory != null && _activeCategory!.isNotEmpty;

    final activeProfileType = ref.watch(selectedProfileTypeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(
          hasFilter ? _categoryLabel(_activeCategory!) : 'All Schemes',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF475569)), tooltip: 'AI Recommendations', onPressed: () => context.push('/recommendations')),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Active filter chip
          if (hasFilter)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF475569)),
                  const SizedBox(width: 8),
                  const Text('Filtered by:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      _categoryLabel(_activeCategory!),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                    ),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF1E40AF)),
                    onDeleted: () => setState(() => _activeCategory = null),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

          if (hasFilter && _activeCategory != 'Education' && _activeCategory != 'General' && activeProfileType == ProfileType.student)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                        children: [
                          const TextSpan(text: 'Notice: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'Viewing ${_categoryLabel(_activeCategory!)} schemes. Your active profile is '),
                          const TextSpan(text: 'Student / Learner. ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: 'Schemes for this category are listed below with clear eligibility status & reasons.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Schemes list
          Expanded(
            child: ref.watch(allSchemesProvider).when(
              loading: () => const LoadingStateWidget(message: 'Loading schemes...'),
              error: (err, _) => ErrorStateWidget(message: 'Failed to load: $err', onRetry: () => ref.invalidate(allSchemesProvider)),
              data: (schemes) {
                final filtered = _applyFilter(schemes);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 14),
                        Text(
                          'No schemes found for this category.',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () => setState(() => _activeCategory = null),
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          label: const Text('Show all schemes'),
                        ),
                      ],
                    ),
                  );
                }
                final savedIds = ref.watch(savedSchemeIdsProvider).value ?? {};
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    final isSaved = savedIds.contains(item.id);
                    return _SchemeCard(
                      scheme: item,
                      isSaved: isSaved,
                      selectedSector: _activeCategory ?? 'All',
                      selectedState: '',
                      onSave: () async {
                        try {
                          final nowSaved = await ref
                              .read(savedSchemeIdsProvider.notifier)
                              .toggleSave(item.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  nowSaved
                                      ? 'Scheme saved to My Saved Schemes!'
                                      : 'Scheme removed from Saved Schemes.',
                                ),
                                action: SnackBarAction(
                                  label: 'View All',
                                  onPressed: () => context.push('/saved-schemes'),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update bookmark: $e')),
                            );
                          }
                        }
                      },
                      onTap: () => context.push('/catalog/${item.id}'),
                      onChecklist: () => context.push('/checklist/${item.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI CHAT TAB
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// SAVED TAB
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileType = ref.watch(selectedProfileTypeProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final authState = ref.watch(authProvider);
    final userPhone = authState.phoneNumber ?? '+91 9876543210';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildBody(context, ref, null, profileType, userPhone),
        data: (profile) => _buildBody(context, ref, profile, profileType, userPhone),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ProfileModel? profile,
    ProfileType profileType,
    String phone,
  ) {
    final name = (profile != null && profile.fullName.isNotEmpty)
        ? profile.fullName
        : _getDefaultNameForType(profileType);
    final dob = (profile != null && profile.dateOfBirth.isNotEmpty)
        ? profile.dateOfBirth
        : _getDefaultDobForType(profileType);
    final gender = profile?.gender ?? 'Male';
    final state = profile?.state ?? 'Maharashtra';
    final socialCategory = profile?.socialCategory ?? 'OBC';
    final income = profile?.annualFamilyIncome != null
        ? '₹${profile!.annualFamilyIncome!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
        : '₹2,50,000 / year';
    final educationLevel = profile?.educationLevel ?? _getDefaultEducationForType(profileType);
    final course = profile?.courseName ?? _getDefaultCourseForType(profileType);
    final institution = profile?.institutionName ?? _getDefaultInstitutionForType(profileType);
    final employment = profile?.employmentStatus ?? _getDefaultEmploymentForType(profileType);

    // Profile completion score
    int filled = 0;
    if (profile?.fullName.isNotEmpty ?? false) filled++;
    if (profile?.dateOfBirth.isNotEmpty ?? false) filled++;
    if (profile?.gender != null) filled++;
    if (profile?.state != null) filled++;
    if (profile?.socialCategory != null) filled++;
    if (profile?.annualFamilyIncome != null) filled++;
    final completionPct = (filled / 6.0).clamp(0.0, 1.0);
    final completionInt = (completionPct * 100).round();

    final (ptColor, ptIcon, ptLabel) = _profileTypeMeta(profileType);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero Header ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20, right: -20,
                      child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(10))),
                    ),
                    Positioned(
                      top: 48, right: 16,
                      child: InkWell(
                        onTap: () => context.push('/profile-form'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withAlpha(60)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar
              Positioned(
                bottom: -40,
                left: 20,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [ptColor, ptColor.withAlpha(190)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(color: ptColor.withAlpha(60), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Icon(ptIcon, color: Colors.white, size: 38),
                ),
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 50)),

        // ── User Identity Info ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF0284C7)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(phone, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ptColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: ptColor.withAlpha(50)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(ptIcon, size: 13, color: ptColor),
                                const SizedBox(width: 5),
                                Text(ptLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ptColor)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF059669)),
                                SizedBox(width: 4),
                                Text('e-KYC Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                              ],
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

        const SliverToBoxAdapter(child: SizedBox(height: 18)),

        // ── Primary Essential Card: Overview & View Full Details Button ───────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.badge_rounded, color: AppTheme.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Summary',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Essential identity & eligibility criteria',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(state, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),

                  // Quick snippet chips
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryPill(Icons.category_rounded, 'Category', socialCategory),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryPill(Icons.currency_rupee_rounded, 'Annual Income', income),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Profile completion bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scheme Match Readiness: $completionInt%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                      Text(
                        completionInt >= 80 ? '✓ Ready' : 'Incomplete',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: completionInt >= 80 ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: completionPct,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completionInt >= 80 ? const Color(0xFF059669) : const Color(0xFFD97706),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Prominent View Profile Details button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showProfileDetailsModal(
                        context,
                        name: name,
                        phone: phone,
                        dob: dob,
                        gender: gender,
                        state: state,
                        socialCategory: socialCategory,
                        income: income,
                        educationLevel: educationLevel,
                        course: course,
                        institution: institution,
                        employment: employment,
                        profileType: profileType,
                      ),
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('View Full Profile Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Quick Access Tools Grid ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.bolt_rounded, label: 'Services & Tools', color: Color(0xFF2563EB)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BigActionButton(
                        icon: Icons.auto_awesome_rounded,
                        label: 'AI Schemes\nFor You',
                        color: const Color(0xFF7C3AED),
                        onTap: () => context.push('/recommendations'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BigActionButton(
                        icon: Icons.bookmark_rounded,
                        label: 'Saved\nSchemes',
                        color: const Color(0xFF0284C7),
                        onTap: () => context.push('/saved-schemes'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BigActionButton(
                        icon: Icons.folder_open_rounded,
                        label: 'Document\nVault',
                        color: const Color(0xFF059669),
                        onTap: () => context.push('/documents/upload'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Account Settings & Preferences ───────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.settings_rounded, label: 'Account & Settings', color: Color(0xFF475569)),
                const SizedBox(height: 10),
                _PMenuItem(
                  icon: Icons.edit_note_rounded,
                  label: 'Edit Profile Information',
                  subtitle: 'Update qualification, income, address & more',
                  onTap: () => context.push('/profile-form'),
                ),
                _PMenuItem(
                  icon: Icons.tune_rounded,
                  label: 'Switch Citizen Persona',
                  subtitle: 'Current: $ptLabel',
                  onTap: () => context.push('/profile-type'),
                ),
                _PMenuItem(
                  icon: Icons.translate_rounded,
                  label: 'App Language & Voice',
                  subtitle: 'Choose from 16 Indian languages',
                  onTap: () => _showLanguageSelectorModal(context, ref),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Sign Out Button ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── MODAL: Full Detailed Profile View ──────────────────────────────────────
  void _showProfileDetailsModal(
    BuildContext context, {
    required String name,
    required String phone,
    required String dob,
    required String gender,
    required String state,
    required String socialCategory,
    required String income,
    required String educationLevel,
    required String course,
    required String institution,
    required String employment,
    required ProfileType profileType,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.86,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Sheet Handle & Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.account_circle_rounded, color: AppTheme.primaryBlue, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Full Profile & Identification Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Detailed Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Verified ID Badges
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildModalBadge(Icons.fingerprint_rounded, 'Aadhaar e-KYC', 'Verified', const Color(0xFF059669)),
                            Container(width: 1, height: 28, color: const Color(0xFFBFDBFE)),
                            _buildModalBadge(Icons.lock_rounded, 'DigiLocker', 'Linked', const Color(0xFF0284C7)),
                            Container(width: 1, height: 28, color: const Color(0xFFBFDBFE)),
                            _buildModalBadge(Icons.account_balance_rounded, 'DBT Account', 'Active', const Color(0xFF059669)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section 1: Personal & Demographic
                      _InfoCard(
                        header: const _SectionHeader(icon: Icons.person_rounded, label: 'Personal & Demographic', color: Color(0xFF2563EB)),
                        items: [
                          _InfoRow(icon: Icons.badge_outlined, label: 'Full Name', value: name),
                          _InfoRow(icon: Icons.cake_outlined, label: 'Date of Birth', value: dob),
                          _InfoRow(icon: Icons.wc_rounded, label: 'Gender', value: gender),
                          _InfoRow(icon: Icons.location_on_outlined, label: 'State of Domicile', value: state),
                          _InfoRow(icon: Icons.people_outline_rounded, label: 'Social Category', value: socialCategory),
                          _InfoRow(icon: Icons.currency_rupee_rounded, label: 'Annual Family Income', value: income),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Section 2: Education & Occupation
                      _InfoCard(
                        header: const _SectionHeader(icon: Icons.school_rounded, label: 'Academic & Occupation', color: Color(0xFF7C3AED)),
                        items: [
                          _InfoRow(icon: Icons.menu_book_outlined, label: 'Qualification', value: educationLevel),
                          _InfoRow(icon: Icons.work_outline_rounded, label: 'Field / Sector', value: course),
                          _InfoRow(icon: Icons.account_balance_outlined, label: 'Institution / District', value: institution),
                          _InfoRow(icon: Icons.badge_outlined, label: 'Employment Status', value: employment),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Edit button at bottom of sheet
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push('/profile-form');
                          },
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Update Profile Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                            side: const BorderSide(color: AppTheme.primaryBlue),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalBadge(IconData icon, String label, String status, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 2),
        Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  (Color, IconData, String) _profileTypeMeta(ProfileType type) => switch (type) {
    ProfileType.student       => (const Color(0xFF2563EB), Icons.school_rounded, 'Student'),
    ProfileType.farmer        => (const Color(0xFF059669), Icons.agriculture_rounded, 'Farmer'),
    ProfileType.jobSeeker     => (const Color(0xFF7C3AED), Icons.work_rounded, 'Job Seeker'),
    ProfileType.entrepreneur  => (const Color(0xFFD97706), Icons.store_rounded, 'Entrepreneur'),
    ProfileType.womanFamily   => (const Color(0xFFDB2777), Icons.female_rounded, 'Women & Family'),
    ProfileType.seniorCitizen => (const Color(0xFF0EA5E9), Icons.elderly_rounded, 'Senior Citizen'),
    ProfileType.generalCitizen=> (const Color(0xFF475569), Icons.person_rounded, 'General Citizen'),
  };

  String _getDefaultNameForType(ProfileType type) => switch (type) {
    ProfileType.student        => 'Aarav Sharma',
    ProfileType.farmer         => 'Ramesh Chandra Patil',
    ProfileType.jobSeeker      => 'Priya Verma',
    ProfileType.entrepreneur   => 'Vikramaditya Joshi',
    ProfileType.womanFamily    => 'Sunita Devi',
    ProfileType.seniorCitizen  => 'Harishchandra Kulkarni',
    ProfileType.generalCitizen => 'Rajesh Kumar Singh',
  };

  String _getDefaultDobForType(ProfileType type) => switch (type) {
    ProfileType.student        => '15 Jun 2004 (Age 20)',
    ProfileType.farmer         => '12 Apr 1978 (Age 46)',
    ProfileType.jobSeeker      => '20 Sep 2001 (Age 23)',
    ProfileType.entrepreneur   => '05 Nov 1992 (Age 32)',
    ProfileType.womanFamily    => '25 Aug 1986 (Age 38)',
    ProfileType.seniorCitizen  => '10 Mar 1958 (Age 66)',
    ProfileType.generalCitizen => '18 Jan 1985 (Age 39)',
  };

  String _getDefaultEducationForType(ProfileType type) => switch (type) {
    ProfileType.student        => 'Undergraduate (B.Tech)',
    ProfileType.farmer         => 'Class 10 (Secondary)',
    ProfileType.jobSeeker      => 'Undergraduate / ITI',
    ProfileType.entrepreneur   => 'Postgraduate (MBA)',
    ProfileType.womanFamily    => 'Class 12 (Higher Secondary)',
    ProfileType.seniorCitizen  => 'Class 10 (Secondary)',
    ProfileType.generalCitizen => 'Undergraduate',
  };

  String _getDefaultCourseForType(ProfileType type) => switch (type) {
    ProfileType.student        => 'B.Tech Computer Science',
    ProfileType.farmer         => 'Sugarcane & Rice Cultivation',
    ProfileType.jobSeeker      => 'Software & Digital Operations',
    ProfileType.entrepreneur   => 'Micro Retail Enterprise',
    ProfileType.womanFamily    => 'Maternity & Self-Help Group',
    ProfileType.seniorCitizen  => 'Pension Applicant',
    ProfileType.generalCitizen => 'Housing & Subsidy Applicant',
  };

  String _getDefaultInstitutionForType(ProfileType type) => switch (type) {
    ProfileType.student        => 'COEP Technological University',
    ProfileType.farmer         => 'Kolhapur Farm District',
    ProfileType.jobSeeker      => 'Skill India Center Lucknow',
    ProfileType.entrepreneur   => 'Joshi Green Tech Solutions',
    ProfileType.womanFamily    => 'Nashik Primary Health Center',
    ProfileType.seniorCitizen  => 'Bengaluru Senior Center',
    ProfileType.generalCitizen => 'Central Municipal Ward',
  };

  String _getDefaultEmploymentForType(ProfileType type) => switch (type) {
    ProfileType.student        => 'Full-Time Student',
    ProfileType.farmer         => 'Small & Marginal Farmer',
    ProfileType.jobSeeker      => 'Seeking Employment',
    ProfileType.entrepreneur   => 'Self-Employed Business Owner',
    ProfileType.womanFamily    => 'Self-Help Group Member',
    ProfileType.seniorCitizen  => 'Retired — Unorganized Sector',
    ProfileType.generalCitizen => 'Part-Time / Self-Employed',
  };
}

// ── Shared Profile Widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Text(label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
    ]);
  }
}

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BigActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, height: 1.3)),
          ]),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget header;
  final List<_InfoRow> items;
  const _InfoCard({required this.header, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: List.generate(items.length, (i) => Column(
              children: [
                items[i],
                if (i < items.length - 1) const Divider(height: 1, indent: 52, endIndent: 16),
              ],
            )),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.3)),
            const SizedBox(height: 3),
            Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ]),
        ),
      ]),
    );
  }
}

class _PMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _PMenuItem({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.primaryBlue;
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
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ])),
              Icon(Icons.chevron_right_rounded, size: 22, color: Colors.grey.shade400),
            ]),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// SHARED: SCHEME CARD
// ─────────────────────────────────────────────────────────────────────────────

ProfileType _detectSchemeTargetType(SchemeModel scheme) {
  final text = '${scheme.title} ${scheme.shortDescription} ${scheme.benefitSummary} ${scheme.provider}'.toLowerCase();

  if (text.contains('kisan') ||
      text.contains('fasal') ||
      text.contains('bima') ||
      text.contains('raitha') ||
      text.contains('crop') ||
      text.contains('farm') ||
      text.contains('agri')) {
    return ProfileType.farmer;
  }
  if (text.contains('mudra') ||
      text.contains('svanidhi') ||
      text.contains('pmegp') ||
      text.contains('business') ||
      text.contains('enterprise') ||
      text.contains('msme') ||
      text.contains('loan')) {
    return ProfileType.entrepreneur;
  }
  if (text.contains('scholarship') ||
      text.contains('mysy') ||
      text.contains('vidya') ||
      text.contains('student') ||
      text.contains('college') ||
      text.contains('post matric') ||
      text.contains('internship')) {
    return ProfileType.student;
  }
  if (text.contains('pudhumai') ||
      text.contains('ladki') ||
      text.contains('bahin') ||
      text.contains('gruha') ||
      text.contains('lakshmi') ||
      text.contains('sumangala') ||
      text.contains('sukanya') ||
      text.contains('matru') ||
      text.contains('women') ||
      text.contains('female') ||
      text.contains('girl')) {
    return ProfileType.womanFamily;
  }
  if (text.contains('pension') ||
      text.contains('apy') ||
      text.contains('ignoaps') ||
      text.contains('senior') ||
      text.contains('scss') ||
      text.contains('old age')) {
    return ProfileType.seniorCitizen;
  }
  if (text.contains('kaushal') ||
      text.contains('pmkvy') ||
      text.contains('naps') ||
      text.contains('skill') ||
      text.contains('apprentice') ||
      text.contains('worker') ||
      text.contains('job')) {
    return ProfileType.jobSeeker;
  }
  return ProfileType.generalCitizen;
}

class _SchemeCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isCentral = scheme.jurisdiction.toLowerCase() == 'central';
    final schemeTheme = SchemeImageHelper.getSchemeTheme(title: scheme.title, category: selectedSector);

    final userProfileType = ref.watch(selectedProfileTypeProvider);
    final schemeTargetType = _detectSchemeTargetType(scheme);
    final isProfileMismatch = (userProfileType != schemeTargetType && schemeTargetType != ProfileType.generalCitizen);
    final mismatchReason = isProfileMismatch ? userProfileType.getIneligibilityReason(schemeTargetType) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isProfileMismatch ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isProfileMismatch ? 1.5 : 1.0,
        ),
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
                        isCentral ? 'Central Government' : 'State — ${scheme.state ?? selectedState}',
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFFDE68A))),
                          child: Text(scheme.benefitType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                        ),
                        const Spacer(),
                        if (isProfileMismatch)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cancel_rounded, size: 12, color: Color(0xFFDC2626)),
                                const SizedBox(width: 4),
                                Text(
                                  'Ineligible (${userProfileType == ProfileType.student ? 'Student' : userProfileType.displayName})',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                      ],
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
                    if (isProfileMismatch) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ineligibility Reason: $mismatchReason',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF991B1B), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isProfileMismatch ? const Color(0xFFDC2626) : AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          visualDensity: VisualDensity.compact,
                          minimumSize: Size.zero,
                        ),
                        child: Text(isProfileMismatch ? 'View Reason' : 'Details', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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
