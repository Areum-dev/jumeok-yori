import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../models/starter_menu.dart';
import 'menu_repository.dart';

/// 실제 Supabase DB에서 데이터를 읽는 repository (anon key + RLS)
class SupabaseMenuRepository implements MenuRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<MenuItem>> fetchApprovedMenus() async {
    final res = await _client
        .from('menu_items')
        .select('*, restaurants!inner(*)')
        .eq('approval_status', 'approved')
        .eq('display_status', 'approved')
        .eq('is_available', true);

    final rows = res as List<dynamic>;
    return rows.map((row) {
      final map = row as Map<String, dynamic>;
      final rMap = map['restaurants'] as Map<String, dynamic>?;
      final restaurant = rMap != null ? Restaurant.fromJson(rMap) : null;
      return MenuItem.fromJson(map, restaurant: restaurant);
    }).toList();
  }

  @override
  Future<List<StarterMenu>> fetchStarterMenus() async {
    final res = await _client
        .from('starter_menus')
        .select()
        .eq('display_status', 'approved');
    final rows = res as List<dynamic>;
    return rows
        .map((r) => StarterMenu.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MenuItem>> fetchOwnerMenus(String ownerId) async {
    final res = await _client
        .from('menu_items')
        .select('*, restaurants(*)')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    final rows = res as List<dynamic>;
    return rows.map((row) {
      final map = row as Map<String, dynamic>;
      final rMap = map['restaurants'] as Map<String, dynamic>?;
      final restaurant = rMap != null ? Restaurant.fromJson(rMap) : null;
      return MenuItem.fromJson(map, restaurant: restaurant);
    }).toList();
  }

  @override
  Future<void> submitMenu(MenuItem menu) async {
    final payload = menu.toInsertJson();
    payload['approval_status'] = 'pending';
    payload['display_status'] = 'hidden';
    await _client.from('menu_items').insert(payload);
  }

  @override
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

  @override
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
}
