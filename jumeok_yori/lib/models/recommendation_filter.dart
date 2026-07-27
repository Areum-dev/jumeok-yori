class RecommendationFilter {
  static const double minDistanceKm = 0.5;
  static const double maxDistanceKm = 10.0;
  static const int minPrice = 5000;
  static const int maxPriceLimit = 100000;

  final double distanceKm; // 0.5 ~ 10.0
  final int maxPrice; // 5000 ~ 100000
  final String? category; // null이면 전체
  final bool soloFriendly;
  final bool takeoutAvailable;
  final bool deliveryAvailable;
  final bool veganOption;
  final bool excludeRecent;

  const RecommendationFilter({
    this.distanceKm = 2.0,
    this.maxPrice = 15000,
    this.category,
    this.soloFriendly = false,
    this.takeoutAvailable = false,
    this.deliveryAvailable = false,
    this.veganOption = false,
    this.excludeRecent = true,
  });

  RecommendationFilter copyWith({
    double? distanceKm,
    int? maxPrice,
    Object? category = _sentinel,
    bool? soloFriendly,
    bool? takeoutAvailable,
    bool? deliveryAvailable,
    bool? veganOption,
    bool? excludeRecent,
  }) {
    return RecommendationFilter(
      distanceKm: distanceKm ?? this.distanceKm,
      maxPrice: maxPrice ?? this.maxPrice,
      category: category == _sentinel ? this.category : category as String?,
      soloFriendly: soloFriendly ?? this.soloFriendly,
      takeoutAvailable: takeoutAvailable ?? this.takeoutAvailable,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      veganOption: veganOption ?? this.veganOption,
      excludeRecent: excludeRecent ?? this.excludeRecent,
    );
  }

  Map<String, dynamic> toJson() => {
    'distanceKm': distanceKm,
    'maxPrice': maxPrice,
    'category': category,
    'soloFriendly': soloFriendly,
    'takeoutAvailable': takeoutAvailable,
    'deliveryAvailable': deliveryAvailable,
    'veganOption': veganOption,
    'excludeRecent': excludeRecent,
  };

  String get distanceLabel {
    if (distanceKm < 1.0) return '${(distanceKm * 1000).round()}m';
    return '${distanceKm.toStringAsFixed(distanceKm == distanceKm.roundToDouble() ? 0 : 1)}km';
  }

  String get priceLabel => '${_formatPrice(maxPrice)} 이하';

  String get categoryLabel => category ?? '전체';

  String get summaryText {
    final parts = <String>['$distanceLabel 이내', priceLabel, categoryLabel];
    if (soloFriendly) parts.add('혼밥');
    if (takeoutAvailable) parts.add('포장');
    if (deliveryAvailable) parts.add('배달');
    if (veganOption) parts.add('비건');
    return parts.join(' · ');
  }

  static String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return '$formatted원';
  }
}

const _sentinel = Object();

const kCategoryOptions = <String>[
  '전체',
  '한식',
  '중식',
  '일식',
  '양식',
  '분식',
  '치킨',
  '피자',
  '햄버거',
  '고기',
  '해산물',
  '면',
  '밥',
  '국·탕·찌개',
  '샐러드',
  '디저트',
  '카페',
  '술집',
  '야식',
  '기타',
];

/// 필터링 시 카테고리 값 비교에 사용합니다. 기존에 저장된(구) 카테고리
/// 문자열이나 사장님이 자유 입력한 표기가 새 카테고리 목록과 정확히
/// 일치하지 않아도 합리적으로 매칭되도록 완화된 비교를 제공합니다.
/// 기존 DB의 카테고리 값 자체는 변경하지 않고, 비교 로직에서만 흡수합니다.
class CategoryMatcher {
  static const Map<String, List<String>> _aliases = {
    '면': [
      '라면',
      '우동',
      '파스타',
      '쌀국수',
      '냉면',
      '칼국수',
      '짜장면',
      '짬뽕',
      '소바',
      '막국수',
      '냉모밀',
      '팟타이',
    ],
    '밥': ['덮밥', '볶음밥', '비빔밥', '국밥', '컵밥', '규동', '카레라이스'],
    '국·탕·찌개': ['국밥', '탕', '찌개', '전골'],
    '술집': ['호프', '이자카야', '포차', '펍'],
    '카페': ['카페/디저트', '카페'],
    '디저트': ['카페/디저트', '디저트', '베이커리'],
    '치킨': ['패스트푸드', '치킨'],
    '피자': ['패스트푸드', '피자'],
    '햄버거': ['패스트푸드', '햄버거', '버거'],
  };

  /// [rawCategory](메뉴에 실제 저장된 카테고리)가 [canonicalFilter](사용자가
  /// 선택한 필터 카테고리)에 해당하는지 판단합니다.
  static bool matches(String? rawCategory, String canonicalFilter) {
    if (rawCategory == null || rawCategory.isEmpty) return false;
    if (rawCategory == canonicalFilter) return true;
    final aliases = _aliases[canonicalFilter];
    if (aliases == null) return false;
    return aliases.any(
      (a) => rawCategory.contains(a) || a.contains(rawCategory),
    );
  }
}
