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

// ── Main shell with bottom navigation ─────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  void _navigateTo(int index) => setState(() => _currentIndex = index);

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
          _SchemesTab(),
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
  final void Function(int) onNavigate;
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
                  onTap: () => widget.onNavigate(1),
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
                                        isSpeakingThis ? 'रोकें' : 'सुनें',
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
                                            isSpeakingThis ? 'रोकें' : 'सुनें',
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
                label: const Text('सुनें (Listen)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
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
    final userEmail = 'user@schemora.gov.in';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'My Profile & Identity',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue),
            tooltip: 'Edit Profile Details',
            onPressed: () => context.push('/profile-form'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildProfileBody(context, ref, null, profileType, userPhone, userEmail),
        data: (profile) => _buildProfileBody(context, ref, profile, profileType, userPhone, userEmail),
      ),
    );
  }

  Widget _buildProfileBody(
    BuildContext context,
    WidgetRef ref,
    ProfileModel? profile,
    ProfileType profileType,
    String phone,
    String email,
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
        : '₹2,50,000 / annum';

    final educationLevel = profile?.educationLevel ?? _getDefaultEducationForType(profileType);
    final course = profile?.courseName ?? _getDefaultCourseForType(profileType);
    final institution = profile?.institutionName ?? _getDefaultInstitutionForType(profileType);
    final employment = profile?.employmentStatus ?? _getDefaultEmploymentForType(profileType);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── SECTION 1: ACCOUNT HEADER CARD ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(80), width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 34),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Mobile: $phone',
                            style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user_rounded, color: Color(0xFF38BDF8), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  profileType.displayName,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      tooltip: 'Edit Profile',
                      onPressed: () => context.push('/profile-form'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeaderBadge(Icons.fingerprint_rounded, 'Aadhaar e-KYC', 'Verified'),
                    _buildHeaderBadge(Icons.lock_rounded, 'DigiLocker', 'Linked'),
                    _buildHeaderBadge(Icons.account_balance_rounded, 'DBT Account', 'Active'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── SECTION 2: PERSONAL & DEMOGRAPHIC DETAILS (SHOWN SEPARATELY) ────
          _buildSectionTitle('PERSONAL & DEMOGRAPHIC DETAILS', Icons.badge_rounded, const Color(0xFF2563EB)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                _buildDetailRow(Icons.person_outline_rounded, 'Full Name', name),
                const Divider(height: 1, indent: 48),
                _buildDetailRow(Icons.cake_outlined, 'Date of Birth', dob),
                const Divider(height: 1, indent: 48),
                _buildDetailRow(Icons.wc_rounded, 'Gender', gender),
                const Divider(height: 1, indent: 48),
                _buildDetailRow(Icons.location_on_outlined, 'Home State', state),
                const Divider(height: 1, indent: 48),
                _buildDetailRow(Icons.people_outline_rounded, 'Social Category', socialCategory),
                const Divider(height: 1, indent: 48),
                _buildDetailRow(Icons.currency_rupee_rounded, 'Annual Family Income', income),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── SECTION 3: ACADEMIC & CAREER BACKGROUND (SHOWN SEPARATELY) ──────
          _buildSectionTitle('ACADEMIC & OCCUPATIONAL DETAILS', Icons.school_rounded, const Color(0xFF7C3AED)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                _buildDetailRow(Icons.menu_book_outlined, 'Education Qualification', educationLevel),
                const Divider(height: 1, indent: 48),
                _buildDetailRow(Icons.edit_note_rounded, 'Course / Sector', course),
                const Divider(height: 1, indent: 48),
                _buildDetailRow(Icons.account_balance_outlined, 'Institution / District', institution),
                const Divider(height: 1, indent: 48),
                _buildDetailRow(Icons.work_outline_rounded, 'Employment Status', employment),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── SECTION 4: VERIFIED DOCUMENTS VAULT SUMMARY (SHOWN SEPARATELY) ──
          _buildSectionTitle('VERIFIED DOCUMENT VAULT', Icons.shield_rounded, const Color(0xFF059669)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                _buildDocVaultItem('Aadhaar Card', '9999_8888_1234', 'Verified', const Color(0xFF059669)),
                const SizedBox(height: 8),
                _buildDocVaultItem('Income Certificate', 'INC-2026-9876', 'Verified', const Color(0xFF059669)),
                const SizedBox(height: 8),
                _buildDocVaultItem('Caste / Category Proof', 'CST-2026-4321', 'Verified', const Color(0xFF059669)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/documents/upload'),
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: const Text('Manage All Documents in Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── SECTION 5: ACCOUNT ACTIONS & NAVIGATION (SHOWN SEPARATELY) ──────
          _buildSectionTitle('QUICK ACTIONS & SETTINGS', Icons.settings_rounded, const Color(0xFF475569)),
          const SizedBox(height: 8),
          _PMenuItem(
            icon: Icons.edit_note_rounded,
            label: 'Edit Profile Information',
            subtitle: 'Update your name, state, income, or course details',
            onTap: () => context.push('/profile-form'),
          ),
          _PMenuItem(
            icon: Icons.tune_rounded,
            label: 'Change Profile Category',
            subtitle: 'Switch between Student, Farmer, Entrepreneur, etc.',
            onTap: () => context.push('/profile-type'),
          ),
          _PMenuItem(
            icon: Icons.bookmark_outline_rounded,
            label: 'Saved Schemes & Tracker',
            subtitle: 'View your bookmarked schemes and application status',
            onTap: () => context.push('/saved-schemes'),
          ),
          _PMenuItem(
            icon: Icons.auto_awesome_rounded,
            label: 'AI Recommendation Engine',
            subtitle: 'See eligible schemes matching your profile',
            onTap: () => context.push('/recommendations'),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          _PMenuItem(
            icon: Icons.logout_rounded,
            label: 'Sign Out Account',
            subtitle: 'Log out safely from this device',
            isDestructive: true,
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.8),
        ),
      ],
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label, String status) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF38BDF8), size: 14),
            const SizedBox(width: 4),
            Text(status, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocVaultItem(String docTitle, String docId, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_rounded, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(docTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text('ID: $docId', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
          ),
        ],
      ),
    );
  }

  String _getDefaultNameForType(ProfileType type) {
    return switch (type) {
      ProfileType.student => 'Aarav Sharma',
      ProfileType.farmer => 'Ramesh Chandra Patil',
      ProfileType.jobSeeker => 'Priya Verma',
      ProfileType.entrepreneur => 'Vikramaditya Joshi',
      ProfileType.womanFamily => 'Sunita Devi',
      ProfileType.seniorCitizen => 'Harishchandra Kulkarni',
      ProfileType.generalCitizen => 'Rajesh Kumar Singh',
    };
  }

  String _getDefaultDobForType(ProfileType type) {
    return switch (type) {
      ProfileType.student => '2004-06-15 (Age: 20)',
      ProfileType.farmer => '1978-04-12 (Age: 46)',
      ProfileType.jobSeeker => '2001-09-20 (Age: 23)',
      ProfileType.entrepreneur => '1992-11-05 (Age: 32)',
      ProfileType.womanFamily => '1986-08-25 (Age: 38)',
      ProfileType.seniorCitizen => '1958-03-10 (Age: 66)',
      ProfileType.generalCitizen => '1985-01-18 (Age: 39)',
    };
  }

  String _getDefaultEducationForType(ProfileType type) {
    return switch (type) {
      ProfileType.student => 'Undergraduate (B.Tech)',
      ProfileType.farmer => 'Class 10 (Secondary)',
      ProfileType.jobSeeker => 'Undergraduate / ITI Apprentice',
      ProfileType.entrepreneur => 'Postgraduate (Management)',
      ProfileType.womanFamily => 'Class 12 (Higher Secondary)',
      ProfileType.seniorCitizen => 'Class 10 (Secondary)',
      ProfileType.generalCitizen => 'Undergraduate',
    };
  }

  String _getDefaultCourseForType(ProfileType type) {
    return switch (type) {
      ProfileType.student => 'B.Tech Computer Science',
      ProfileType.farmer => 'Sugarcane & Rice Cultivation',
      ProfileType.jobSeeker => 'Software & Digital Operations',
      ProfileType.entrepreneur => 'Micro Retail Enterprise',
      ProfileType.womanFamily => 'Maternity & Self-Help Group Aid',
      ProfileType.seniorCitizen => 'Unorganized Pension Applicant',
      ProfileType.generalCitizen => 'Housing & Subsidy Applicant',
    };
  }

  String _getDefaultInstitutionForType(ProfileType type) {
    return switch (type) {
      ProfileType.student => 'COEP Technological University',
      ProfileType.farmer => 'Kolhapur Farm District',
      ProfileType.jobSeeker => 'Skill India Center Lucknow',
      ProfileType.entrepreneur => 'Joshi Green Tech Solutions',
      ProfileType.womanFamily => 'Nashik Primary Health Center',
      ProfileType.seniorCitizen => 'Bengaluru Senior Center',
      ProfileType.generalCitizen => 'Central Municipal Ward',
    };
  }

  String _getDefaultEmploymentForType(ProfileType type) {
    return switch (type) {
      ProfileType.student => 'Full-Time Student',
      ProfileType.farmer => 'Small & Marginal Farmer (Self-Employed)',
      ProfileType.jobSeeker => 'Actively Seeking Employment',
      ProfileType.entrepreneur => 'Self-Employed Business Owner',
      ProfileType.womanFamily => 'Self-Help Group Member',
      ProfileType.seniorCitizen => 'Retired Unorganized Sector',
      ProfileType.generalCitizen => 'Part-Time / Self-Employed',
    };
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

// ─────────────────────────────────────────────────────────────────────────────
// SHARED: SCHEME CARD
// ─────────────────────────────────────────────────────────────────────────────

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
