import 'package:flutter/material.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';

class SchemeCard extends StatelessWidget {
  final SchemeModel scheme;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback? onBookmarkTap;

  const SchemeCard({
    super.key,
    required this.scheme,
    this.isSaved = false,
    required this.onTap,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCentral = scheme.jurisdiction.toLowerCase() == 'central';
    final tagBg = isCentral ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4);
    final tagColor = isCentral ? AppTheme.primaryBlue : AppTheme.successGreen;
    final tagBorder = isCentral ? const Color(0xFFBFDBFE) : const Color(0xFFBBF7D0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor, width: 1.2),
        boxShadow: AppTheme.boxShadowSoft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title and Bookmark
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        scheme.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppTheme.primaryNavy,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onBookmarkTap != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onBookmarkTap,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSaved ? AppTheme.warningOrange.withAlpha(20) : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: isSaved ? AppTheme.warningOrange : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 6),

                // Description
                Text(
                  scheme.shortDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Bottom row: Jurisdiction Tag, Provider, Arrow
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tagBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCentral ? Icons.account_balance_rounded : Icons.location_city_rounded,
                            size: 13,
                            color: tagColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            scheme.jurisdiction,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: tagColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        scheme.provider,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withAlpha(15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: AppTheme.primaryBlue,
                      ),
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
