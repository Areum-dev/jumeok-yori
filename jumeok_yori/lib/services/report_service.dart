import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'analytics_service.dart';

/// 정보 오류 신고를 Supabase reports 테이블에 저장합니다.
class ReportService {
  static Future<bool> submitReport({
    required String reason,
    String? detail,
    String? menuItemId,
    String? starterMenuId,
    String? restaurantId,
    String? recommendationType,
    String? userId,
    String? anonymousUserId,
  }) async {
    if (!AppConfig.enableReports) return true;
    try {
      final client = Supabase.instance.client;
      await client.from('reports').insert({
        'user_id': userId,
        'anonymous_user_id': anonymousUserId,
        'recommendation_type': recommendationType,
        'menu_item_id': menuItemId,
        'starter_menu_id': starterMenuId,
        'restaurant_id': restaurantId,
        'reason': reason,
        'detail': detail,
        'status': 'pending',
      });
      await AnalyticsService.log(
        eventType: 'reported',
        userId: userId,
        anonymousUserId: anonymousUserId,
        restaurantId: restaurantId,
        menuItemId: menuItemId,
        starterMenuId: starterMenuId,
        recommendationType: recommendationType,
      );
      return true;
    } catch (e) {
      debugPrint('신고 저장 실패: $e');
      return false;
    }
  }
}
