import 'package:flutter_test/flutter_test.dart';
import 'package:jumeok_yori/data/additional_starter_menus.dart';
import 'package:jumeok_yori/models/recommendation_filter.dart';
import 'package:jumeok_yori/models/starter_menu.dart';
import 'package:jumeok_yori/services/recommendation_service.dart';

void main() {
  test('추가 스타터 메뉴는 기존 목록에 더할 100개다', () {
    expect(kAdditionalStarterMenus, hasLength(100));
    expect(
      kAdditionalStarterMenus.map((menu) => menu.id).toSet(),
      hasLength(100),
    );
    expect(
      kAdditionalStarterMenus.every((menu) => menu.expectedMinPrice == null),
      isTrue,
    );
    expect(
      kAdditionalStarterMenus.every((menu) => menu.expectedMaxPrice == null),
      isTrue,
    );
  });

  test('스타터 메뉴는 가격 필터와 관계없이 추천 후보가 된다', () {
    const expensiveStarter = StarterMenu(
      id: 'starter-expensive',
      name: '가격 무관 음식 아이디어',
      category: '한식',
      expectedMinPrice: 50000,
      expectedMaxPrice: 70000,
    );

    final result = RecommendationService.recommend(
      registeredMenus: const [],
      starterMenus: const [expensiveStarter],
      filter: const RecommendationFilter(maxPrice: 5000, category: '한식'),
      userLat: 0,
      userLng: 0,
    );

    expect(result?.starterMenu?.id, expensiveStarter.id);
  });
}
