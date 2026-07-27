import 'package:supabase_flutter/supabase_flutter.dart';

/// 저장한 메뉴 한 행을 나타내는 가벼운 값 객체.
/// 실제 메뉴 정보(이름/가격/이미지 등)는 여기 담지 않고, AppState 가 이미
/// 불러온 registeredMenus/starterMenus 목록과 id 로 매칭해 구성한다
/// (saved_menu_items 테이블 자체는 참조만 저장하는 정규화된 구조이므로).
class SavedMenuRow {
  final String id; // saved_menu_items.id (삭제 시 사용)
  final String recommendationType; // 'registered' or 'starter'
  final String? menuItemId;
  final String? starterMenuId;
  final DateTime createdAt;

  const SavedMenuRow({
    required this.id,
    required this.recommendationType,
    this.menuItemId,
    this.starterMenuId,
    required this.createdAt,
  });

  factory SavedMenuRow.fromJson(Map<String, dynamic> json) => SavedMenuRow(
    id: json['id'] as String,
    recommendationType: json['recommendation_type'] as String,
    menuItemId: json['menu_item_id'] as String?,
    starterMenuId: json['starter_menu_id'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
  );
}

/// saved_menu_items 테이블 접근 (Supabase, RLS: 본인 행만 select/insert/delete).
class SavedMenuRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<SavedMenuRow>> fetchSaved(String userId) async {
    final res = await _client
        .from('saved_menu_items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final rows = res as List<dynamic>;
    return rows
        .map((r) => SavedMenuRow.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<SavedMenuRow> insertSaved({
    required String userId,
    required bool isRegistered,
    required String id,
  }) async {
    final payload = {
      'user_id': userId,
      'recommendation_type': isRegistered ? 'registered' : 'starter',
      'menu_item_id': isRegistered ? id : null,
      'starter_menu_id': isRegistered ? null : id,
    };
    final res = await _client
        .from('saved_menu_items')
        .insert(payload)
        .select()
        .single();
    return SavedMenuRow.fromJson(res);
  }

  Future<void> deleteSaved(String rowId) async {
    await _client.from('saved_menu_items').delete().eq('id', rowId);
  }

  /// 특정 메뉴가 이미 저장돼 있는지, 저장돼 있다면 그 행의 id 를 반환.
  /// 중복 저장(같은 사용자가 같은 메뉴를 두 번 저장) 방지에 사용한다.
  Future<String?> findExisting({
    required String userId,
    required bool isRegistered,
    required String id,
  }) async {
    final column = isRegistered ? 'menu_item_id' : 'starter_menu_id';
    final res = await _client
        .from('saved_menu_items')
        .select('id')
        .eq('user_id', userId)
        .eq(column, id)
        .limit(1)
        .maybeSingle();
    return res?['id'] as String?;
  }
}
