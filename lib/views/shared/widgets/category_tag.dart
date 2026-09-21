import 'package:flutter/material.dart';

import '../../../models/debt_model.dart';
import '../category_style.dart';

/// Small `Halal` / `Risiko` pill.
class CategoryTag extends StatelessWidget {
  const CategoryTag({super.key, required this.category});

  final DebtCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          category.shortLabel,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
