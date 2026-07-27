import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recommendation_result.dart';
import '../config/app_config.dart';
import 'analytics_service.dart';

/// 추천 결과를 텍스트로 공유합니다.
class ShareService {
  // 연속 탭으로 시스템 공유 시트가 중복으로 뜨는 것을 막기 위한 가드.
  // 네이티브 공유 시트 자체가 모달이라 실질적 위험은 낮지만, 시트가 뜨기
  // 전(딜레이가 있는 일부 기기)의 짧은 틈에 두 번 눌리는 것을 막는다.
  static bool _sharing = false;

  static Future<void> shareRecommendation(
    BuildContext context,
    RecommendationResult result,
  ) async {
    if (!AppConfig.enableShare || _sharing) return;
    _sharing = true;
    try {
      final text = _buildShareText(result);
      // iPad/Mac 에서는 sharePositionOrigin 이 없으면 공유 시트가 뜨지 않거나
      // 위치를 잡지 못해 아무 반응이 없는 것처럼 보일 수 있다. 화면 전체를
      // origin 으로 넘겨 항상 안전하게 표시되도록 한다(다른 기기에는 영향 없음).
      final size = MediaQuery.of(context).size;
      await Share.share(text, sharePositionOrigin: Offset.zero & size);
      // 공유 로그는 실패해도 공유 자체의 성공 여부에 영향을 주지 않는다.
      unawaited(
        AnalyticsService.log(
          eventType: 'shared',
          restaurantId: result.restaurant?.id,
          ownerId: result.restaurant?.ownerId,
          menuItemId: result.menuItem?.id,
          starterMenuId: result.starterMenu?.id,
          recommendationType: result.type,
        ),
      );
    } catch (e) {
      debugPrint('[SHARE] 공유 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유 창을 열지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      _sharing = false;
    }
  }

  static String _buildShareText(RecommendationResult result) {
    if (result.isRegistered && result.menuItem != null) {
      final item = result.menuItem!;
      final restaurant = result.restaurant;
      final restaurantLine = (restaurant != null && restaurant.name.isNotEmpty)
          ? '${restaurant.name}의 '
          : '';
      return '주먹요리가 골라준 오늘의 메뉴: $restaurantLine${item.name}\n'
          '가격: ${item.priceText}\n'
          '오늘 뭐 먹을지 고민될 때 주먹요리에서 메뉴를 추천받아 보세요.';
    } else if (result.starterMenu != null) {
      return '주먹요리가 골라준 오늘의 메뉴: ${result.starterMenu!.name}\n'
          '근처에서 이 메뉴를 찾아보세요.\n'
          '오늘 뭐 먹을지 고민될 때 주먹요리에서 메뉴를 추천받아 보세요.';
    }
    return '주먹요리에서 오늘의 메뉴를 뽑아봐!';
  }
}
