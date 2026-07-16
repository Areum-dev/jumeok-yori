import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../theme/app_theme.dart';
import 'store_marker_preview_card.dart';

class MapFallbackStoreList extends StatelessWidget {
  final List<Restaurant> restaurants;
  final double? userLat;
  final double? userLng;
  final Function(Restaurant) onViewDetail;

  const MapFallbackStoreList({
    super.key,
    required this.restaurants,
    this.userLat,
    this.userLng,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🗺️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('아직 등록된 가게가 없어요.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('사장님 등록 후 관리자 승인이 완료되면\n이 화면에 가게가 표시됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGray, height: 1.5)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: restaurants.length,
      itemBuilder: (_, i) {
        final r = restaurants[i];
        final hasCoords = r.lat != 0 && r.lng != 0;
        final dist = (userLat != null && userLng != null && hasCoords)
            ? _haversine(userLat!, userLng!, r.lat, r.lng)
            : null;
        return StoreMarkerPreviewCard(
          restaurant: r,
          distanceKm: dist,
          onViewDetail: () => onViewDetail(r),
          onDismiss: () {},
        );
      },
    );
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLng / 2), 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
