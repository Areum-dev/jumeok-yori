import 'restaurant.dart';

class MenuItem {
  final String id;
  final String restaurantId;
  final String? ownerId;
  final String name;
  final String? description;
  final int price;
  final String category;
  final String? imageUrl;
  final bool isAvailable;
  final bool isTakeoutAvailable;
  final bool isDeliveryAvailable;
  final bool isSoloFriendly;
  final bool isVeganOption;
  final int? spicyLevel; // 0~5
  // owner_registered / admin_seed
  final String source;
  // pending / approved / rejected
  final String approvalStatus;
  // hidden / approved / suspended
  final String displayStatus;
  // 조인 데이터 (런타임)
  Restaurant? restaurant;

  MenuItem({
    required this.id,
    required this.restaurantId,
    this.ownerId,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isAvailable = true,
    this.isTakeoutAvailable = false,
    this.isDeliveryAvailable = false,
    this.isSoloFriendly = false,
    this.isVeganOption = false,
    this.spicyLevel,
    this.source = 'owner_registered',
    this.approvalStatus = 'approved',
    this.displayStatus = 'approved',
    this.restaurant,
  });

  bool get isApproved =>
      approvalStatus == 'approved' && displayStatus == 'approved';

  factory MenuItem.fromJson(
    Map<String, dynamic> json, {
    Restaurant? restaurant,
  }) => MenuItem(
    id: json['id'] as String,
    restaurantId: json['restaurant_id'] as String,
    ownerId: json['owner_id'] as String?,
    name: json['name'] as String,
    description: json['description'] as String?,
    price: (json['price'] as num).toInt(),
    category: (json['category'] as String?) ?? '기타',
    imageUrl: json['image_url'] as String?,
    isAvailable: json['is_available'] as bool? ?? true,
    isTakeoutAvailable: json['is_takeout_available'] as bool? ?? false,
    isDeliveryAvailable: json['is_delivery_available'] as bool? ?? false,
    isSoloFriendly: json['is_solo_friendly'] as bool? ?? false,
    isVeganOption: json['is_vegan_option'] as bool? ?? false,
    spicyLevel: json['spicy_level'] as int?,
    source: json['source'] as String? ?? 'owner_registered',
    approvalStatus: json['approval_status'] as String? ?? 'approved',
    displayStatus: json['display_status'] as String? ?? 'approved',
    restaurant: restaurant,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'restaurant_id': restaurantId,
    'owner_id': ownerId,
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'image_url': imageUrl,
    'is_available': isAvailable,
    'is_takeout_available': isTakeoutAvailable,
    'is_delivery_available': isDeliveryAvailable,
    'is_solo_friendly': isSoloFriendly,
    'is_vegan_option': isVeganOption,
    'spicy_level': spicyLevel,
    'source': source,
    'approval_status': approvalStatus,
    'display_status': displayStatus,
  };

  /// 신규 등록/수정용 insert payload (id 제외, 상태는 호출부에서 지정)
  Map<String, dynamic> toInsertJson() {
    final map = toJson();
    map.remove('id');
    return map;
  }

  String get priceText {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return '$formatted원';
  }

  String get approvalStatusLabel {
    switch (approvalStatus) {
      case 'pending':
        return '검수 대기';
      case 'approved':
        return '승인됨';
      case 'rejected':
        return '반려됨';
      default:
        return approvalStatus;
    }
  }

  List<String> get conditionTags {
    final tags = <String>[];
    if (isSoloFriendly) tags.add('혼밥 OK');
    if (isTakeoutAvailable) tags.add('포장 가능');
    if (isDeliveryAvailable) tags.add('배달 가능');
    if (isVeganOption) tags.add('비건 옵션');
    if (spicyLevel != null && spicyLevel! >= 3) tags.add('매운맛');
    return tags;
  }
}
