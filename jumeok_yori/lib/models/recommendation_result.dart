import 'menu_item.dart';
import 'starter_menu.dart';
import 'restaurant.dart';

/// 추천 결과 (등록 메뉴 또는 스타터 메뉴)
class RecommendationResult {
  final String type; // 'registered' or 'starter'
  final MenuItem? menuItem;
  final StarterMenu? starterMenu;
  final Restaurant? restaurant;
  final double? distanceM;

  /// 저장/추천 기록이 DB 행에서 온 경우, 그 행의 시각(저장 시각 또는 추천
  /// 시각)과 행 id. UI에서 최신순 정렬/표시, 삭제(행 id 기준)에 사용한다.
  /// 즉석 추천 결과(currentRecommendation)에는 없을 수 있다(null).
  final DateTime? recordedAt;
  final String? recordId;

  const RecommendationResult({
    required this.type,
    this.menuItem,
    this.starterMenu,
    this.restaurant,
    this.distanceM,
    this.recordedAt,
    this.recordId,
  });

  bool get isRegistered => type == 'registered';
  bool get isStarter => type == 'starter';

  factory RecommendationResult.registered(
    MenuItem item, {
    double? distanceM,
    DateTime? recordedAt,
    String? recordId,
  }) => RecommendationResult(
    type: 'registered',
    menuItem: item,
    restaurant: item.restaurant,
    distanceM: distanceM,
    recordedAt: recordedAt,
    recordId: recordId,
  );

  factory RecommendationResult.starter(
    StarterMenu menu, {
    DateTime? recordedAt,
    String? recordId,
  }) => RecommendationResult(
    type: 'starter',
    starterMenu: menu,
    recordedAt: recordedAt,
    recordId: recordId,
  );

  /// UI 공통: 메뉴 이름
  String get menuName => menuItem?.name ?? starterMenu?.name ?? '';

  /// UI 공통: 카테고리
  String get category => menuItem?.category ?? starterMenu?.category ?? '';

  /// UI 공통: 이미지 URL
  String? get imageUrl => menuItem?.imageUrl ?? starterMenu?.imageUrl;

  String? get id => isRegistered ? menuItem?.id : starterMenu?.id;

  String get distanceText {
    if (distanceM == null) return '';
    if (distanceM! < 1000) return '${distanceM!.round()}m';
    return '${(distanceM! / 1000).toStringAsFixed(1)}km';
  }

  List<String> get conditionTags =>
      menuItem?.conditionTags ?? starterMenu?.conditionTags ?? const [];
}
