import 'package:flutter/material.dart';

/// Theme data for a scheme card — gradient colors, icon, and category label.
class SchemeTheme {
  final List<Color> gradient;
  final IconData icon;
  final String label;

  const SchemeTheme({
    required this.gradient,
    required this.icon,
    required this.label,
  });
}

/// Maps a scheme's title/category to a professional [SchemeTheme].
/// No cartoonish images — clean icon + gradient design system.
class SchemeImageHelper {
  static SchemeTheme getSchemeTheme({required String title, String? category}) {
    final t = title.toLowerCase();
    final c = (category ?? '').toLowerCase();

    if (t.contains('kisan') ||
        t.contains('fasal') ||
        t.contains('crop') ||
        t.contains('farm') ||
        c.contains('agri')) {
      return const SchemeTheme(
        gradient: [Color(0xFF059669), Color(0xFF047857)],
        icon: Icons.agriculture_rounded,
        label: 'Agriculture',
      );
    } else if (t.contains('scholarship') ||
        t.contains('education') ||
        t.contains('post matric') ||
        t.contains('college') ||
        t.contains('mysy') ||
        c.contains('scholar') ||
        c.contains('edu')) {
      return const SchemeTheme(
        gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        icon: Icons.school_rounded,
        label: 'Education',
      );
    } else if (t.contains('mudra') ||
        t.contains('loan') ||
        t.contains('msme') ||
        t.contains('business') ||
        t.contains('vendor') ||
        t.contains('svanidhi') ||
        c.contains('entrepreneur') ||
        c.contains('business')) {
      return const SchemeTheme(
        gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        icon: Icons.store_rounded,
        label: 'MSME & Business',
      );
    } else if (t.contains('woman') ||
        t.contains('women') ||
        t.contains('ladki') ||
        t.contains('kanya') ||
        t.contains('lakshmi') ||
        t.contains('matru') ||
        c.contains('women')) {
      return const SchemeTheme(
        gradient: [Color(0xFFDB2777), Color(0xFFBE185D)],
        icon: Icons.favorite_rounded,
        label: 'Women & Family',
      );
    } else if (t.contains('pension') ||
        t.contains('senior') ||
        t.contains('atal') ||
        t.contains('old age') ||
        t.contains('apy') ||
        c.contains('pension') ||
        c.contains('senior')) {
      return const SchemeTheme(
        gradient: [Color(0xFF0891B2), Color(0xFF0E7490)],
        icon: Icons.elderly_rounded,
        label: 'Senior & Pension',
      );
    } else if (t.contains('awas') ||
        t.contains('housing') ||
        t.contains('house') ||
        c.contains('housing')) {
      return const SchemeTheme(
        gradient: [Color(0xFF4F46E5), Color(0xFF3730A3)],
        icon: Icons.home_rounded,
        label: 'Housing',
      );
    } else if (t.contains('ayushman') ||
        t.contains('health') ||
        t.contains('medical') ||
        t.contains('bima') ||
        c.contains('health')) {
      return const SchemeTheme(
        gradient: [Color(0xFF16A34A), Color(0xFF15803D)],
        icon: Icons.local_hospital_rounded,
        label: 'Health & Insurance',
      );
    } else if (t.contains('skill') ||
        t.contains('rozgar') ||
        t.contains('employment') ||
        t.contains('pmkvy') ||
        c.contains('skill')) {
      return const SchemeTheme(
        gradient: [Color(0xFFEA580C), Color(0xFFC2410C)],
        icon: Icons.work_rounded,
        label: 'Skill & Employment',
      );
    }

    return const SchemeTheme(
      gradient: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
      icon: Icons.account_balance_rounded,
      label: 'Government Scheme',
    );
  }

  // Legacy compatibility — not used by dashboard
  static String getSchemeImage({required String title, String? category}) {
    return 'assets/images/schemora_hero.png';
  }
}
