import 'package:flutter/foundation.dart';
import '../config/env.dart';
import 'naver_geocoding_service.dart';
import 'nominatim_geocoding_service.dart';

export 'naver_geocoding_service.dart' show GeocodingResult;

/// 통합 지오코딩 서비스.
/// Naver API 키가 있으면 Naver 우선, 없으면 Nominatim(무료) 사용.
class GeocodingService {
  static Future<GeocodingResult> geocodeAddress(String address) async {
    if (address.trim().isEmpty) {
      return const GeocodingResult(
        success: false,
        errorMessage: '주소를 입력해 주세요.',
      );
    }

    if (Env.isNaverGeocodingConfigured) {
      debugPrint('[GeocodingService] Naver API 사용');
      final result = await NaverGeocodingService.geocodeAddress(address);
      if (result.success) return result;
      debugPrint('[GeocodingService] Naver 실패, Nominatim으로 재시도');
    } else {
      debugPrint('[GeocodingService] Naver 키 없음 → Nominatim 사용');
    }

    return NominatimGeocodingService.geocodeAddress(address);
  }
}
