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
    ),
    _ProfileCard(
      type: ProfileType.farmer,
      icon: Icons.agriculture_rounded,
      gradient: [Color(0xFF16A34A), Color(0xFF15803D)],
    ),
    _ProfileCard(
      type: ProfileType.jobSeeker,
      icon: Icons.work_rounded,
      gradient: [Color(0xFFD97706), Color(0xFFB45309)],
    ),
    _ProfileCard(
      type: ProfileType.entrepreneur,
      icon: Icons.store_rounded,
      gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    ),
    _ProfileCard(
      type: ProfileType.womanFamily,
      icon: Icons.female_rounded,
      gradient: [Color(0xFFDB2777), Color(0xFFBE185D)],
    ),
    _ProfileCard(
      type: ProfileType.seniorCitizen,
      icon: Icons.elderly_rounded,
      gradient: [Color(0xFF0891B2), Color(0xFF0E7490)],
    ),
    _ProfileCard(
      type: ProfileType.generalCitizen,
      icon: Icons.person_rounded,
      gradient: [Color(0xFF64748B), Color(0xFF475569)],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Category'),
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
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'How can Schemora\nhelp you?',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 30,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose the profile that best matches your needs.\nYou can update this anytime.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 28),
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
                  childAspectRatio: 0.92,
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

  const _ProfileCard({
    required this.type,
    required this.icon,
    required this.gradient,
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
                color: widget.card.gradient.first.withAlpha(70),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.card.icon, color: Colors.white, size: 26),
                ),
                const Spacer(),
                Text(
                  widget.card.type.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.card.type.subtitle,
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 11,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
