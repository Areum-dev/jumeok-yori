class OwnerStoreApplication {
  final String id;
  final String userId;
  final String businessNumber;
  final String storeName;
  final String? ownerName;
  final String? phone;
  final String? address;
  final String? detailAddress;
  final String? category;
  final String? description;
  final String? openingHours;
  final bool isTakeoutAvailable;
  final bool isDeliveryAvailable;
  final String? businessLicenseImageUrl;
  final double? lat;
  final double? lng;
  final String? geocodingStatus;
  final String? geocodingError;
  final String status; // pending / approved / rejected / suspended
  final String? adminNote;
  final String? restaurantId;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const OwnerStoreApplication({
    required this.id,
    required this.userId,
    required this.businessNumber,
    required this.storeName,
    this.ownerName,
    this.phone,
    this.address,
    this.detailAddress,
    this.category,
    this.description,
    this.openingHours,
    this.isTakeoutAvailable = false,
    this.isDeliveryAvailable = false,
    this.businessLicenseImageUrl,
    this.lat,
    this.lng,
    this.geocodingStatus,
    this.geocodingError,
    this.status = 'pending',
    this.adminNote,
    this.restaurantId,
    this.createdAt,
    this.reviewedAt,
  });

  factory OwnerStoreApplication.fromJson(Map<String, dynamic> json) =>
      OwnerStoreApplication(
        id: json['id'] as String,
        userId: (json['user_id'] as String?) ?? '',
        businessNumber: (json['business_number'] as String?) ?? '',
        storeName: (json['store_name'] as String?) ?? '',
        ownerName: json['owner_name'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        detailAddress: json['detail_address'] as String?,
        category: json['category'] as String?,
        description: json['description'] as String?,
        openingHours: json['opening_hours'] as String?,
        isTakeoutAvailable: json['is_takeout_available'] as bool? ?? false,
        isDeliveryAvailable: json['is_delivery_available'] as bool? ?? false,
        businessLicenseImageUrl: json['business_license_image_url'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        geocodingStatus: json['geocoding_status'] as String?,
        geocodingError: json['geocoding_error'] as String?,
        status: (json['status'] as String?) ?? 'pending',
        adminNote: json['admin_note'] as String?,
        restaurantId: json['restaurant_id'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        reviewedAt: json['reviewed_at'] != null
            ? DateTime.tryParse(json['reviewed_at'] as String)
            : null,
      );

  /// insert 용 (id / 상태 / 리뷰필드 제외)
  Map<String, dynamic> toInsertJson() => {
    'user_id': userId,
    'business_number': businessNumber,
    'store_name': storeName,
    'owner_name': ownerName,
    'phone': phone,
    'address': address,
    'detail_address': detailAddress,
    'category': category,
    'description': description,
    'opening_hours': openingHours,
    'is_takeout_available': isTakeoutAvailable,
    'is_delivery_available': isDeliveryAvailable,
    'business_license_image_url': businessLicenseImageUrl,
    'lat': lat,
    'lng': lng,
    'geocoding_status': geocodingStatus,
    'geocoding_error': geocodingError,
  };

  String get statusLabel {
    switch (status) {
      case 'pending':
        return '검수 대기';
      case 'approved':
        return '승인됨';
      case 'rejected':
        return '반려됨';
      case 'suspended':
        return '정지됨';
      default:
        return status;
    }
  }
}
