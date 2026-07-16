import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'naver_geocoding_service.dart';

/// OpenStreetMap Nominatim 지오코딩 (무료, API 키 불필요).
/// 한국 주소에 최적화된 두 단계 시도:
///   1차: 원본 주소 + countrycodes=kr
///   2차: 주소에서 상세주소(동/호) 제거 후 재시도
class NominatimGeocodingService {
  static const _headers = {
    'User-Agent': 'JumeokYoriApp/1.0 (Flutter)',
    'Accept-Language': 'ko,en',
  };

  static Future<GeocodingResult> geocodeAddress(String address) async {
    final cleaned = address.trim();
    if (cleaned.isEmpty) {
      return const GeocodingResult(success: false, errorMessage: '주소를 입력해 주세요.');
    }

    // 1차 시도: 원본 주소
    final result1 = await _query(cleaned);
    if (result1.success) return result1;
    debugPrint('[Nominatim] 1차 실패: ${result1.errorMessage}');

    // 2차 시도: 도/시/구/동 수준까지만 (상세주소 제거)
    final simplified = _simplifyKoreanAddress(cleaned);
    if (simplified != cleaned) {
      debugPrint('[Nominatim] 2차 시도: $simplified');
      final result2 = await _query(simplified);
      if (result2.success) return result2;
      debugPrint('[Nominatim] 2차 실패: ${result2.errorMessage}');
    }

    return GeocodingResult(
      success: false,
      errorMessage: '주소를 찾을 수 없어요. 도로명 주소(예: 서울시 강남구 테헤란로 123)로 입력해 보세요.',
    );
  }

  static Future<GeocodingResult> _query(String address) async {
    try {
      final q = Uri.encodeQueryComponent(address);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1&countrycodes=kr&addressdetails=0',
      );
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 12));

      debugPrint('[Nominatim] status=${response.statusCode} body=${response.body.substring(0, response.body.length.clamp(0, 200))}');

      if (response.statusCode != 200) {
        return GeocodingResult(
          success: false,
          errorMessage: 'Nominatim HTTP ${response.statusCode}',
        );
      }

      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) {
        return const GeocodingResult(success: false, errorMessage: '결과 없음');
      }

      final first = list.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lng = double.tryParse(first['lon']?.toString() ?? '');

      if (lat == null || lng == null) {
        return const GeocodingResult(success: false, errorMessage: '좌표 파싱 실패');
      }

      debugPrint('[Nominatim] 성공: lat=$lat lng=$lng');
      return GeocodingResult(success: true, lat: lat, lng: lng);
    } catch (e) {
      debugPrint('[Nominatim] 예외: $e');
      return GeocodingResult(success: false, errorMessage: e.toString());
    }
  }

  /// 한국 주소에서 상세(동호수 등)를 제거해 도로명+번지 수준으로 축약.
  static String _simplifyKoreanAddress(String address) {
    // "서울특별시 강남구 테헤란로 123 456동 789호" → "서울특별시 강남구 테헤란로 123"
    // 숫자 뒤에 오는 한글(동/호/층/번지) 이후를 잘라냄
    final match = RegExp(r'^(.*?\d+)(?:\s+\S*[동호층관].*)?$').firstMatch(address);
    if (match != null) {
      final simplified = match.group(1)?.trim() ?? address;
      if (simplified.length > 5 && simplified != address) return simplified;
    }
    // 공백 기준 마지막 토큰 제거
    final parts = address.split(' ');
    if (parts.length > 2) {
      return parts.sublist(0, parts.length - 1).join(' ');
    }
    return address;
  }
}
