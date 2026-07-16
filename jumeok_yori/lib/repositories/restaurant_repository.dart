import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant.dart';
import '../models/owner_store_application.dart';

abstract class RestaurantRepository {
  Future<List<Restaurant>> fetchApprovedRestaurants();
  Future<Restaurant?> fetchMyRestaurant(String ownerId);
  Future<void> submitApplication(OwnerStoreApplication application);
  Future<OwnerStoreApplication?> fetchMyApplication(String userId);
}

/// Supabase 미연결 시 사용하는 mock (메모리 저장)
class MockRestaurantRepository implements RestaurantRepository {
  final List<OwnerStoreApplication> _apps = [];

  @override
  Future<List<Restaurant>> fetchApprovedRestaurants() async => [];

  @override
  Future<Restaurant?> fetchMyRestaurant(String ownerId) async => null;

  @override
  Future<void> submitApplication(OwnerStoreApplication application) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _apps.insert(0, application);
  }

  @override
  Future<OwnerStoreApplication?> fetchMyApplication(String userId) async =>
      _apps.where((a) => a.userId == userId).firstOrNull;
}

class SupabaseRestaurantRepository implements RestaurantRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Restaurant>> fetchApprovedRestaurants() async {
    final res = await _client
        .from('restaurants')
        .select()
        .eq('display_status', 'approved');
    return (res as List<dynamic>)
        .map((r) => Restaurant.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Restaurant?> fetchMyRestaurant(String ownerId) async {
    final res = await _client
        .from('restaurants')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (res == null) return null;
    return Restaurant.fromJson(res);
  }

  @override
  Future<void> submitApplication(OwnerStoreApplication application) async {
    await _client
        .from('owner_store_applications')
        .insert(application.toInsertJson());
  }

  @override
  Future<OwnerStoreApplication?> fetchMyApplication(String userId) async {
    final res = await _client
        .from('owner_store_applications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (res == null) return null;
    return OwnerStoreApplication.fromJson(res);
  }
}
