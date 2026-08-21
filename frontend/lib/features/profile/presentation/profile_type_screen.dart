import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type_provider.dart';

// ─── Data ──────────────────────────────────────────────────────────────────────
class _CardData {
  final ProfileType type;
  final IconData icon;
  final Color color;
  final String badge;
  const _CardData({
    required this.type,
    required this.icon,
    required this.color,
    required this.badge,
  });
}

// ─── Screen ────────────────────────────────────────────────────────────────────
class ProfileTypeScreen extends ConsumerWidget {
  const ProfileTypeScreen({super.key});

  static const _cards = [
    _CardData(
      type: ProfileType.student,
      icon: Icons.school_rounded,
      color: Color(0xFF2563EB),
      badge: 'Scholarships · Education Loans',
    ),
    _CardData(
      type: ProfileType.farmer,
      icon: Icons.agriculture_rounded,
      color: Color(0xFF059669),
      badge: 'Kisan Credit · Crop Insurance',
    ),
    _CardData(
      type: ProfileType.jobSeeker,
      icon: Icons.work_rounded,
      color: Color(0xFFEA580C),
      badge: 'Skill Training · Employment',
    ),
    _CardData(
      type: ProfileType.entrepreneur,
      icon: Icons.store_rounded,
      color: Color(0xFF7C3AED),
      badge: 'MSME Loans · Startup Grants',
    ),
    _CardData(
      type: ProfileType.womanFamily,
      icon: Icons.favorite_rounded,
      color: Color(0xFFDB2777),
      badge: 'Women Welfare · Maternity',
    ),
    _CardData(
      type: ProfileType.seniorCitizen,
      icon: Icons.elderly_rounded,
      color: Color(0xFF0891B2),
      badge: 'Pension · Healthcare Benefits',
    ),
    _CardData(
      type: ProfileType.generalCitizen,
      icon: Icons.home_rounded,
      color: Color(0xFF4F46E5),
      badge: 'Housing · Ration · Utilities',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Choose Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: const [DashboardButton()],
      ),
      body: Column(
        children: [
          // ── Header Card ──────────────────────────────────────────────────
          _buildHeader(),

          // ── Section Label ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Row(
              children: [
                Text(
                  'SELECT YOUR CATEGORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
              ],
            ),
          ),

          // ── Cards ────────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: _cards.length,
              itemBuilder: (context, i) => _ProfileCard(
                data: _cards[i],
                index: i,
                onTap: () {
                  ref.read(selectedProfileTypeProvider.notifier).state =
                      _cards[i].type;
                  context.go('/profile-form');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withAlpha(55),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFFBBF24), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personalise your experience',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pick the profile that fits you best to discover relevant government schemes.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(185),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Widget ────────────────────────────────────────────────────────────────
class _ProfileCard extends StatefulWidget {
  final _CardData data;
  final int index;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.data,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.data.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: GestureDetector(
          onTapDown: (_) => _ctrl.forward(),
          onTapUp: (_) {
            _ctrl.reverse();
            widget.onTap();
          },
          onTapCancel: () => _ctrl.reverse(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Left accent column ──────────────────────────────────
                Container(
                  width: 5,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ── Icon box ────────────────────────────────────────────
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(widget.data.icon, color: c, size: 22),
                  ),
                ),

                const SizedBox(width: 12),

                // ── Text block ──────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data.type.displayName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryNavy,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.data.badge,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: c,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Arrow ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                    size: 22,
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
