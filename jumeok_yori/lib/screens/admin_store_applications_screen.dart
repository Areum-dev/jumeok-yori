import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/owner_store_application.dart';
import '../repositories/admin_repository.dart';
import '../repositories/map_repository.dart';
import '../services/geocoding_service.dart';
import '../theme/app_theme.dart';

class AdminStoreApplicationsScreen extends StatefulWidget {
  const AdminStoreApplicationsScreen({super.key});

  @override
  State<AdminStoreApplicationsScreen> createState() =>
      _AdminStoreApplicationsScreenState();
}

class _AdminStoreApplicationsScreenState
    extends State<AdminStoreApplicationsScreen> {
  final _repo = AdminRepository();
  final _mapRepo = MapRepository();
  bool _loading = true;
  List<OwnerStoreApplication> _apps = [];

  // 신청 id 별 좌표 / 진행상태
  final Map<String, double?> _lat = {};
  final Map<String, double?> _lng = {};
  final Set<String> _geocoding = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _apps = await _repo.fetchPendingApplications();
      for (final a in _apps) {
        _lat[a.id] = a.lat;
        _lng[a.id] = a.lng;
      }
    } catch (_) {
      _apps = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _geocodeAddress(String address, String applicationId) async {
    setState(() => _geocoding.add(applicationId));
    final result = await GeocodingService.geocodeAddress(address);
    if (!mounted) return;
    setState(() => _geocoding.remove(applicationId));
    if (result.success) {
      setState(() {
        _lat[applicationId] = result.lat;
        _lng[applicationId] = result.lng;
      });
      await _mapRepo.updateApplicationCoordinates(
        applicationId,
        result.lat!,
        result.lng!,
      );
      _snack('좌표 변환 완료: ${result.lat}, ${result.lng}');
    } else {
      _snack(result.errorMessage ?? '좌표 변환 실패');
    }
  }

  Future<void> _editCoordinates(String applicationId) async {
    final latCtrl = TextEditingController(
      text: _lat[applicationId]?.toString() ?? '',
    );
    final lngCtrl = TextEditingController(
      text: _lng[applicationId]?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('좌표 직접 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: '위도 (lat)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lngCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: '경도 (lng)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final lat = double.tryParse(latCtrl.text.trim());
    final lng = double.tryParse(lngCtrl.text.trim());
    if (lat == null || lng == null) {
      _snack('올바른 숫자를 입력하세요.');
      return;
    }
    setState(() {
      _lat[applicationId] = lat;
      _lng[applicationId] = lng;
    });
    await _mapRepo.updateApplicationCoordinates(applicationId, lat, lng);
    _snack('좌표가 저장됐어요.');
  }

  Future<void> _approve(OwnerStoreApplication app) async {
    try {
      await _repo.approveApplication(app, lat: _lat[app.id], lng: _lng[app.id]);
      _snack('승인되었습니다.');
      _load();
    } catch (_) {
      _snack('승인 중 오류가 발생했습니다.');
    }
  }

  Future<void> _reject(OwnerStoreApplication app) async {
    final note = await _askNote();
    if (note == null) return;
    try {
      await _repo.rejectApplication(app.id, note);
      _snack('반려되었습니다.');
      _load();
    } catch (_) {
      _snack('반려 중 오류가 발생했습니다.');
    }
  }

  Future<String?> _askNote() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('반려 사유'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '사유를 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('반려'),
          ),
        ],
      ),
    );
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_apps.isEmpty) {
      return const Center(
        child: Text(
          '대기 중인 가게 신청이 없습니다.',
          style: TextStyle(color: AppColors.textGray),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _apps.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _card(_apps[i]),
      ),
    );
  }

  Widget _card(OwnerStoreApplication a) {
    final lat = _lat[a.id];
    final lng = _lng[a.id];
    final busy = _geocoding.contains(a.id);
    return Container(
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
            a.storeName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          _row('사업자번호', a.businessNumber),
          if (a.ownerName != null) _row('대표자', a.ownerName!),
          if (a.phone != null) _row('전화', a.phone!),
          if (a.address != null) _row('주소', a.address!),
          if (a.category != null) _row('카테고리', a.category!),
          const SizedBox(height: 12),
          _coordinateSection(a, lat, lng, busy),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approve(a),
                  child: const Text('승인'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(a),
                  child: const Text('반려'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coordinateSection(
    OwnerStoreApplication a,
    double? lat,
    double? lng,
    bool busy,
  ) {
    final hasAddress = a.address != null && a.address!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주먹지도 좌표',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.darkInk,
          ),
        ),
        const SizedBox(height: 6),
        if (lat != null && lng != null) ...[
          Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.success, size: 16),
              SizedBox(width: 6),
              Text(
                '좌표 자동 변환 완료',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '위도 $lat / 경도 $lng',
            style: const TextStyle(fontSize: 12, color: AppColors.textGray),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_amber, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '좌표가 없어 지도에 표시되지 않습니다.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 16),
                label: const Text('주소 좌표 변환', style: TextStyle(fontSize: 13)),
                onPressed: (!hasAddress || busy)
                    ? null
                    : () => _geocodeAddress(a.address!, a.id),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ),
            if (AppConfig.allowManualLatLngEditByAdmin) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_location_alt, size: 16),
                  label: const Text('직접 입력', style: TextStyle(fontSize: 13)),
                  onPressed: () => _editCoordinates(a.id),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      '$label: $value',
      style: const TextStyle(fontSize: 13, color: AppColors.textGray),
    ),
  );
}
