import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/owner_store_application.dart';
import '../models/recommendation_filter.dart';
import '../providers/app_state.dart';
import '../services/geocoding_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/option_chip.dart';
import '../widgets/primary_button.dart';

class OwnerStoreApplicationScreen extends StatefulWidget {
  const OwnerStoreApplicationScreen({super.key});

  @override
  State<OwnerStoreApplicationScreen> createState() =>
      _OwnerStoreApplicationScreenState();
}

class _OwnerStoreApplicationScreenState
    extends State<OwnerStoreApplicationScreen> {
  final _bizNum = TextEditingController();
  final _storeName = TextEditingController();
  final _ownerName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _detailAddress = TextEditingController();
  final _description = TextEditingController();
  final _openingHours = TextEditingController();
  final _licenseUrl = TextEditingController();

  String? _category;
  bool _takeout = false;
  bool _delivery = false;

  XFile? _licenseImage;
  String? _uploadedLicenseUrl;
  bool _uploading = false;
  bool _showUrlFallback = false;

  @override
  void dispose() {
    for (final c in [
      _bizNum,
      _storeName,
      _ownerName,
      _phone,
      _address,
      _detailAddress,
      _description,
      _openingHours,
      _licenseUrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLicense() async {
    final state = context.read<AppState>();
    final file = await StorageService.pickImage();
    if (file == null) return;
    setState(() {
      _licenseImage = file;
      _uploading = true;
    });
    String? url;
    if (state.isSupabaseMode && state.isLoggedIn) {
      url = await StorageService.uploadImage(
        file: file,
        bucket: 'business-licenses',
        path: '${state.currentProfile!.id}/license_${const Uuid().v4()}',
      );
    }
    if (!mounted) return;
    setState(() {
      _uploadedLicenseUrl = url;
      _uploading = false;
      _showUrlFallback = url == null;
    });
    if (url == null) {
      _snack('이미지 업로드에 실패했어요. URL로 입력해주세요.');
    }
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    if (_bizNum.text.trim().isEmpty || _storeName.text.trim().isEmpty) {
      _snack('사업자번호와 가게 이름은 필수입니다.');
      return;
    }
    if (!state.isLoggedIn) {
      _snack('가게 등록은 로그인 후 이용할 수 있습니다.');
      return;
    }

    // 주소 자동 지오코딩 (저장 전)
    double? lat;
    double? lng;
    String geocodingStatus = 'skipped_no_api_key';
    String? geocodingError;
    final address = _address.text.trim();
    if (address.isNotEmpty) {
      try {
        final result = await GeocodingService.geocodeAddress(address);
        if (result.success) {
          lat = result.lat;
          lng = result.lng;
          geocodingStatus = 'success';
        } else {
          geocodingStatus = 'failed';
          geocodingError = result.errorMessage;
        }
      } catch (e) {
        geocodingStatus = 'failed';
        geocodingError = e.toString();
      }
    } else {
      geocodingStatus = 'skipped_no_address';
    }

    final app = OwnerStoreApplication(
      id: const Uuid().v4(),
      userId: state.currentProfile!.id,
      businessNumber: _bizNum.text.trim(),
      storeName: _storeName.text.trim(),
      ownerName: _ownerName.text.trim().isEmpty ? null : _ownerName.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      address: address.isEmpty ? null : address,
      detailAddress:
          _detailAddress.text.trim().isEmpty ? null : _detailAddress.text.trim(),
      category: _category,
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      openingHours:
          _openingHours.text.trim().isEmpty ? null : _openingHours.text.trim(),
      isTakeoutAvailable: _takeout,
      isDeliveryAvailable: _delivery,
      businessLicenseImageUrl: _uploadedLicenseUrl ??
          (_licenseUrl.text.trim().isEmpty ? null : _licenseUrl.text.trim()),
      lat: lat,
      lng: lng,
      geocodingStatus: geocodingStatus,
      geocodingError: geocodingError,
    );

    try {
      await state.submitStoreApplication(app);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('신청 완료'),
          content: const Text('가게 등록 신청이 접수되었습니다.\n관리자 검수 후 승인됩니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (_) {
      _snack('신청 중 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('내 가게 등록 신청')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!state.isLoggedIn)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '가게 등록은 로그인 후 이용할 수 있습니다.',
                  style: TextStyle(color: AppColors.orange, fontSize: 13),
                ),
              ),
            _field(_bizNum, '사업자등록번호 *'),
            _field(_storeName, '가게 이름 *'),
            _field(_ownerName, '대표자명'),
            _field(_phone, '전화번호', keyboard: TextInputType.phone),
            _field(_address, '주소'),
            _field(_detailAddress, '상세주소'),
            _field(_openingHours, '영업시간 (예: 11:00~21:00)'),
            _field(_description, '가게 소개', maxLines: 3),
            const SizedBox(height: 12),
            const Text('카테고리',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.darkInk)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategoryOptions.where((c) => c != '전체').map((c) {
                return OptionChip(
                  label: c,
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                OptionChip(
                  label: '포장 가능',
                  icon: Icons.takeout_dining_outlined,
                  selected: _takeout,
                  onTap: () => setState(() => _takeout = !_takeout),
                ),
                OptionChip(
                  label: '배달 가능',
                  icon: Icons.delivery_dining_outlined,
                  selected: _delivery,
                  onTap: () => setState(() => _delivery = !_delivery),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('사업자등록증',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.darkInk)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _uploading ? null : _pickLicense,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.softGray),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _uploading
                    ? const Center(child: CircularProgressIndicator())
                    : _licenseImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _imagePreview(_licenseImage!),
                              ),
                              if (_uploadedLicenseUrl != null)
                                const Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Icon(Icons.check_circle,
                                      color: AppColors.success),
                                ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_outlined,
                                  size: 32, color: AppColors.midGray),
                              SizedBox(height: 8),
                              Text('사업자등록증 업로드',
                                  style: TextStyle(color: AppColors.textGray)),
                            ],
                          ),
              ),
            ),
            if (_showUrlFallback) ...[
              const SizedBox(height: 12),
              _field(_licenseUrl, '사업자등록증 이미지 URL'),
              const Text(
                '※ 업로드가 안 될 경우 URL로 입력해주세요.',
                style: TextStyle(fontSize: 11, color: AppColors.midGray),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: '등록 신청하기',
              isLoading: state.isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview(XFile file) => FutureBuilder(
        future: file.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        },
      );

  Widget _field(TextEditingController c, String label,
          {int maxLines = 1, TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
