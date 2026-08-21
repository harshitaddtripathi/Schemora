import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type_provider.dart';

class ProfileTypeScreen extends ConsumerWidget {
  const ProfileTypeScreen({super.key});

  static const List<_ProfileCard> _cards = [
    _ProfileCard(
      type: ProfileType.student,
      icon: Icons.school_rounded,
      gradient: [Color(0xFF2563EB), Color(0xFF4F46E5)],
      imageAsset: 'assets/images/scholarship_card.png',
    ),
    _ProfileCard(
      type: ProfileType.farmer,
      icon: Icons.agriculture_rounded,
      gradient: [Color(0xFF16A34A), Color(0xFF15803D)],
      imageAsset: 'assets/images/agriculture_card.png',
    ),
    _ProfileCard(
      type: ProfileType.jobSeeker,
      icon: Icons.work_rounded,
      gradient: [Color(0xFFD97706), Color(0xFFB45309)],
      imageAsset: 'assets/images/scholarship_card.png',
    ),
    _ProfileCard(
      type: ProfileType.entrepreneur,
      icon: Icons.store_rounded,
      gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
      imageAsset: 'assets/images/business_card.png',
    ),
    _ProfileCard(
      type: ProfileType.womanFamily,
      icon: Icons.female_rounded,
      gradient: [Color(0xFFDB2777), Color(0xFFBE185D)],
      imageAsset: 'assets/images/women_card.png',
    ),
    _ProfileCard(
      type: ProfileType.seniorCitizen,
      icon: Icons.elderly_rounded,
      gradient: [Color(0xFF0891B2), Color(0xFF0E7490)],
      imageAsset: 'assets/images/pension_card.png',
    ),
    _ProfileCard(
      type: ProfileType.generalCitizen,
      icon: Icons.person_rounded,
      gradient: [Color(0xFF475569), Color(0xFF1E293B)],
      imageAsset: 'assets/images/housing_card.png',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Category'),
        centerTitle: true,
        actions: const [
          DashboardButton(),
        ],
      ),
      backgroundColor: AppTheme.surfaceLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Choose Profile Category',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryNavy),
                            ),
                            Text(
                              'Tailors deterministic schemes & AI matches',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.76,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final card = _cards[index];
                    return _ProfileTypeCard(
                      card: card,
                      onTap: () => _onSelect(context, ref, card.type),
                    );
                  },
                  childCount: _cards.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSelect(BuildContext context, WidgetRef ref, ProfileType type) {
    ref.read(selectedProfileTypeProvider.notifier).state = type;
    context.go('/profile-form');
  }
}

class _ProfileCard {
  final ProfileType type;
  final IconData icon;
  final List<Color> gradient;
  final String imageAsset;

  const _ProfileCard({
    required this.type,
    required this.icon,
    required this.gradient,
    required this.imageAsset,
  });
}

class _ProfileTypeCard extends StatefulWidget {
  final _ProfileCard card;
  final VoidCallback onTap;

  const _ProfileTypeCard({required this.card, required this.onTap});

  @override
  State<_ProfileTypeCard> createState() => _ProfileTypeCardState();
}

class _ProfileTypeCardState extends State<_ProfileTypeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (ctx, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: widget.card.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.card.gradient.first.withAlpha(80),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Visual Background Image
                Positioned.fill(
                  child: Image.asset(
                    widget.card.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),

                // Dark Gradient Overlay for legible contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.card.gradient.first.withAlpha(210),
                          widget.card.gradient.last.withAlpha(240),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Content Column
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(45),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(widget.card.icon, color: Colors.white, size: 22),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        widget.card.type.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.card.type.subtitle,
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 11,
                          height: 1.3,
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
        ),
      ),
    );
  }
}

