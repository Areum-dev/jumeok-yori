class StarterMenu {
  final String id;
  final String name;
  final String? description;
  final String category;
  final int? expectedMinPrice;
  final int? expectedMaxPrice;
  final String? imageUrl;
  final bool isSoloFriendly;
  final bool isTakeoutFriendly;
  final bool isDeliveryFriendly;
  final bool isVeganOption;
  final String? searchKeyword;
  final String source; // starter_menu
  final String displayStatus; // approved

  const StarterMenu({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.expectedMinPrice,
    this.expectedMaxPrice,
    this.imageUrl,
    this.isSoloFriendly = false,
    this.isTakeoutFriendly = false,
    this.isDeliveryFriendly = false,
    this.isVeganOption = false,
    this.searchKeyword,
    this.source = 'starter_menu',
    this.displayStatus = 'approved',
  });

  factory StarterMenu.fromJson(Map<String, dynamic> json) => StarterMenu(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        category: (json['category'] as String?) ?? '기타',
        expectedMinPrice: (json['expected_min_price'] as num?)?.toInt(),
        expectedMaxPrice: (json['expected_max_price'] as num?)?.toInt(),
        imageUrl: json['image_url'] as String?,
        isSoloFriendly: json['is_solo_friendly'] as bool? ?? false,
        isTakeoutFriendly: json['is_takeout_friendly'] as bool? ?? false,
        isDeliveryFriendly: json['is_delivery_friendly'] as bool? ?? false,
        isVeganOption: json['is_vegan_option'] as bool? ?? false,
        searchKeyword: json['search_keyword'] as String?,
        source: json['source'] as String? ?? 'starter_menu',
        displayStatus: json['display_status'] as String? ?? 'approved',
      );

  String get priceRangeText {
    String fmt(int p) => p.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
    if (expectedMinPrice == null && expectedMaxPrice == null) return '가격 정보 없음';
    if (expectedMinPrice != null && expectedMaxPrice != null) {
      return '${fmt(expectedMinPrice!)} ~ ${fmt(expectedMaxPrice!)}원';
    }
    final p = expectedMinPrice ?? expectedMaxPrice!;
    return '약 ${fmt(p)}원';
  }

  List<String> get conditionTags {
    final tags = <String>[];
    if (isSoloFriendly) tags.add('혼밥 OK');
    if (isTakeoutFriendly) tags.add('포장 추천');
    if (isDeliveryFriendly) tags.add('배달 추천');
    if (isVeganOption) tags.add('비건 옵션');
    return tags;
  }
}
