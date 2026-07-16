import 'package:flutter/material.dart';
import '../repositories/analytics_repository.dart';
import '../theme/app_theme.dart';

class OwnerDashboardDetailScreen extends StatefulWidget {
  final String ownerId;
  const OwnerDashboardDetailScreen({super.key, required this.ownerId});
  @override
  State<OwnerDashboardDetailScreen> createState() =>
      _OwnerDashboardDetailScreenState();
}

class _OwnerDashboardDetailScreenState
    extends State<OwnerDashboardDetailScreen> {
  final _repo = AnalyticsRepository();
  DashboardStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _repo.getOwnerDashboardStats(widget.ownerId);
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('내 가게 대시보드',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _loading = true);
                _load();
              })
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final s = _stats ?? const DashboardStats();
    final items = [
      _Item('오늘 뽑힘', '${s.todayDrawCount}', '오늘 추천된 횟수', Icons.casino_rounded),
      _Item('전체 뽑힘', '${s.totalDrawCount}', '누적 추천 횟수', Icons.casino_outlined),
      _Item('오늘 조회', '${s.todayRestaurantViews}', '가게 상세 진입',
          Icons.visibility_outlined),
      _Item('전체 조회', '${s.totalRestaurantViews}', '누적 가게 조회',
          Icons.visibility_rounded),
      _Item('길찾기', '${s.totalDirectionClicks}', '네이버지도 이동',
          Icons.directions_outlined),
      _Item('저장', '${s.savedCount}', '저장된 횟수', Icons.bookmark_outline),
      _Item('공유', '${s.sharedCount}', '공유된 횟수', Icons.share_outlined),
      _Item('신고', '${s.reportCount}', '신고 접수 건', Icons.flag_outlined),
      _Item('등록 메뉴', '${s.totalMenuCount}', '등록된 메뉴 수',
          Icons.restaurant_menu_outlined),
      _Item('노출 메뉴', '${s.visibleMenuCount}', '현재 노출 중',
          Icons.restaurant_menu_rounded),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.orange,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (s.totalDrawCount == 0 && s.totalRestaurantViews == 0)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.softGray,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Text('📊', style: TextStyle(fontSize: 36)),
                  SizedBox(height: 8),
                  Text('아직 데이터가 없어요.',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('메뉴가 뽑히면 이곳에 기록됩니다.',
                      style: TextStyle(
                          color: AppColors.textGray, fontSize: 13)),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _statCard(items[i]),
            ),
        ],
      ),
    );
  }

  Widget _statCard(_Item item) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(item.icon, size: 16, color: AppColors.orange),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(item.label,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis)),
            ]),
            const Spacer(),
            Text(item.value,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkInk)),
            Text(item.subtitle,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textGray),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

class _Item {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  const _Item(this.label, this.value, this.subtitle, this.icon);
}
