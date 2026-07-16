import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 네이버지도(없으면 웹/구글지도)로 길찾기 또는 검색을 엽니다.
class MapLauncherService {
  static Future<void> openNaverDirectionsOrSearch({
    String? restaurantName,
    required String menuName,
    String? address,
    double? lat,
    double? lng,
    required String recommendationType, // 'registered' or 'starter'
    BuildContext? context,
  }) async {
    final candidates = <String>[];

    if (recommendationType == 'registered') {
      final name = restaurantName ?? menuName;
      if (lat != null && lng != null) {
        candidates.add(
          'nmap://place?lat=$lat&lng=$lng&name=${Uri.encodeComponent(name)}&appname=com.jumeok.yori',
        );
      }
      final query = restaurantName ?? '$menuName ${address ?? ''}'.trim();
      candidates.add(
        'https://map.naver.com/v5/search/${Uri.encodeComponent(query)}',
      );
      candidates.add(
        'https://www.google.com/maps/search/${Uri.encodeComponent(query)}',
      );
    } else {
      // starter: 가게명 없이 "내 주변 + 메뉴" 검색
      candidates.add(
        'https://map.naver.com/v5/search/${Uri.encodeComponent('내 주변 $menuName')}',
      );
      candidates.add(
        'https://www.google.com/maps/search/${Uri.encodeComponent('$menuName 맛집')}',
      );
    }

    for (final url in candidates) {
      try {
        final uri = Uri.parse(url);
        final ok = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (ok) return;
      } catch (_) {
        // 다음 후보로
      }
    }

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도를 열 수 없습니다. 잠시 후 다시 시도해주세요.')),
      );
    }
  }
}
