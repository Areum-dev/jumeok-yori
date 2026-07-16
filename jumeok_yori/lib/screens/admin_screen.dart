import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../repositories/admin_repository.dart';
import '../repositories/map_repository.dart';
import '../models/restaurant.dart';
import '../theme/app_theme.dart';
import 'admin_store_applications_screen.dart';
import 'admin_menu_applications_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!state.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('관리자')),
        body: const Center(
          child: Text('관리자만 접근할 수 있습니다.',
              style: TextStyle(color: AppColors.textGray)),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          title: const Text('관리자 페이지'),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.textGray,
            indicatorColor: AppColors.orange,
            tabs: [
              Tab(text: '가게 신청'),
              Tab(text: '메뉴 신청'),
              Tab(text: '등록된 가게'),
              Tab(text: '신고 목록'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              AdminStoreApplicationsScreen(),
              AdminMenuApplicationsScreen(),
              _AllRestaurantsTab(),
              _ReportsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllRestaurantsTab extends StatefulWidget {
  const _AllRestaurantsTab();

  @override
  State<_AllRestaurantsTab> createState() => _AllRestaurantsTabState();
}

class _AllRestaurantsTabState extends State<_AllRestaurantsTab> {
  final _repo = AdminRepository();
  final _mapRepo = MapRepository();
  bool _loading = true;
  List<Restaurant> _restaurants = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _restaurants = await _repo.fetchAllRestaurants();
    } catch (_) {
      _restaurants = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _editCoordinates(Restaurant r) async {
    final latCtrl = TextEditingController(
        text: (r.lat != 0) ? r.lat.toString() : '');
    final lngCtrl = TextEditingController(
        text: (r.lng != 0) ? r.lng.toString() : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${r.name} 좌표 편집'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: '위도 (lat)', hintText: '예: 37.4979'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lngCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: '경도 (lng)', hintText: '예: 127.0276'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('저장', style: TextStyle(color: AppColors.orange))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final lat = double.tryParse(latCtrl.text.trim());
    final lng = double.tryParse(lngCtrl.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('올바른 숫자를 입력하세요.')));
      return;
    }
    final success = await _mapRepo.updateRestaurantCoordinates(r.id, lat, lng);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좌표가 저장됐어요. 이제 지도에 표시됩니다.')));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좌표 저장에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_restaurants.isEmpty) {
      return const Center(
          child: Text('등록된 가게가 없습니다.',
              style: TextStyle(color: AppColors.textGray)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _restaurants.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = _restaurants[i];
          final hasCoords = r.lat != 0 && r.lng != 0;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: hasCoords ? AppColors.softGray : Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    if (!hasCoords)
                      const Icon(Icons.warning_amber,
                          color: Colors.amber, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(r.address,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGray)),
                const SizedBox(height: 4),
                Text(
                  hasCoords
                      ? '위도 ${r.lat.toStringAsFixed(4)} · 경도 ${r.lng.toStringAsFixed(4)}'
                      : '좌표 없음 — 지도에 표시 안 됨',
                  style: TextStyle(
                      fontSize: 11,
                      color: hasCoords ? AppColors.midGray : Colors.amber.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  '노출: ${r.displayStatus} · 검증: ${r.verificationStatus}',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.midGray),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_location_alt, size: 15),
                    label: Text(
                        hasCoords ? '좌표 수정' : '좌표 입력 (지도 표시용)',
                        style: const TextStyle(fontSize: 13)),
                    onPressed: () => _editCoordinates(r),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          hasCoords ? AppColors.darkInk : AppColors.orange,
                      side: BorderSide(
                          color: hasCoords
                              ? AppColors.softGray
                              : AppColors.orange),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  final _repo = AdminRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _reports = await _repo.fetchReports();
    } catch (_) {
      _reports = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _mark(String id, String status) async {
    try {
      await _repo.updateReportStatus(id, status);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상태 변경에 실패했습니다.')),
        );
      }
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'reviewed':
        return '검토됨';
      case 'resolved':
        return '처리완료';
      default:
        return '대기중';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_reports.isEmpty) {
      return const Center(
          child: Text('접수된 신고가 없습니다.',
              style: TextStyle(color: AppColors.textGray)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = _reports[i];
          final status = r['status'] as String?;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.softGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r['reason'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      _statusLabel(status),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange),
                    ),
                  ],
                ),
                if (r['detail'] != null) ...[
                  const SizedBox(height: 4),
                  Text('${r['detail']}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.darkInk)),
                ],
                const SizedBox(height: 4),
                Text(
                  '유형: ${r['recommendation_type'] ?? '-'}',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.midGray),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (status != 'reviewed')
                      TextButton(
                        onPressed: () => _mark(r['id'] as String, 'reviewed'),
                        child: const Text('검토됨으로'),
                      ),
                    if (status != 'resolved')
                      TextButton(
                        onPressed: () => _mark(r['id'] as String, 'resolved'),
                        child: const Text('처리완료',
                            style: TextStyle(color: AppColors.orange)),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
