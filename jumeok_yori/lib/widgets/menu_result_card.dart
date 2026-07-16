import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';

class MenuResultCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onTap;
  final bool compact;

  const MenuResultCard({
    super.key,
    required this.item,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = item.restaurant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 뱃지
            Row(
              children: [
                _badge(item.category),
                const Spacer(),
                if (r != null && r.distanceKm != null)
                  Text(
                    r.distanceText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // 메뉴명
            Text(
              item.name,
              style: TextStyle(
                fontSize: compact ? 16 : 20,
                fontWeight: FontWeight.w800,
                color: AppColors.darkInk,
              ),
            ),
            const SizedBox(height: 4),
            // 음식점명
            if (r != null)
              Text(
                r.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 10),
            // 가격 + 도보 시간
            Row(
              children: [
                Text(
                  item.priceText,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
                if (r != null && r.distanceKm != null) ...[
                  const SizedBox(width: 10),
                  const Text(
                    '·',
                    style:
                        TextStyle(color: AppColors.midGray, fontSize: 14),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '도보 ${r.walkingMinutes}분',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ],
            ),
            if (!compact && item.conditionTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.conditionTags
                    .map((tag) => _conditionTag(tag))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.orangeLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.orange,
          ),
        ),
      );

  Widget _conditionTag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.softGray,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textGray,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
