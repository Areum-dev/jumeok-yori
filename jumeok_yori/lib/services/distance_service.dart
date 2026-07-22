import 'dart:math';

class DistanceService {
  // Haversine 공식으로 두 좌표 간 거리 계산 (km)
  static double calculateKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0; // 지구 반경 km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// alias (스펙 명칭)
  static double distanceInKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) => calculateKm(lat1, lng1, lat2, lng2);

  static double _toRad(double deg) => deg * pi / 180;

  static String formatDistance(double km) {
    if (km < 1.0) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(1)}km';
  }

  // 평균 도보 속도 4km/h 기준
  static int walkingMinutes(double km) => (km / 4.0 * 60).round();
}
