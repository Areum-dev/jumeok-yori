import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// 보상형 광고 시청 결과.
enum RewardedAdResult {
  /// 끝까지 시청해 보상을 받음 -> 다음 단계로 진행해도 된다.
  completed,

  /// 광고를 보다가 중간에 닫음 -> 진행하면 안 된다.
  dismissedEarly,

  /// 광고를 불러오지 못함(네트워크/광고 재고 없음/미지원 플랫폼) -> 사용자를
  /// 막지 않기 위해 광고 없이 진행해도 된다.
  unavailable,
}

/// AdMob 초기화와 보상형("다시뽑기") 광고 관리.
class AdService {
  AdService._();

  static bool _initStarted = false;
  static bool _initialized = false;
  static RewardedAd? _rewardedAd;
  static bool _loadingRewarded = false;
  static bool _showing = false;

  /// google_mobile_ads 는 Android/iOS 에서만 동작한다(웹/데스크톱 제외).
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// 광고 SDK 가 초기화됐는지. 배너는 이 값이 true 일 때만 요청한다.
  static bool get isReady => _initialized;

  /// 앱 시작 후 한 번만 호출한다. 여러 번 불러도 안전하다.
  static Future<void> init() async {
    if (!isSupported || _initStarted) return;
    _initStarted = true;
    try {
      // iOS: 추적 허용 팝업. 거절/미결정이어도 광고는 (비맞춤형으로) 나온다.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          // 앱이 완전히 활성화되기 전에 요청하면 팝업이 조용히 무시되는 경우가
          // 있어 짧게 기다린 뒤 요청한다.
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      }
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaited(_loadRewarded());
    } catch (e) {
      debugPrint('[AD] 초기화 실패(광고 없이 계속): $e');
    }
  }

  static Future<void> _loadRewarded() async {
    if (!isSupported || !_initialized) return;
    if (_rewardedAd != null || _loadingRewarded) return;
    _loadingRewarded = true;
    final completer = Completer<void>();
    await RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loadingRewarded = false;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AD] 보상형 광고 로드 실패: ${error.code} ${error.message}');
          _loadingRewarded = false;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future;
  }

  /// 보상형 광고를 보여주고 결과를 돌려준다.
  ///
  /// 미리 불러둔 광고가 없으면 최대 [loadTimeout] 만큼만 기다려 보고, 그래도
  /// 없으면 [RewardedAdResult.unavailable] 을 돌려줘서 호출부가 사용자를
  /// 막지 않게 한다.
  static Future<RewardedAdResult> showRewarded({
    Duration loadTimeout = const Duration(seconds: 4),
  }) async {
    if (!isSupported || _showing) return RewardedAdResult.unavailable;
    if (!_initialized) {
      // 초기화가 아직 끝나지 않았으면 잠깐 기다린다.
      await init();
    }
    if (_rewardedAd == null) {
      await _loadRewarded().timeout(loadTimeout, onTimeout: () {});
    }
    final ad = _rewardedAd;
    if (ad == null) return RewardedAdResult.unavailable;

    _rewardedAd = null; // 한 번 쓴 광고는 다시 쓸 수 없다.
    _showing = true;
    var earned = false;
    final done = Completer<RewardedAdResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        unawaited(_loadRewarded()); // 다음 번을 위해 미리 불러둔다.
        if (!done.isCompleted) {
          done.complete(
            earned
                ? RewardedAdResult.completed
                : RewardedAdResult.dismissedEarly,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AD] 보상형 광고 표시 실패: ${error.code} ${error.message}');
        ad.dispose();
        _showing = false;
        unawaited(_loadRewarded());
        if (!done.isCompleted) done.complete(RewardedAdResult.unavailable);
      },
    );

    try {
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
    } catch (e) {
      debugPrint('[AD] 보상형 광고 show 예외: $e');
      ad.dispose();
      _showing = false;
      if (!done.isCompleted) done.complete(RewardedAdResult.unavailable);
    }
    return done.future;
  }
}
