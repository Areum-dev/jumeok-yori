import 'package:flutter/material.dart';
import '../repositories/analytics_repository.dart';
import '../theme/app_theme.dart';

class OwnerDashboardOverviewCard extends StatelessWidget {
  final DashboardStats stats;
  final VoidCallback onTap;

  const OwnerDashboardOverviewCard({
    super.key,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text(
                  '대시보드',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                const Text(
                  '자세히 보기',
                  style: TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.midGray,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _miniStat(
                  '오늘 뽑힘',
                  '${stats.todayDrawCount}회',
                  Icons.casino_rounded,
                ),
                _divider(),
                _miniStat(
                  '오늘 조회',
                  '${stats.todayRestaurantViews}회',
                  Icons.visibility_outlined,
                ),
                _divider(),
                _miniStat(
                  '길찾기',
                  '${stats.totalDirectionClicks}회',
                  Icons.directions_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 18, color: AppColors.orange),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.darkInk,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textGray),
        ),
      ],
    ),
  );

  Widget _divider() =>
      Container(width: 1, height: 40, color: AppColors.softGray);
}
