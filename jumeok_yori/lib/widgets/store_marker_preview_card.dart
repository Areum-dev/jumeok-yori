import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../repositories/map_repository.dart';
import '../theme/app_theme.dart';
import '../services/map_launcher_service.dart';

/// 핀을 탭했을 때 지도 하단에 뜨는 가게 미리보기 카드.
/// 메뉴 썸네일(최대 3개)을 비동기로 로드하며, X 버튼으로 닫을 수 있습니다.
class StoreMarkerPreviewCard extends StatefulWidget {
  final Restaurant restaurant;
  final double? distanceKm;
  final VoidCallback onViewDetail;
  final VoidCallback onDismiss;

  const StoreMarkerPreviewCard({
    super.key,
    required this.restaurant,
    this.distanceKm,
    required this.onViewDetail,
    required this.onDismiss,
  });

  @override
  State<StoreMarkerPreviewCard> createState() => _StoreMarkerPreviewCardState();
}

class _StoreMarkerPreviewCardState extends State<StoreMarkerPreviewCard> {
  final _repo = MapRepository();
  List<MenuItem> _menus = [];
  bool _loadingMenus = true;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  @override
  void didUpdateWidget(covariant StoreMarkerPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 다른 가게로 바뀌면 메뉴 다시 로드
    if (oldWidget.restaurant.id != widget.restaurant.id) {
      setState(() {
        _menus = [];
        _loadingMenus = true;
      });
      _loadMenus();
    }
  }

  Future<void> _loadMenus() async {
    final menus =
        await _repo.getApprovedMenusByRestaurant(widget.restaurant.id);
    if (!mounted) return;
    setState(() {
      _menus = menus.take(3).toList();
      _loadingMenus = false;
    });
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(1)}km';
  }

  /// 대표 이미지: restaurant.imageUrl > 첫 메뉴 이미지 > null(플레이스홀더)
  String? get _headerImageUrl {
    if (widget.restaurant.imageUrl != null &&
        widget.restaurant.imageUrl!.isNotEmpty) {
      return widget.restaurant.imageUrl;
    }
    for (final m in _menus) {
      if (m.imageUrl != null && m.imageUrl!.isNotEmpty) return m.imageUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    return Dismissible(
      key: ValueKey('preview_${r.id}'),
      direction: DismissDirection.down,
      onDismissed: (_) => widget.onDismiss(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headerImage(),
                    const SizedBox(width: 12),
                    Expanded(child: _headerInfo(r)),
                    InkWell(
                      onTap: widget.onDismiss,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child:
                            Icon(Icons.close, size: 20, color: AppColors.midGray),
                      ),
                    ),
                  ],
                ),
                _menuThumbnails(),
                const SizedBox(height: 12),
                _buttons(r),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerImage() {
    final url = _headerImageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url != null
          ? Image.network(
              url,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _imagePlaceholder(60),
            )
          : _imagePlaceholder(60),
    );
  }

  Widget _imagePlaceholder(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.softGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.restaurant, color: AppColors.midGray),
      );

  Widget _headerInfo(Restaurant r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.name,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.darkInk),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.category ?? '음식점',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700),
              ),
            ),
            if (widget.distanceKm != null) ...[
              const SizedBox(width: 6),
              Text(_formatDistance(widget.distanceKm!),
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        if (r.address.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            r.address,
            style: const TextStyle(fontSize: 12, color: AppColors.textGray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _menuThumbnails() {
    if (_loadingMenus) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.orange),
            ),
          ),
        ),
      );
    }
    if (_menus.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: _menus.map((m) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (m.imageUrl != null && m.imageUrl!.isNotEmpty)
                        ? Image.network(
                            m.imageUrl!,
                            height: 64,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _menuPlaceholder(),
                          )
                        : _menuPlaceholder(),
                  ),
                  const SizedBox(height: 4),
                  Text(m.name,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(m.priceText,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.orange,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _menuPlaceholder() => Container(
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.softGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.restaurant, color: AppColors.midGray, size: 20),
      );

  Widget _buttons(Restaurant r) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.directions, size: 16),
            label: const Text('길찾기', style: TextStyle(fontSize: 13)),
            onPressed: () => MapLauncherService.openNaverDirectionsOrSearch(
              restaurantName: r.name,
              menuName: r.name,
              address: r.address,
              lat: r.lat,
              lng: r.lng,
              recommendationType: 'registered',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orange,
              side: const BorderSide(color: AppColors.orange),
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: widget.onViewDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text('가게 보기', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}
