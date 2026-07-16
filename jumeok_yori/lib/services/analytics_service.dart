import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// analytics_events 테이블에 이벤트를 기록합니다.
/// 실패해도 앱 흐름에 영향을 주지 않도록 모두 try/catch 처리합니다.
class AnalyticsService {
  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<void> log({
    required String eventType,
    String? userId,
    String? anonymousUserId,
    String? ownerId,
    String? restaurantId,
    String? menuItemId,
    String? starterMenuId,
    String? recommendationType,
    Map<String, dynamic>? metadata,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    try {
      final payload = <String, dynamic>{'event_type': eventType};
      if (userId != null) payload['user_id'] = userId;
      if (anonymousUserId != null) {
        payload['anonymous_user_id'] = anonymousUserId;
      }
      if (ownerId != null) payload['owner_id'] = ownerId;
      if (restaurantId != null) payload['restaurant_id'] = restaurantId;
      if (menuItemId != null) payload['menu_item_id'] = menuItemId;
      if (starterMenuId != null) payload['starter_menu_id'] = starterMenuId;
      if (recommendationType != null) {
        payload['recommendation_type'] = recommendationType;
      }
      if (metadata != null) payload['metadata'] = metadata;
      await _client?.from('analytics_events').insert(payload);
    } catch (e) {
      debugPrint('Analytics log failed ($eventType): $e');
    }
  }
}
