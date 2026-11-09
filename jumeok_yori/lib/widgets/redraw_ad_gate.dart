import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../theme/app_theme.dart';

/// "다시뽑기"를 누르면 먼저 광고 시청 안내를 보여주고, 광고를 끝까지 본 경우에만
/// true 를 돌려준다.
///
/// - 첫 추천은 광고가 없고, 결과 화면의 "다시뽑기"부터 이 함수를 거친다.
/// - 보상형 광고 정책상 사용자가 광고를 보는 것에 먼저 동의하도록 안내 창을 띄운다.
/// - 광고를 불러오지 못한 경우(네트워크 오류, 광고 재고 없음, 웹/미지원 기기)에는
///   사용자를 막지 않고 true 를 돌려준다.
/// - 광고를 중간에 닫으면 false 를 돌려주고 안내 문구를 보여준다.
Future<bool> confirmRedrawWithAd(BuildContext context) async {
  if (!AdService.isSupported) return true;

  final agreed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('다시 뽑기'),
      content: const Text('광고를 끝까지 보면 새 메뉴를 다시 뽑을 수 있어요.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            '광고 보고 다시 뽑기',
            style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
  if (agreed != true || !context.mounted) return false;

  // 광고를 불러오는 동안(최대 몇 초) 화면이 멈춘 것처럼 보이지 않도록 표시.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  final result = await AdService.showRewarded();

  if (!context.mounted) return false;
  Navigator.of(context, rootNavigator: true).pop(); // 로딩 표시 닫기

  switch (result) {
    case RewardedAdResult.completed:
    case RewardedAdResult.unavailable:
      return true;
    case RewardedAdResult.dismissedEarly:
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('광고를 끝까지 봐야 다시 뽑을 수 있어요.')));
      return false;
  }
}
