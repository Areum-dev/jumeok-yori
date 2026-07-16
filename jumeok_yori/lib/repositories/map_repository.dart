import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';

/// 주먹지도 전용 데이터 접근.
/// 지도에는 승인된(display_status='approved') 가게만 노출됩니다.
/// starter_menu 는 절대 지도에 표시하지 않습니다.
class MapRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// 좌표가 있는 승인 가게만 (지도 마커용)
  Future<List<Restaurant>> getApprovedRestaurantsForMap() async {
    try {
      final res = await _client
          .from('restaurants')
          .select()
          .eq('display_status', 'approved')
          .not('lat', 'is', null)
          .not('lng', 'is', null);
      final all = (res as List<dynamic>)
          .map((r) => Restaurant.fromJson(r as Map<String, dynamic>))
          .toList();
      // verification_status 와 0좌표 필터는 클라이언트에서 처리 (in 쿼리 이슈 회피)
      return all
          .where((r) =>
              (r.verificationStatus == 'approved' ||
                  r.verificationStatus == 'owner_verified') &&
              r.lat != 0 &&
              r.lng != 0)
          .toList();
    } catch (e) {
      debugPrint('지도 가게 로드 실패: $e');
      return [];
    }
  }

  /// 좌표 유무와 관계없이 승인된 모든 가게 (fallback 목록용)
  Future<List<Restaurant>> getAllApprovedRestaurants() async {
    try {
      final res = await _client
          .from('restaurants')
          .select()
          .eq('display_status', 'approved');
      return (res as List<dynamic>)
          .map((r) => Restaurant.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('가게 목록 로드 실패: $e');
      return [];
    }
  }

  Future<Restaurant?> getRestaurantById(String restaurantId) async {
    try {
      final res = await _client
          .from('restaurants')
          .select()
          .eq('id', restaurantId)
          .maybeSingle();
      if (res == null) return null;
      return Restaurant.fromJson(res);
    } catch (e) {
      debugPrint('가게 상세 로드 실패: $e');
      return null;
    }
  }

  /// 현재 사용자(owner_id) 소유 가게 조회. 내 가게 탭에서 사용.
  Future<Restaurant?> getRestaurantByOwnerId(String ownerId) async {
    try {
      final res = await _client
          .from('restaurants')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (res == null) return null;
      return Restaurant.fromJson(res);
    } catch (e) {
      debugPrint('getRestaurantByOwnerId failed: $e');
      return null;
    }
  }

  Future<List<MenuItem>> getApprovedMenusByRestaurant(
      String restaurantId) async {
    try {
      final res = await _client
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('approval_status', 'approved')
          .eq('display_status', 'approved')
          .eq('is_available', true);
      return (res as List<dynamic>)
          .map((r) => MenuItem.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('메뉴 로드 실패: $e');
      return [];
    }
  }

  Future<bool> updateApplicationCoordinates(
      String applicationId, double lat, double lng) async {
    try {
      await _client.from('owner_store_applications').update({
        'lat': lat,
        'lng': lng,
        'geocoding_status': 'success',
      }).eq('id', applicationId);
      return true;
    } catch (e) {
      debugPrint('좌표 업데이트 실패: $e');
      return false;
    }
  }

  Future<bool> updateRestaurantCoordinates(
      String restaurantId, double lat, double lng) async {
    debugPrint('[MapRepo] 좌표 저장 시작: restaurantId=$restaurantId '
        'lat=$lat lng=$lng (WGS84 double)');
    try {
      await _client.from('restaurants').update({
        'lat': lat,
        'lng': lng,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', restaurantId);
      debugPrint('[MapRepo] 좌표 저장 성공: restaurantId=$restaurantId');
      return true;
    } catch (e) {
      debugPrint('[MapRepo] 좌표 저장 실패: restaurantId=$restaurantId error=$e');
      return false;
    }
  }
}
