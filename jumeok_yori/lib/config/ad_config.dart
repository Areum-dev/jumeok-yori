import 'package:flutter/foundation.dart';

/// AdMob 광고 설정.
///
/// 광고 단위 ID 는 비밀값이 아니라 앱 바이너리에 그대로 들어가는 공개 식별자라
/// 코드에 두어도 됩니다. 단, 개발/디버그 중에는 항상 구글이 제공하는 테스트 ID 만
/// 사용합니다 (실제 ID 로 본인이 광고를 반복해서 보거나 누르면 AdMob 계정이
/// 정지될 수 있음).
class AdConfig {
  /// true 면 릴리스 빌드에서도 테스트 광고를 사용한다. 실제 광고 단위 ID 를
  /// 아래에 채운 뒤 false 로 바꾸면 운영 광고가 나온다.
  ///
  /// 디버그 빌드(flutter run 등)는 이 값과 상관없이 항상 테스트 광고만 쓴다.
  static const bool useTestAds = false;

  // ── 실제 광고 단위 ID (AdMob 콘솔에서 발급) ──────────────────
  // 앱 ID(Android ~8709904034 / iOS ~5800669664)는 각각
  // AndroidManifest.xml 과 ios/Runner/Info.plist 에 들어 있다.
  static const String _androidBanner = 'ca-app-pub-3603250995950186/2270674109';
  static const String _iosBanner = 'ca-app-pub-3603250995950186/7141012355';
  static const String _androidRewarded =
      'ca-app-pub-3603250995950186/7195697725';
  static const String _iosRewarded = 'ca-app-pub-3603250995950186/7277402864';

  // ── 구글 공식 테스트 광고 단위 ID ────────────────────────────
  static const String _testAndroidBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testIosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testAndroidRewarded =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testIosRewarded =
      'ca-app-pub-3940256099942544/1712485313';

  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  /// 실제 ID 를 써도 되는 상태인지: 릴리스 빌드 + 테스트 모드 해제 + ID 입력됨.
  static bool _useReal(String realId) =>
      !kDebugMode && !useTestAds && realId.isNotEmpty;

  /// 하단 배너 광고 단위 ID.
  static String get bannerUnitId {
    final real = _isIos ? _iosBanner : _androidBanner;
    if (_useReal(real)) return real;
    return _isIos ? _testIosBanner : _testAndroidBanner;
  }

  /// "다시뽑기" 보상형 광고 단위 ID.
  static String get rewardedUnitId {
    final real = _isIos ? _iosRewarded : _androidRewarded;
    if (_useReal(real)) return real;
    return _isIos ? _testIosRewarded : _testAndroidRewarded;
  }
}
