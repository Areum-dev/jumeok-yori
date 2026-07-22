import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/owner_store_application.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';

/// 관리자 전용 데이터 접근 (RLS: is_admin() 통과 필요)
class AdminRepository {
  SupabaseClient get _client => Supabase.instance.client;

  // ── 가게 신청 ──
  Future<List<OwnerStoreApplication>> fetchPendingApplications() async {
    final res = await _client
        .from('owner_store_applications')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (res as List<dynamic>)
        .map((r) => OwnerStoreApplication.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// 신청 승인 → restaurants 생성 + owner role 부여 + 신청서 업데이트
  /// [lat]/[lng] 이 있으면 주먹지도에 표시되도록 함께 저장합니다.
  Future<void> approveApplication(
    OwnerStoreApplication app, {
    double? lat,
    double? lng,
  }) async {
    // 전달된 좌표 우선, 없으면 신청서에 저장된 (자동 지오코딩) 좌표 사용
    final finalLat = lat ?? app.lat;
    final finalLng = lng ?? app.lng;

    final restaurantData = <String, dynamic>{
      'owner_id': app.userId,
      'business_number': app.businessNumber,
      'name': app.storeName,
      'owner_name': app.ownerName,
      'phone': app.phone,
      'address': app.address,
      'detail_address': app.detailAddress,
      'category': app.category,
      'description': app.description,
      'opening_hours': app.openingHours,
      'is_takeout_available': app.isTakeoutAvailable,
      'is_delivery_available': app.isDeliveryAvailable,
      'source': 'owner_registered',
      'verification_status': 'approved',
      'display_status': 'approved',
      if (finalLat != null && finalLat != 0) 'lat': finalLat,
      if (finalLng != null && finalLng != 0) 'lng': finalLng,
    };

    String? restaurantId = app.restaurantId;
    if (restaurantId != null) {
      await _client
          .from('restaurants')
          .update(restaurantData)
          .eq('id', restaurantId);
    } else {
      final inserted = await _client
          .from('restaurants')
          .insert(restaurantData)
          .select()
          .single();
      restaurantId = inserted['id'] as String;
    }

    await _client
        .from('owner_store_applications')
        .update({
          'status': 'approved',
          'restaurant_id': restaurantId,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', app.id);

    await _client
        .from('profiles')
        .update({'role': 'owner'})
        .eq('id', app.userId);
  }

  Future<void> rejectApplication(String applicationId, String note) async {
    await _client
        .from('owner_store_applications')
        .update({
          'status': 'rejected',
          'admin_note': note,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', applicationId);
  }

  // ── 메뉴 신청 ──
  Future<List<MenuItem>> fetchPendingMenus() async {
    final res = await _client
        .from('menu_items')
        .select('*, restaurants(*)')
        .eq('approval_status', 'pending')
        .order('created_at', ascending: false);
    return (res as List<dynamic>).map((row) {
      final map = row as Map<String, dynamic>;
      final rMap = map['restaurants'] as Map<String, dynamic>?;
      final restaurant = rMap != null ? Restaurant.fromJson(rMap) : null;
      return MenuItem.fromJson(map, restaurant: restaurant);
    }).toList();
  }

  Future<void> approveMenu(String menuId) async {
    await _client
        .from('menu_items')
        .update({
          'approval_status': 'approved',
          'display_status': 'approved',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', menuId);
  }

  Future<void> rejectMenu(String menuId, String note) async {
    await _client
        .from('menu_items')
        .update({
          'approval_status': 'rejected',
          'display_status': 'hidden',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', menuId);
  }

  // ── 신고 목록 ──
  Future<List<Map<String, dynamic>>> fetchReports() async {
    final res = await _client
        .from('reports')
        .select()
        .order('created_at', ascending: false);
    return (res as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await _client.from('reports').update({'status': status}).eq('id', reportId);
  }

  // ── 등록된 가게 ──
  Future<List<Restaurant>> fetchAllRestaurants() async {
    final res = await _client
        .from('restaurants')
        .select()
        .order('created_at', ascending: false);
    return (res as List<dynamic>)
        .map((r) => Restaurant.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
