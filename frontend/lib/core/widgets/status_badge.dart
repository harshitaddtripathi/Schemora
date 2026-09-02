import 'package:flutter/material.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';

enum BadgeType {
  ruleMatched,
  needsInformation,
  ineligible,
  drafting,
  underReview,
  approved,
  rejected,
  central,
  state,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  factory StatusBadge.fromEligibilityStatus(String status) {
    switch (status) {
      case 'RuleMatched':
        return const StatusBadge(label: '100% Eligible', type: BadgeType.ruleMatched);
      case 'NeedsInformation':
        return const StatusBadge(label: 'Needs Info', type: BadgeType.needsInformation);
      case 'Ineligible':
      case 'NotMatched':
        return const StatusBadge(label: 'Ineligible', type: BadgeType.ineligible);
      default:
        return StatusBadge(label: status, type: BadgeType.needsInformation);
    }
  }

  factory StatusBadge.fromApplicationStatus(String status) {
    switch (status) {
      case 'Approved':
        return const StatusBadge(label: 'Approved', type: BadgeType.approved);
      case 'UnderReview':
        return const StatusBadge(label: 'Under Review', type: BadgeType.underReview);
      case 'Rejected':
        return const StatusBadge(label: 'Rejected', type: BadgeType.rejected);
      case 'Drafting':
      case 'Saved':
        return const StatusBadge(label: 'Saved / Draft', type: BadgeType.drafting);
      default:
        return StatusBadge(label: status, type: BadgeType.drafting);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    IconData icon;

    switch (type) {
      case BadgeType.ruleMatched:
      case BadgeType.approved:
        bg = const Color(0xFFECFDF5);
        fg = AppTheme.successGreen;
        border = const Color(0xFFA7F3D0);
        icon = Icons.check_circle_rounded;
        break;
      case BadgeType.needsInformation:
      case BadgeType.underReview:
      case BadgeType.drafting:
        bg = const Color(0xFFFFFBEB);
        fg = AppTheme.warningOrange;
        border = const Color(0xFFFDE68A);
        icon = Icons.info_rounded;
        break;
      case BadgeType.ineligible:
      case BadgeType.rejected:
        bg = const Color(0xFFFEF2F2);
        fg = AppTheme.errorRed;
        border = const Color(0xFFFCA5A5);
        icon = Icons.cancel_rounded;
        break;
      case BadgeType.central:
        bg = const Color(0xFFEFF6FF);
        fg = AppTheme.primaryBlue;
        border = const Color(0xFFBFDBFE);
        icon = Icons.account_balance_rounded;
        break;
      case BadgeType.state:
        bg = const Color(0xFFF0FDF4);
        fg = AppTheme.successGreen;
        border = const Color(0xFFBBF7D0);
        icon = Icons.location_city_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
