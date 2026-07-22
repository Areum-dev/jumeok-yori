import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../models/owner_store_application.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _loading = true;
  OwnerStoreApplication? _application;
  Restaurant? _restaurant;
  List<MenuItem> _menus = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final state = context.read<AppState>();
    final uid = state.currentProfile?.id;
    if (uid != null && state.isSupabaseMode) {
      _application = await state.restaurantRepository.fetchMyApplication(uid);
      _restaurant = await state.restaurantRepository.fetchMyRestaurant(uid);
      try {
        _menus = await state.menuRepository.fetchOwnerMenus(uid);
      } catch (_) {
        _menus = [];
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('사장님 대시보드'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _statusCard(),
                  if (_restaurant != null) ...[
                    const SizedBox(height: 20),
                    _restaurantCard(_restaurant!),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            '/menu-edit',
                            arguments: _restaurant,
                          );
                          _load();
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('메뉴 등록하기'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '등록한 메뉴',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkInk,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_menus.isEmpty)
                      const Text(
                        '아직 등록한 메뉴가 없습니다.',
                        style: TextStyle(color: AppColors.textGray),
                      )
                    else
                      ..._menus.map(_menuTile),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _statusCard() {
    final status =
        _application?.status ?? (_restaurant != null ? 'approved' : null);
    String title;
    String body;
    Color color;
    if (status == null) {
      title = '가게 신청 내역이 없습니다.';
      body = '홈에서 "내 가게 등록하기"로 신청해주세요.';
      color = AppColors.midGray;
    } else if (status == 'approved') {
      title = '승인 완료 ✅';
      body = '가게가 승인되었습니다. 메뉴를 등록해보세요.';
      color = AppColors.success;
    } else if (status == 'rejected') {
      title = '반려됨';
      body = _application?.adminNote ?? '관리자에게 문의해주세요.';
      color = AppColors.error;
    } else {
      title = '검수 대기 중 ⏳';
      body = '관리자 검수 후 승인됩니다. 잠시만 기다려주세요.';
      color = AppColors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.darkInk,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _restaurantCard(Restaurant r) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.softGray),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          r.address,
          style: const TextStyle(fontSize: 13, color: AppColors.textGray),
        ),
        if (r.category != null) ...[
          const SizedBox(height: 4),
          Text(
            r.category!,
            style: const TextStyle(fontSize: 12, color: AppColors.midGray),
          ),
        ],
      ],
    ),
  );

  Widget _menuTile(MenuItem m) {
    Color statusColor;
    switch (m.approvalStatus) {
      case 'approved':
        statusColor = AppColors.success;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.orange;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softGray),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m.priceText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              m.approvalStatusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
