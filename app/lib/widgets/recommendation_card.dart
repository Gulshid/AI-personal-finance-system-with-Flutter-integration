import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/models.dart';

/// A single recommendation from the /user/{id}/recommendations endpoint,
/// styled with the category's color and an icon based on the recommendation
/// type (rising trend, saving tip, etc).
class RecommendationCard extends StatelessWidget {
  final RecommendationItem item;
  const RecommendationCard({super.key, required this.item});

  IconData get _typeIcon {
    switch (item.type) {
      case 'rising_trend':
        return Icons.trending_up_rounded;
      case 'falling_trend':
        return Icons.trending_down_rounded;
      case 'saving_tip':
        return Icons.savings_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(item.category);
    final cardColor = Theme.of(context).cardTheme.color ?? AppTheme.surface;
    final textColor = Theme.of(context).textTheme.titleMedium?.color ?? AppTheme.textPrimary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: style.color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, color: style.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(style.icon, size: 14, color: style.color),
                    const SizedBox(width: 4),
                    Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: style.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.message,
                  style: TextStyle(fontSize: 13.5, color: textColor, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
