import 'package:shared_preferences/shared_preferences.dart';
import '../models/recommendation_filter.dart';

/// 필터를 shared_preferences 에 저장/복원합니다.
class FilterStorageService {
  static const _prefix = 'filter_';

  static Future<void> saveFilter(RecommendationFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_prefix}distanceKm', filter.distanceKm);
    await prefs.setInt('${_prefix}maxPrice', filter.maxPrice);
    await prefs.setString('${_prefix}category', filter.category ?? '전체');
    await prefs.setBool('${_prefix}soloFriendly', filter.soloFriendly);
    await prefs.setBool('${_prefix}takeoutAvailable', filter.takeoutAvailable);
    await prefs.setBool(
      '${_prefix}deliveryAvailable',
      filter.deliveryAvailable,
    );
    await prefs.setBool('${_prefix}veganOption', filter.veganOption);
    await prefs.setBool('${_prefix}excludeRecent', filter.excludeRecent);
  }

  static Future<RecommendationFilter> loadFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cat = prefs.getString('${_prefix}category');
      // 예전 버전에서 저장된 값이 현재 필터의 최대/최소 범위를 벗어나면
      // (예: 거리 상한이 10km로, 가격 상한이 100,000원으로 바뀌기 전 저장값)
      // 슬라이더 value 가 min/max 범위를 벗어나 assertion 오류가 나지 않도록
      // 안전하게 보정한다.
      final rawDistance = prefs.getDouble('${_prefix}distanceKm') ?? 2.0;
      final rawPrice = prefs.getInt('${_prefix}maxPrice') ?? 15000;
      final distanceKm = rawDistance
          .clamp(
            RecommendationFilter.minDistanceKm,
            RecommendationFilter.maxDistanceKm,
          )
          .toDouble();
      final maxPrice = rawPrice
          .clamp(
            RecommendationFilter.minPrice,
            RecommendationFilter.maxPriceLimit,
          )
          .toInt();
      return RecommendationFilter(
        distanceKm: distanceKm,
        maxPrice: maxPrice,
        category: (cat == null || cat == '전체') ? null : cat,
        soloFriendly: prefs.getBool('${_prefix}soloFriendly') ?? false,
        takeoutAvailable: prefs.getBool('${_prefix}takeoutAvailable') ?? false,
        deliveryAvailable:
            prefs.getBool('${_prefix}deliveryAvailable') ?? false,
        veganOption: prefs.getBool('${_prefix}veganOption') ?? false,
        excludeRecent: prefs.getBool('${_prefix}excludeRecent') ?? true,
      );
    } catch (_) {
      return const RecommendationFilter(distanceKm: 2.0, maxPrice: 15000);
    }
  }
}
