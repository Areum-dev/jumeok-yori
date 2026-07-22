import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/map_repository.dart';
import '../models/restaurant.dart';
import '../theme/app_theme.dart';
import '../widgets/owner_dashboard_overview_card.dart';
import 'menu_management_screen.dart';
import 'owner_dashboard_detail_screen.dart';
import 'owner_store_edit_screen.dart';

class MyStoreTabScreen extends StatefulWidget {
  const MyStoreTabScreen({super.key});
  @override
  State<MyStoreTabScreen> createState() => _MyStoreTabScreenState();
}

class _MyStoreTabScreenState extends State<MyStoreTabScreen> {
  final _analyticsRepo = AnalyticsRepository();
  final _mapRepo = MapRepository();
  DashboardStats? _stats;
  Restaurant? _myRestaurant;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _myRestaurant = null; // 이전 사용자 데이터 초기화
      _stats = null;
    });
    final appState = context.read<AppState>();
    await appState.loadMyStoreInfo();
    final userId = appState.currentProfile?.id;
    final restaurantId = appState.myRestaurantId;

    // 로그인 사용자가 없으면 아무것도 로드하지 않음
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // 통계는 항상 현재 사용자(owner_id) 기준으로만 집계
    final stats = await _analyticsRepo.getOwnerDashboardStats(userId);
    if (mounted) setState(() => _stats = stats);

    // 가게는 현재 사용자의 restaurant_id 로 로드하고, owner_id 로 재검증
    Restaurant? restaurant;
    if (restaurantId != null) {
      restaurant = await _mapRepo.getRestaurantById(restaurantId);
      if (restaurant != null && restaurant.ownerId != userId) {
        // 보안: 다른 사용자의 가게는 절대 노출하지 않음
        restaurant = null;
      }
    }
    // restaurant_id 로 못 찾으면 owner_id 로 직접 조회
    restaurant ??= await _mapRepo.getRestaurantByOwnerId(userId);
    // owner_id 로 찾은 경우에도 최종 재검증
    if (restaurant != null && restaurant.ownerId != userId) {
      restaurant = null;
    }

    if (mounted) {
      setState(() {
        _myRestaurant = restaurant;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final status = appState.myStoreApplicationStatus;
    final isApproved =
        status == 'approved' ||
        appState.isOwner ||
        appState.isAdmin ||
        _myRestaurant != null;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text(
          '내 가게',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            )
          : isApproved
          ? _approvedView(appState)
          : _pendingView(),
    );
  }

  Widget _pendingView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            '관리자 승인 대기 중입니다.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            '승인 후 메뉴를 등록할 수 있어요.',
            style: TextStyle(color: AppColors.textGray),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '신청 내역을 확인하려면 관리자에게 문의해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textGray),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _approvedView(AppState appState) {
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_myRestaurant != null) _storeInfoCard(_myRestaurant!),
          const SizedBox(height: 16),
          OwnerDashboardOverviewCard(
            stats: _stats ?? const DashboardStats(),
            onTap: () {
              final userId = appState.currentProfile?.id;
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OwnerDashboardDetailScreen(ownerId: userId),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 20),
          _sectionButton(
            icon: Icons.restaurant_menu,
            title: '메뉴 관리',
            subtitle: '메뉴 등록, 수정, 숨김/노출',
            onTap:
                (_myRestaurant != null && appState.currentProfile?.id != null)
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuManagementScreen(
                        restaurantId: _myRestaurant!.id,
                        ownerId: appState.currentProfile!.id,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          _sectionButton(
            icon: Icons.store_outlined,
            title: '가게 정보 수정',
            subtitle: '이름, 주소, 전화번호 등 수정',
            onTap: _myRestaurant != null
                ? () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OwnerStoreEditScreen(restaurant: _myRestaurant!),
                      ),
                    );
                    if (result == true) _load(); // 수정 후 새로고침
                  }
                : null,
          ),
          const SizedBox(height: 10),
          _sectionButton(
            icon: Icons.flag_outlined,
            title: '신고/오류',
            subtitle: '신고된 항목 확인',
            onTap: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('신고 관리 기능은 준비 중이에요.'))),
          ),
        ],
      ),
    );
  }

  Widget _storeInfoCard(Restaurant r) {
    final noCoords = r.lat == 0 && r.lng == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '승인됨',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (r.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textGray,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    r.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGray,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (noCoords) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, size: 14, color: Colors.amber),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '좌표가 없어 주먹지도에 표시되지 않습니다.\n관리자에게 문의해 주세요.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: onTap != null ? AppColors.midGray : AppColors.softGray,
          ),
        ],
      ),
    ),
  );
}
