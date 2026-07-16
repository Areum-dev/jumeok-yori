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

  const RecommendationResult({
    required this.type,
    this.menuItem,
    this.starterMenu,
    this.restaurant,
    this.distanceM,
  });

  bool get isRegistered => type == 'registered';
  bool get isStarter => type == 'starter';

  factory RecommendationResult.registered(MenuItem item, {double? distanceM}) =>
      RecommendationResult(
        type: 'registered',
        menuItem: item,
        restaurant: item.restaurant,
        distanceM: distanceM,
      );

  factory RecommendationResult.starter(StarterMenu menu) =>
      RecommendationResult(type: 'starter', starterMenu: menu);

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
