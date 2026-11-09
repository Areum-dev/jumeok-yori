import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

/// 하단 탭 위에 붙는 작은 배너 광고(320x50).
///
/// - 광고 SDK 가 준비되지 않았거나(웹/미지원 기기) 광고를 불러오지 못하면
///   빈 공간 없이 아예 보이지 않는다.
/// - 광고임을 알 수 있도록 "광고" 표시를 붙이고, 아래 탭 버튼과는 여백으로
///   구분해 오클릭을 줄인다 (AdMob 배너 배치 정책).
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _waitForSdkAndLoad();
  }

  /// SDK 초기화(추적 허용 팝업 포함)가 끝난 뒤에 배너를 요청한다.
  Future<void> _waitForSdkAndLoad() async {
    if (!AdService.isSupported) return;
    await AdService.init();
    if (!mounted || !AdService.isReady || _requested) return;
    _requested = true;
    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AD] 배너 로드 실패: ${error.code} ${error.message}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '광고',
            style: TextStyle(fontSize: 10, color: AppColors.midGray),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        ],
      ),
    );
  }
}
