import 'package:share_plus/share_plus.dart';
import '../models/recommendation_result.dart';
import '../config/app_config.dart';
import 'analytics_service.dart';

/// 추천 결과를 텍스트로 공유합니다.
class ShareService {
  static Future<void> shareRecommendation(RecommendationResult result) async {
    if (!AppConfig.enableShare) return;
    final text = _buildShareText(result);
    await Share.share(text);
    await AnalyticsService.log(
      eventType: 'shared',
      restaurantId: result.restaurant?.id,
      ownerId: result.restaurant?.ownerId,
      menuItemId: result.menuItem?.id,
      starterMenuId: result.starterMenu?.id,
      recommendationType: result.type,
    );
  }

  static String _buildShareText(RecommendationResult result) {
    if (result.isRegistered && result.menuItem != null) {
      final item = result.menuItem!;
      final restaurant = result.restaurant;
      return '주먹요리가 골라준 오늘의 메뉴: ${restaurant?.name ?? ''}의 ${item.name}\n'
          '가격: ${item.priceText}\n'
          '지금 뭐 먹을지 고민되면 주먹요리에서 뽑아봐.';
    } else if (result.starterMenu != null) {
      return '주먹요리가 골라준 오늘의 메뉴: ${result.starterMenu!.name}\n'
          '근처에서 이 메뉴를 찾아보세요.\n'
          '지금 뭐 먹을지 고민되면 주먹요리에서 뽑아봐.';
    }
    return '주먹요리에서 오늘의 메뉴를 뽑아봐!';
  }
}
