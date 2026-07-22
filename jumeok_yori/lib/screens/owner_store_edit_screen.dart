import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant.dart';
import '../services/geocoding_service.dart';
import '../theme/app_theme.dart';

/// 사장님이 자신의 가게 정보를 직접 수정하는 화면.
/// 주소가 바뀌면 자동으로 좌표를 다시 지오코딩합니다.
class OwnerStoreEditScreen extends StatefulWidget {
  final Restaurant restaurant;
  const OwnerStoreEditScreen({super.key, required this.restaurant});
  @override
  State<OwnerStoreEditScreen> createState() => _OwnerStoreEditScreenState();
}

class _OwnerStoreEditScreenState extends State<OwnerStoreEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _detailAddressCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _openingHoursCtrl;
  bool _isTakeout = false;
  bool _isDelivery = false;
  bool _saving = false;
  bool _geocodingFailed = false;
  double? _manualLat;
  double? _manualLng;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    final r = widget.restaurant;
    _nameCtrl = TextEditingController(text: r.name);
    _phoneCtrl = TextEditingController(text: r.phone ?? '');
    _addressCtrl = TextEditingController(text: r.address);
    _detailAddressCtrl = TextEditingController(text: r.detailAddress ?? '');
    _descriptionCtrl = TextEditingController(text: r.description ?? '');
    _categoryCtrl = TextEditingController(text: r.category ?? '');
    _openingHoursCtrl = TextEditingController(text: r.openingHours ?? '');
    _isTakeout = r.isTakeoutAvailable;
    _isDelivery = r.isDeliveryAvailable;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _detailAddressCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    _openingHoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('가게 이름을 입력해 주세요.');
      return;
    }
    setState(() => _saving = true);

    final address = _addressCtrl.text.trim();
    final oldAddress = widget.restaurant.address;
    // 수동 입력 좌표 우선, 없으면 기존 좌표, 그것도 없으면 null
    double? newLat =
        _manualLat ??
        (widget.restaurant.lat != 0 ? widget.restaurant.lat : null);
    double? newLng =
        _manualLng ??
        (widget.restaurant.lng != 0 ? widget.restaurant.lng : null);
    bool geocodingFailed = false;

    // 수동 좌표가 없고 (주소 변경 or 좌표 없음) → 자동 지오코딩 시도
    if (_manualLat == null &&
        address.isNotEmpty &&
        (address != oldAddress || newLat == null)) {
      try {
        final result = await GeocodingService.geocodeAddress(address);
        if (result.success) {
          newLat = result.lat;
          newLng = result.lng;
        } else {
          geocodingFailed = true;
        }
      } catch (_) {
        geocodingFailed = true;
      }
    }

    final client = _client;
    if (client == null) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('저장에 실패했어요. 잠시 후 다시 시도해 주세요.');
      }
      return;
    }

    try {
      final updates = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isNotEmpty
            ? _phoneCtrl.text.trim()
            : null,
        'address': address,
        'detail_address': _detailAddressCtrl.text.trim().isNotEmpty
            ? _detailAddressCtrl.text.trim()
            : null,
        'description': _descriptionCtrl.text.trim().isNotEmpty
            ? _descriptionCtrl.text.trim()
            : null,
        'category': _categoryCtrl.text.trim().isNotEmpty
            ? _categoryCtrl.text.trim()
            : null,
        'opening_hours': _openingHoursCtrl.text.trim().isNotEmpty
            ? _openingHoursCtrl.text.trim()
            : null,
        'is_takeout_available': _isTakeout,
        'is_delivery_available': _isDelivery,
        'lat': ?newLat,
        'lng': ?newLng,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client
          .from('restaurants')
          .update(updates)
          .eq('id', widget.restaurant.id);

      if (!mounted) return;
      setState(() => _saving = false);

      if (mounted) {
        setState(() => _geocodingFailed = geocodingFailed && newLat == null);
      }
      if (geocodingFailed && newLat == null) {
        _snack('주소는 저장됐지만 좌표 변환에 실패했어요. 아래에서 직접 입력해 주세요.');
        setState(() => _saving = false);
        return; // 페이지 유지 — 사장님이 직접 좌표 입력 가능
      }
      _snack('가게 정보가 수정됐어요.');
      Navigator.pop(context, true); // true = 새로고침 필요
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('저장에 실패했어요: $e');
      }
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text(
          '가게 정보 수정',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.orange,
                    ),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field('가게 이름 *', _nameCtrl),
          _field('전화번호', _phoneCtrl, keyboardType: TextInputType.phone),
          _field('주소', _addressCtrl),
          _field('상세주소', _detailAddressCtrl),
          _field('카테고리', _categoryCtrl, hint: '예: 한식, 중식, 분식'),
          _field('가게 설명', _descriptionCtrl, maxLines: 3),
          _field('영업시간', _openingHoursCtrl, hint: '예: 11:00 - 21:00'),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('포장 가능'),
            value: _isTakeout,
            onChanged: (v) => setState(() => _isTakeout = v),
            activeThumbColor: AppColors.orange,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('배달 가능'),
            value: _isDelivery,
            onChanged: (v) => setState(() => _isDelivery = v),
            activeThumbColor: AppColors.orange,
            contentPadding: EdgeInsets.zero,
          ),
          if (_geocodingFailed) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amber, size: 18),
                      SizedBox(width: 6),
                      Text(
                        '자동 좌표 변환 실패',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '주소로 자동 좌표를 찾지 못했어요.\n지도에 표시하려면 아래에 위도/경도를 직접 입력해 주세요.\n(구글 지도에서 가게 주소 검색 후 핀 탭 → 좌표 복사)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _coordField(
                          '위도 (예: 37.4979)',
                          (v) => _manualLat = double.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _coordField(
                          '경도 (예: 127.0276)',
                          (v) => _manualLng = double.tryParse(v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '저장하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coordField(String hint, void Function(String) onChanged) => TextField(
    keyboardType: const TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    ),
    decoration: InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    onChanged: (v) {
      setState(() {
        onChanged(v);
      });
    },
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    String? hint,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );
}
