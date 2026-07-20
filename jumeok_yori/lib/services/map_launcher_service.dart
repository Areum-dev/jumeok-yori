import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum _MapChoice { apple, naver }

/// 길찾기/지도 검색 실행.
///
/// iOS: Apple App Review Guideline 4 (Design) 대응.
/// "제3자 지도 앱(네이버 지도)만 실행되고 iOS 기본 지도(Apple 지도) 연동이 없다"는
/// 사유로 반려된 바 있어, iOS에서는 항상 Apple 지도 / 네이버 지도 중 선택하도록 함.
/// Android는 기존과 동일하게 네이버 지도(없으면 웹/구글지도)로 바로 이동.
class MapLauncherService {
  /// 좌표가 없거나(0,0 포함, 이 앱에서 "미설정" sentinel로 사용) 잘못된 경우를 판별.
  static bool _hasValidCoords(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat == 0 && lng == 0) return false;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
    return true;
  }

  /// 길찾기 진입점. 기존 openNaverDirectionsOrSearch 를 대체합니다.
  static Future<void> openDirections({
    String? restaurantName,
    required String menuName,
    String? address,
    double? lat,
    double? lng,
    required String recommendationType, // 'registered' or 'starter'
    BuildContext? context,
  }) async {
    final displayName = restaurantName ?? menuName;
    final hasCoords = _hasValidCoords(lat, lng);

    // iOS 에서는 반드시 Apple 지도 / 네이버 지도 중 선택하게 함 (App Review 요구사항).
    // dart:io Platform 대신 defaultTargetPlatform 사용: Flutter Web 빌드에서도
    // (dart:io 를 못 쓰므로) 컴파일 오류 없이 안전하게 동작.
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    if (isIOS && context != null && context.mounted) {
      final choice = await _showIosMapPicker(context);
      if (choice == null) return; // 사용자가 취소
      if (choice == _MapChoice.apple) {
        await _openAppleMaps(
          name: displayName,
          address: address,
          lat: hasCoords ? lat : null,
          lng: hasCoords ? lng : null,
        );
        return;
      }
      // choice == naver: 아래 공통 로직으로 진행
    }

    // 위 iOS 선택창에서 await 가 발생했을 수 있으므로, context 를 넘기기 전
    // 위젯이 여전히 화면에 있는지 다시 확인한다 (async gap 이후 context 사용 방지).
    if (context != null && !context.mounted) return;

    await _openNaverOrFallback(
      restaurantName: restaurantName,
      menuName: menuName,
      address: address,
      lat: hasCoords ? lat : null,
      lng: hasCoords ? lng : null,
      recommendationType: recommendationType,
      context: context,
    );
  }

  /// 이전 이름 유지 (하위 호환용 별칭). 새 코드는 openDirections 를 사용하세요.
  static Future<void> openNaverDirectionsOrSearch({
    String? restaurantName,
    required String menuName,
    String? address,
    double? lat,
    double? lng,
    required String recommendationType,
    BuildContext? context,
  }) =>
      openDirections(
        restaurantName: restaurantName,
        menuName: menuName,
        address: address,
        lat: lat,
        lng: lng,
        recommendationType: recommendationType,
        context: context,
      );

  static Future<_MapChoice?> _showIosMapPicker(BuildContext context) {
    return showCupertinoModalPopup<_MapChoice>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('길찾기'),
        message: const Text('어떤 지도 앱으로 길을 찾으시겠어요?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, _MapChoice.apple),
            child: const Text('Apple 지도로 길찾기'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, _MapChoice.naver),
            child: const Text('네이버 지도로 길찾기'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소'),
        ),
      ),
    );
  }

  /// Apple 지도 실행. https 유니버설 링크라서 canLaunchUrl 사전 확인 없이도
  /// iOS 기본 기능으로 항상 정상 실행됨 (Apple 지도 앱이 있으면 앱으로,
  /// 없어도 Safari 웹 지도로 열림 — 설치 여부에 관계없이 항상 성공).
  static Future<void> _openAppleMaps({
    required String name,
    String? address,
    double? lat,
    double? lng,
  }) async {
    final Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
    } else if (address != null && address.trim().isNotEmpty) {
      uri = Uri.parse(
        'https://maps.apple.com/?daddr=${Uri.encodeComponent(address)}&dirflg=d',
      );
    } else {
      uri = Uri.parse('https://maps.apple.com/?q=${Uri.encodeComponent(name)}');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// 네이버 지도(앱 우선, 없으면 웹) → 실패 시 구글 웹 지도까지 순서대로 시도.
  /// 네이버 지도 앱이 없어도 nmap:// 실행이 조용히 다음 후보(웹)로 넘어가므로
  /// 사용자에게 오류 화면이 뜨지 않음.
  static Future<void> _openNaverOrFallback({
    String? restaurantName,
    required String menuName,
    String? address,
    double? lat,
    double? lng,
    required String recommendationType,
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
