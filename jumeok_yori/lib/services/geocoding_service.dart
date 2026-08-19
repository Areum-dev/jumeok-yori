import 'package:flutter/foundation.dart';
import 'naver_geocoding_service.dart';
import 'nominatim_geocoding_service.dart';

export 'naver_geocoding_service.dart' show GeocodingResult;

/// 통합 지오코딩 서비스.
/// 서버의 Naver Geocoding을 우선 사용하고 실패하면 Nominatim을 사용한다.
class GeocodingService {
  static Future<GeocodingResult> geocodeAddress(String address) async {
    if (address.trim().isEmpty) {
      return const GeocodingResult(
        success: false,
        errorMessage: '주소를 입력해 주세요.',
      );
    }

    debugPrint('[GeocodingService] 서버 Geocoding 사용');
    final result = await NaverGeocodingService.geocodeAddress(address);
    if (result.success) return result;
    debugPrint('[GeocodingService] 서버 실패, Nominatim으로 재시도');

    return NominatimGeocodingService.geocodeAddress(address);
  }
}
