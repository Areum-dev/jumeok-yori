import 'package:flutter/material.dart';
import '../models/recommendation_result.dart';
import '../theme/app_theme.dart';

/// 저장/기록 목록용 RecommendationResult 요약 카드
class ResultSummaryCard extends StatelessWidget {
  final RecommendationResult result;
  final VoidCallback? onTap;

  const ResultSummaryCard({super.key, required this.result, this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = result.restaurant;
    final priceText = result.isRegistered
        ? result.menuItem!.priceText
        : (result.starterMenu?.priceRangeText ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.softGray),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: result.isStarter
                    ? AppColors.softGray
                    : AppColors.orangeLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                result.isStarter ? '추천' : '등록',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: result.isStarter
                      ? AppColors.textGray
                      : AppColors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.menuName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (r != null) r.name,
                      result.category,
                      priceText,
                    ].where((e) => e.isNotEmpty).join(' · '),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.midGray),
          ],
        ),
      ),
    );
  }
}
