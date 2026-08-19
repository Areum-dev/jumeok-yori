import 'dart:math';
import '../models/menu_item.dart';
import '../models/starter_menu.dart';
import '../models/recommendation_filter.dart';
import '../models/recommendation_result.dart';
import 'distance_service.dart';

class RecommendationService {
  /// 등록 메뉴 + 스타터 메뉴를 통합 필터링 후 하나를 무작위 추천합니다.
  static RecommendationResult? recommend({
    required List<MenuItem> registeredMenus,
    required List<StarterMenu> starterMenus,
    required RecommendationFilter filter,
    required double userLat,
    required double userLng,
    List<String> recentRegisteredIds = const [],
    List<String> recentStarterIds = const [],
  }) {
    final cat = (filter.category != null && filter.category != '전체')
        ? filter.category
        : null;

    // ── 1. 등록 메뉴 필터링 ──
    var regCandidates = registeredMenus.where((item) {
      if (!item.isApproved) return false;
      if (!item.isAvailable) return false;
      final r = item.restaurant;
      if (r == null) return false;

      final dist = DistanceService.calculateKm(userLat, userLng, r.lat, r.lng);
      r.distanceKm = dist;
      if (dist > filter.distanceKm) return false;

      if (item.price > filter.maxPrice) return false;
      if (cat != null && !CategoryMatcher.matches(item.category, cat)) {
        return false;
      }
      if (filter.soloFriendly && !item.isSoloFriendly) return false;
      if (filter.takeoutAvailable && !item.isTakeoutAvailable) return false;
      if (filter.deliveryAvailable && !item.isDeliveryAvailable) return false;
      if (filter.veganOption && !item.isVeganOption) return false;
      return true;
    }).toList();

    // ── 2. 스타터 메뉴 필터링 (거리 무관) ──
    var starterCandidates = starterMenus.where((m) {
      if (m.displayStatus != 'approved') return false;
      // 스타터(목업) 메뉴는 실제 판매 가게가 생기기 전 음식 종류 아이디어를
      // 제공하기 위한 데이터다. 음식점마다 가격이 달라지므로 가격/거리 필터를
      // 적용하지 않고 카테고리와 이용 옵션만 적용한다.
      if (cat != null && !CategoryMatcher.matches(m.category, cat)) {
        return false;
      }
      if (filter.soloFriendly && !m.isSoloFriendly) return false;
      if (filter.takeoutAvailable && !m.isTakeoutFriendly) return false;
      if (filter.deliveryAvailable && !m.isDeliveryFriendly) return false;
      if (filter.veganOption && !m.isVeganOption) return false;
      return true;
    }).toList();

    // ── 3. 최근 제외 ──
    if (filter.excludeRecent) {
      if (recentRegisteredIds.isNotEmpty) {
        final f = regCandidates
            .where((i) => !recentRegisteredIds.contains(i.id))
            .toList();
        if (f.isNotEmpty) regCandidates = f;
      }
      if (recentStarterIds.isNotEmpty) {
        final f = starterCandidates
            .where((m) => !recentStarterIds.contains(m.id))
            .toList();
        if (f.isNotEmpty) starterCandidates = f;
      }
    }

    // ── 4. 통합 & 선택 ──
    final results = <RecommendationResult>[];
    for (final i in regCandidates) {
      results.add(
        RecommendationResult.registered(
          i,
          distanceM: (i.restaurant?.distanceKm ?? 0) * 1000,
        ),
      );
    }
    for (final m in starterCandidates) {
      results.add(RecommendationResult.starter(m));
    }

    if (results.isEmpty) return null;

    results.shuffle(Random());
    return results.first;
  }
}
