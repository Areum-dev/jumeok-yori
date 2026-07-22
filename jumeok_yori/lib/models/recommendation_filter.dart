class RecommendationFilter {
  final double distanceKm; // 0.5 ~ 5.0
  final int maxPrice; // 5000 ~ 30000
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
  '패스트푸드',
  '카페/디저트',
];
