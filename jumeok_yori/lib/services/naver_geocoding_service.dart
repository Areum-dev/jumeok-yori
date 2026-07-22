import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class GeocodingResult {
  final bool success;
  final double? lat;
  final double? lng;
  final String? roadAddress;
  final String? jibunAddress;
  final String? errorMessage;

  const GeocodingResult({
    required this.success,
    this.lat,
    this.lng,
    this.roadAddress,
    this.jibunAddress,
    this.errorMessage,
  });
}

class NaverGeocodingService {
  static Future<GeocodingResult> geocodeAddress(String address) async {
    if (!Env.isNaverGeocodingConfigured) {
      return const GeocodingResult(
        success: false,
        errorMessage:
            'Naver API 키가 설정되지 않았어요. .env 파일에 NAVER_MAP_CLIENT_ID와 NAVER_MAP_CLIENT_SECRET을 입력해 주세요.',
      );
    }

    try {
      final encoded = Uri.encodeComponent(address);
      // 2026-07-14: Naver Cloud Platform이 Maps API 도메인을
      // naveropenapi.apigw.ntruss.com -> maps.apigw.ntruss.com 으로 이전함.
      // 구 도메인은 "구독 필요"(401) 오류를 반환하는 것을 실제 운영 계정에서 확인했음.
      final url = Uri.parse(
        'https://maps.apigw.ntruss.com/map-geocode/v2/geocode?query=$encoded',
      );

      final response = await http
          .get(
            url,
            headers: {
              'X-NCP-APIGW-API-KEY-ID': Env.naverMapClientId,
              'X-NCP-APIGW-API-KEY': Env.naverMapClientSecret,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addresses = data['addresses'] as List<dynamic>?;

        if (addresses == null || addresses.isEmpty) {
          return const GeocodingResult(
            success: false,
            errorMessage: '주소를 찾을 수 없어요. 정확한 도로명 주소를 입력해 주세요.',
          );
        }

        final first = addresses.first as Map<String, dynamic>;
        final lat = double.tryParse(first['y']?.toString() ?? '');
        final lng = double.tryParse(first['x']?.toString() ?? '');

        if (lat == null || lng == null) {
          return const GeocodingResult(
            success: false,
            errorMessage: '좌표 변환에 실패했어요.',
          );
        }

        debugPrint(
          '[Geocoding] Naver 성공: address="$address" '
          '→ lat=$lat lng=$lng roadAddress=${first['roadAddress']}',
        );
        return GeocodingResult(
          success: true,
          lat: lat,
          lng: lng,
          roadAddress: first['roadAddress']?.toString(),
          jibunAddress: first['jibunAddress']?.toString(),
        );
      } else {
        return GeocodingResult(
          success: false,
          errorMessage: 'API 오류 (${response.statusCode}). 잠시 후 다시 시도해 주세요.',
        );
      }
    } catch (e) {
      debugPrint('Geocoding 오류: $e');
      return const GeocodingResult(
        success: false,
        errorMessage: '주소 좌표 변환에 실패했어요. 주소를 확인하거나 좌표를 직접 입력해 주세요.',
      );
    }
  }
}
