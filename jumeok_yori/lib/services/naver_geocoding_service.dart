import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'geocode-address',
        body: {'address': address.trim()},
      );
      final data = response.data;
      if (data is! Map) {
        return const GeocodingResult(
          success: false,
          errorMessage: '주소 변환 서버 응답이 올바르지 않아요.',
        );
      }
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (data['success'] != true || lat == null || lng == null) {
        return GeocodingResult(
          success: false,
          errorMessage: data['error']?.toString() ?? '주소를 찾을 수 없어요.',
        );
      }
      return GeocodingResult(
        success: true,
        lat: lat,
        lng: lng,
        roadAddress: data['roadAddress']?.toString(),
        jibunAddress: data['jibunAddress']?.toString(),
      );
    } catch (e) {
      debugPrint('Geocoding Edge Function 오류: $e');
      return const GeocodingResult(
        success: false,
        errorMessage: '주소 좌표 변환 서버에 연결하지 못했어요.',
      );
    }
  }
}
