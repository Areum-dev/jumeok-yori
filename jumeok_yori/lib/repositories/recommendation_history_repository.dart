import 'package:supabase_flutter/supabase_flutter.dart';

/// recommendation_logs 한 행. saved_menu_items 와 마찬가지로 참조(id)만
/// 담고, 실제 메뉴 정보는 AppState 가 이미 불러온 목록과 매칭해 구성한다.
class RecommendationLogRow {
  final String id;
  final String recommendationType; // 'registered' or 'starter'
  final String? menuItemId;
  final String? starterMenuId;
  final DateTime createdAt;

  const RecommendationLogRow({
    required this.id,
    required this.recommendationType,
    this.menuItemId,
    this.starterMenuId,
    required this.createdAt,
  });

  factory RecommendationLogRow.fromJson(Map<String, dynamic> json) =>
      RecommendationLogRow(
        id: json['id'] as String,
        recommendationType: json['recommendation_type'] as String,
        menuItemId: json['menu_item_id'] as String?,
        starterMenuId: json['starter_menu_id'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

/// recommendation_logs 테이블 접근 (Supabase, RLS: 본인 행만 select).
class RecommendationHistoryRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<RecommendationLogRow>> fetchHistory(
    String userId, {
    int limit = 50,
  }) async {
    final res = await _client
        .from('recommendation_logs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    final rows = res as List<dynamic>;
    return rows
        .map((r) => RecommendationLogRow.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteEntry(String rowId) async {
    await _client.from('recommendation_logs').delete().eq('id', rowId);
  }

  Future<void> deleteAll(String userId) async {
    await _client.from('recommendation_logs').delete().eq('user_id', userId);
  }
}
