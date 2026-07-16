import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../repositories/map_repository.dart';
import '../services/map_launcher_service.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report_dialog.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final _repo = MapRepository();
  Restaurant? _restaurant;
  List<MenuItem> _menus = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _repo.getRestaurantById(widget.restaurantId);
    final m = r != null
        ? await _repo.getApprovedMenusByRestaurant(widget.restaurantId)
        : <MenuItem>[];
    if (mounted) {
      setState(() {
        _restaurant = r;
        _menus = m;
        _loading = false;
      });
    }
    if (r != null) {
      AnalyticsService.log(
        eventType: 'restaurant_viewed',
        restaurantId: r.id,
        ownerId: r.ownerId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.ivory,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }
    if (_restaurant == null) {
      return Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(title: const Text('가게 상세')),
        body: const Center(child: Text('가게 정보를 불러올 수 없어요.')),
      );
    }

    final r = _restaurant!;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(r.name),
        backgroundColor: AppColors.ivory,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _infoCard(r),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions),
                label: const Text('길찾기'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white),
                onPressed: () {
                  AnalyticsService.log(
                    eventType: 'direction_clicked',
                    restaurantId: r.id,
                    ownerId: r.ownerId,
                  );
                  MapLauncherService.openNaverDirectionsOrSearch(
                    restaurantName: r.name,
                    menuName: r.name,
                    address: r.address,
                    lat: r.lat,
                    lng: r.lng,
                    recommendationType: 'registered',
                  );
                },
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Text('메뉴 (${_menus.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (_menus.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('아직 등록된 메뉴가 없어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGray)),
            )
          else
            ..._menus.map(_menuCard),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.flag_outlined,
                  size: 14, color: AppColors.textGray),
              label: const Text('정보 오류 신고',
                  style: TextStyle(fontSize: 12, color: AppColors.textGray)),
              onPressed: () => ReportDialog.show(context,
                  restaurantId: r.id, recommendationType: 'registered'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(Restaurant r) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (r.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(r.category!,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 10),
          if (r.description != null)
            Text(r.description!,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textGray, height: 1.5)),
          if (r.address.isNotEmpty)
            _infoRow(Icons.location_on_outlined, r.address),
          if (r.phone != null) _infoRow(Icons.phone_outlined, r.phone!),
          if (r.openingHours != null)
            _infoRow(Icons.access_time_outlined, r.openingHours!),
          if (r.isTakeoutAvailable || r.isDeliveryAvailable) ...[
            const SizedBox(height: 8),
            Row(children: [
              if (r.isTakeoutAvailable) _chip('포장 가능'),
              if (r.isDeliveryAvailable) ...[
                const SizedBox(width: 6),
                _chip('배달 가능')
              ],
            ]),
          ],
        ]),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(children: [
          Icon(icon, size: 14, color: AppColors.textGray),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ]),
      );

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: AppColors.softGray,
            borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _menuCard(MenuItem m) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
            ]),
        child: Row(children: [
          if (m.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(m.imageUrl!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      _imagePlaceholder()),
            )
          else
            _imagePlaceholder(),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(m.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                if (m.description != null)
                  Text(m.description!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGray),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(m.priceText,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange)),
              ])),
        ]),
      );

  Widget _imagePlaceholder() => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
            color: AppColors.softGray,
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.restaurant, color: AppColors.midGray),
      );
}
