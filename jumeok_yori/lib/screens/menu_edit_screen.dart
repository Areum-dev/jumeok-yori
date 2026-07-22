import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../models/recommendation_filter.dart';
import '../providers/app_state.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/option_chip.dart';
import '../widgets/primary_button.dart';

/// args: Restaurant (신규 등록 시 소속 가게) 또는 MenuItem (수정 시)
class MenuEditScreen extends StatefulWidget {
  const MenuEditScreen({super.key});

  @override
  State<MenuEditScreen> createState() => _MenuEditScreenState();
}

class _MenuEditScreenState extends State<MenuEditScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _imageUrl = TextEditingController();

  String? _category;
  bool _takeout = false;
  bool _delivery = false;
  bool _solo = false;
  bool _vegan = false;
  int _spicy = 0;

  Restaurant? _restaurant;
  MenuItem? _editing;
  bool _initialized = false;

  XFile? _pickedImage;
  bool _uploading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is MenuItem) {
      _editing = args;
      _restaurant = args.restaurant;
      _name.text = args.name;
      _description.text = args.description ?? '';
      _price.text = args.price.toString();
      _imageUrl.text = args.imageUrl ?? '';
      _category = args.category;
      _takeout = args.isTakeoutAvailable;
      _delivery = args.isDeliveryAvailable;
      _solo = args.isSoloFriendly;
      _vegan = args.isVeganOption;
      _spicy = args.spicyLevel ?? 0;
    } else if (args is Restaurant) {
      _restaurant = args;
      _category = args.category;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final state = context.read<AppState>();
    final file = await StorageService.pickImage();
    if (file == null) return;
    setState(() {
      _pickedImage = file;
      _uploading = true;
    });
    String? url;
    if (state.isSupabaseMode && state.isLoggedIn) {
      url = await StorageService.uploadImage(
        file: file,
        bucket: 'menu-images',
        path: 'menu_${const Uuid().v4()}',
      );
    }
    if (!mounted) return;
    setState(() => _uploading = false);
    if (url != null) {
      _imageUrl.text = url;
      _snack('이미지가 업로드됐어요.');
    } else {
      _snack('이미지 업로드에 실패했어요. URL로 입력해주세요.');
    }
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final price = int.tryParse(_price.text.trim());
    if (_name.text.trim().isEmpty || price == null) {
      _snack('메뉴 이름과 가격을 올바르게 입력해주세요.');
      return;
    }
    if (_restaurant == null) {
      _snack('소속 가게 정보가 없습니다.');
      return;
    }

    final menu = MenuItem(
      id: _editing?.id ?? const Uuid().v4(),
      restaurantId: _restaurant!.id,
      ownerId: state.currentProfile?.id,
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      price: price,
      category: _category ?? '기타',
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      isTakeoutAvailable: _takeout,
      isDeliveryAvailable: _delivery,
      isSoloFriendly: _solo,
      isVeganOption: _vegan,
      spicyLevel: _spicy,
      source: 'owner_registered',
      approvalStatus: 'pending',
      displayStatus: 'hidden',
    );

    try {
      await state.menuRepository.submitMenu(menu);
      if (!mounted) return;
      _snack('메뉴가 등록되었습니다. 검수 후 노출됩니다.');
      Navigator.pop(context);
    } catch (_) {
      _snack('등록 중 오류가 발생했습니다.');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: Text(_editing == null ? '메뉴 등록' : '메뉴 수정')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _menuImageArea(),
            const SizedBox(height: 16),
            _field(_name, '메뉴 이름 *'),
            _field(_price, '가격 (원) *', keyboard: TextInputType.number),
            _field(_description, '메뉴 설명', maxLines: 3),
            _field(_imageUrl, '이미지 URL (직접 입력 시)'),
            const SizedBox(height: 16),
            const Text(
              '카테고리',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.darkInk,
              ),
            ),
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
            const Text(
              '옵션',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.darkInk,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OptionChip(
                  label: '혼밥',
                  selected: _solo,
                  onTap: () => setState(() => _solo = !_solo),
                ),
                OptionChip(
                  label: '포장',
                  selected: _takeout,
                  onTap: () => setState(() => _takeout = !_takeout),
                ),
                OptionChip(
                  label: '배달',
                  selected: _delivery,
                  onTap: () => setState(() => _delivery = !_delivery),
                ),
                OptionChip(
                  label: '비건',
                  selected: _vegan,
                  onTap: () => setState(() => _vegan = !_vegan),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '매운맛 단계: $_spicy',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.darkInk,
              ),
            ),
            Slider(
              value: _spicy.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              label: '$_spicy',
              activeColor: AppColors.orange,
              onChanged: (v) => setState(() => _spicy = v.round()),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: '저장하기', onPressed: _submit),
          ],
        ),
      ),
    );
  }

  Widget _menuImageArea() {
    final existingUrl = _imageUrl.text.trim();
    return GestureDetector(
      onTap: _uploading ? null : _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.softGray),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: _uploading
            ? const Center(child: CircularProgressIndicator())
            : _pickedImage != null
            ? FutureBuilder(
                future: _pickedImage!.readAsBytes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                },
              )
            : existingUrl.isNotEmpty
            ? Image.network(
                existingUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.midGray),
      SizedBox(height: 8),
      Text('메뉴 사진을 추가해 주세요', style: TextStyle(color: AppColors.textGray)),
    ],
  );

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
    ),
  );
}
