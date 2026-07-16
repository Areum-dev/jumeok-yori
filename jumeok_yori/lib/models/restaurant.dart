class Restaurant {
  final String id;
  final String? ownerId;
  final String? businessNumber;
  final String name;
  final String? ownerName;
  final String? phone;
  final String address;
  final String? detailAddress;
  final double lat;
  final double lng;
  final String? imageUrl;
  final String? category;
  final String? description;
  final String? openingHours;
  final bool isTakeoutAvailable;
  final bool isDeliveryAvailable;
  // owner_registered / admin_seed / starter_menu
  final String source;
  // pending / approved / rejected / suspended
  final String verificationStatus;
  // hidden / approved / suspended
  final String displayStatus;
  final DateTime? createdAt;

  // 런타임에 계산되는 거리 (DB 저장 안 함)
  double? distanceKm;

  Restaurant({
    required this.id,
    this.ownerId,
    this.businessNumber,
    required this.name,
    this.ownerName,
    this.phone,
    required this.address,
    this.detailAddress,
    required this.lat,
    required this.lng,
    this.imageUrl,
    this.category,
    this.description,
    this.openingHours,
    this.isTakeoutAvailable = false,
    this.isDeliveryAvailable = false,
    this.source = 'admin_seed',
    this.verificationStatus = 'approved',
    this.displayStatus = 'approved',
    this.createdAt,
    this.distanceKm,
  });

  bool get isApproved =>
      verificationStatus == 'approved' && displayStatus == 'approved';

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String?,
        businessNumber: json['business_number'] as String?,
        name: json['name'] as String,
        ownerName: json['owner_name'] as String?,
        phone: json['phone'] as String?,
        address: (json['address'] as String?) ?? '',
        detailAddress: json['detail_address'] as String?,
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        imageUrl: json['image_url'] as String?,
        category: json['category'] as String?,
        description: json['description'] as String?,
        openingHours: json['opening_hours'] as String?,
        isTakeoutAvailable: json['is_takeout_available'] as bool? ?? false,
        isDeliveryAvailable: json['is_delivery_available'] as bool? ?? false,
        source: json['source'] as String? ?? 'admin_seed',
        verificationStatus:
            json['verification_status'] as String? ?? 'approved',
        displayStatus: json['display_status'] as String? ?? 'approved',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'business_number': businessNumber,
        'name': name,
        'owner_name': ownerName,
        'phone': phone,
        'address': address,
        'detail_address': detailAddress,
        'lat': lat,
        'lng': lng,
        'image_url': imageUrl,
        'category': category,
        'description': description,
        'opening_hours': openingHours,
        'is_takeout_available': isTakeoutAvailable,
        'is_delivery_available': isDeliveryAvailable,
        'source': source,
        'verification_status': verificationStatus,
        'display_status': displayStatus,
      };

  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1.0) return '${(distanceKm! * 1000).round()}m';
    return '${distanceKm!.toStringAsFixed(1)}km';
  }

  int get walkingMinutes =>
      distanceKm == null ? 0 : (distanceKm! / 4.0 * 60).round();

  String get sourceLabel {
    switch (source) {
      case 'owner_registered':
        return '사장님 직접 등록';
      case 'admin_seed':
        return '관리자 등록';
      default:
        return '기타';
    }
  }
}
