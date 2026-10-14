import 'package:flutter/material.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';

class RatingBarWidget extends StatelessWidget {
  final int score;
  final double percentage;
  const RatingBarWidget(
      {required this.score, required this.percentage, super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$score',
          style: AppTextStyles.body.copyWith(color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 38,
          alignment: Alignment.centerRight,
          child: Text(
            '${percentage.toInt()}%',
            style: AppTextStyles.body.copyWith(
                color: Theme.of(context).colorScheme.tertiary),
          ),
        ),
      ],
    );
  }
}
