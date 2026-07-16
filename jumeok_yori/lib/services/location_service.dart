import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';

class LocationService {
  static Future<LocationPermission> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission;
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  static Future<bool> isPermissionGranted() async {
    try {
      final p = await Geolocator.checkPermission();
      return p == LocationPermission.always ||
          p == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// 현재 위치. 권한 거부/오류 시 null 반환 (호출부에서 기본 위치 사용)
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final permission = await requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// 항상 좌표를 반환 (실패 시 강남역 기본값)
  static Future<({double lat, double lng, bool isDefault})>
      getPositionOrDefault() async {
    final pos = await getCurrentPosition();
    if (pos == null) {
      return (
        lat: AppConfig.defaultLat,
        lng: AppConfig.defaultLng,
        isDefault: true,
      );
    }
    return (lat: pos.latitude, lng: pos.longitude, isDefault: false);
  }
}
