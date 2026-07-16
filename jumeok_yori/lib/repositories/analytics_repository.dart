import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 사장님 대시보드용 집계 통계. 개인정보(이메일/user_id)는 노출하지 않고
/// 집계된 카운트만 반환합니다.
class DashboardStats {
  final int todayDrawCount;
  final int totalDrawCount;
  final int todayRestaurantViews;
  final int totalRestaurantViews;
  final int todayDirectionClicks;
  final int totalDirectionClicks;
  final int savedCount;
  final int sharedCount;
  final int reportCount;
  final int totalMenuCount;
  final int visibleMenuCount;

  const DashboardStats({
    this.todayDrawCount = 0,
    this.totalDrawCount = 0,
    this.todayRestaurantViews = 0,
    this.totalRestaurantViews = 0,
    this.todayDirectionClicks = 0,
    this.totalDirectionClicks = 0,
    this.savedCount = 0,
    this.sharedCount = 0,
    this.reportCount = 0,
    this.totalMenuCount = 0,
    this.visibleMenuCount = 0,
  });
}

class AnalyticsRepository {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<int> _countEvents({
    required String ownerId,
    required String eventType,
    bool todayOnly = false,
  }) async {
    try {
      var query = _client!
          .from('analytics_events')
          .select()
          .eq('owner_id', ownerId)
          .eq('event_type', eventType);
      if (todayOnly) {
        final today = DateTime.now();
        final start =
            DateTime(today.year, today.month, today.day).toIso8601String();
        query = query.gte('created_at', start);
      }
      final res = await query;
      return (res as List).length;
    } catch (e) {
      debugPrint('Analytics count failed: $e');
      return 0;
    }
  }

  Future<int> _countMenus(String ownerId, {bool visibleOnly = false}) async {
    try {
      var query =
          _client!.from('menu_items').select().eq('owner_id', ownerId);
      if (visibleOnly) {
        query =
            query.eq('display_status', 'approved').eq('is_available', true);
      }
      final res = await query;
      return (res as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<DashboardStats> getOwnerDashboardStats(String ownerId) async {
    if (_client == null) return const DashboardStats();
    try {
      final results = await Future.wait([
        _countEvents(
            ownerId: ownerId,
            eventType: 'recommendation_drawn',
            todayOnly: true),
        _countEvents(ownerId: ownerId, eventType: 'recommendation_drawn'),
        _countEvents(
            ownerId: ownerId, eventType: 'restaurant_viewed', todayOnly: true),
        _countEvents(ownerId: ownerId, eventType: 'restaurant_viewed'),
        _countEvents(
            ownerId: ownerId, eventType: 'direction_clicked', todayOnly: true),
        _countEvents(ownerId: ownerId, eventType: 'direction_clicked'),
        _countEvents(ownerId: ownerId, eventType: 'saved'),
        _countEvents(ownerId: ownerId, eventType: 'shared'),
        _countEvents(ownerId: ownerId, eventType: 'reported'),
        _countMenus(ownerId),
        _countMenus(ownerId, visibleOnly: true),
      ]);
      return DashboardStats(
        todayDrawCount: results[0],
        totalDrawCount: results[1],
        todayRestaurantViews: results[2],
        totalRestaurantViews: results[3],
        todayDirectionClicks: results[4],
        totalDirectionClicks: results[5],
        savedCount: results[6],
        sharedCount: results[7],
        reportCount: results[8],
        totalMenuCount: results[9],
        visibleMenuCount: results[10],
      );
    } catch (e) {
      debugPrint('Dashboard stats failed: $e');
      return const DashboardStats();
    }
  }
}
