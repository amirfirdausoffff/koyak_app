import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/percent_formatter.dart';
import '../../../models/category_share.dart';
import '../../shared/category_style.dart';

/// Ranked legend under the chart: icon, name, RM and %.
class CategoryBreakdownList extends StatelessWidget {
  const CategoryBreakdownList({super.key, required this.shares});

  final List<CategoryShare> shares;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, share) in shares.indexed) ...[
          if (index > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(
                  share.category.icon,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(share.category.label)),
                Text(
                  share.amount.asRinggit,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    PercentFormatter.format(share.percentage),
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
