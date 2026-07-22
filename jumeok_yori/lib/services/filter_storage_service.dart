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
      return RecommendationFilter(
        distanceKm: prefs.getDouble('${_prefix}distanceKm') ?? 2.0,
        maxPrice: prefs.getInt('${_prefix}maxPrice') ?? 15000,
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
