import 'package:flutter/material.dart';
import '../models/recommendation_result.dart';
import '../theme/app_theme.dart';

/// 마이페이지 "저장한 메뉴" / "추천 기록" 목록 전용 카드.
/// 홈 화면의 간단한 ResultSummaryCard 와 달리 이미지, 날짜, 지도/삭제 액션을
/// 넓게 보여준다 (기존 카드가 화면 아래에 너무 작게 표시되던 문제 대응).
class MyPageEntryCard extends StatelessWidget {
  final RecommendationResult result;
  final VoidCallback? onTap;
  final VoidCallback? onMap;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const MyPageEntryCard({
    super.key,
    required this.result,
    this.onTap,
    this.onMap,
    this.onShare,
    this.onDelete,
  });

  String? get _dateLabel {
    final dt = result.recordedAt;
    if (dt == null) return null;
    final mm = dt.month;
    final dd = dt.day;
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$mm월 $dd일 $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final r = result.restaurant;
    final priceText = result.isRegistered
        ? (result.menuItem?.priceText ?? '')
        : (result.starterMenu?.priceRangeText ?? '');
    final imageUrl = result.imageUrl;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softGray),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.softGray,
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? const Center(
                          child: Text('🍽️', style: TextStyle(fontSize: 28)),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text('🍽️', style: TextStyle(fontSize: 28)),
                          ),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (r != null) r.name,
                        result.category,
                        priceText,
                      ].where((e) => e.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                      ),
                    ),
                    if (_dateLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _dateLabel!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.midGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  if (onMap != null)
                    IconButton(
                      onPressed: onMap,
                      icon: const Icon(
                        Icons.map_outlined,
                        color: AppColors.textGray,
                      ),
                      tooltip: '지도에서 보기',
                      visualDensity: VisualDensity.compact,
                    ),
                  if (onShare != null)
                    IconButton(
                      onPressed: onShare,
                      icon: const Icon(
                        Icons.share_outlined,
                        color: AppColors.textGray,
                      ),
                      tooltip: '공유',
                      visualDensity: VisualDensity.compact,
                    ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.midGray,
                      ),
                      tooltip: '삭제',
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
