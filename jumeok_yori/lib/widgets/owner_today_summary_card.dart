import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/analytics_repository.dart';

class OwnerTodaySummaryCard extends StatelessWidget {
  final DashboardStats stats;

  const OwnerTodaySummaryCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final todayDraw = stats.todayDrawCount;
    final todayDirection = stats.todayDirectionClicks;
    final todaySaved = stats.savedCount;

    String message;
    if (todayDraw == 0 && todayDirection == 0) {
      message = '아직 데이터가 없어요.\n메뉴가 뽑히면 이곳에 기록됩니다.';
    } else {
      final parts = <String>[];
      if (todayDraw > 0) parts.add('오늘 내 가게 메뉴가 $todayDraw번 뽑혔어요.');
      if (todayDirection > 0 || todaySaved > 0) {
        final sub = <String>[];
        if (todayDirection > 0) sub.add('길찾기 $todayDirection회');
        if (todaySaved > 0) sub.add('저장 $todaySaved회');
        parts.add('${sub.join(', ')}이 발생했어요.');
      }
      message = parts.join('\n');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.12),
            AppColors.orange.withValues(alpha: 0.04),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('✊', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: AppColors.darkInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
