import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class MenuManagementScreen extends StatefulWidget {
  final String restaurantId;
  final String ownerId;
  const MenuManagementScreen({
    super.key,
    required this.restaurantId,
    required this.ownerId,
  });
  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<MenuItem> _menus = [];
  bool _loading = true;

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
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client
          ?.from('menu_items')
          .select()
          .eq('restaurant_id', widget.restaurantId)
          .eq('owner_id', widget.ownerId) // 항상 현재 사용자 메뉴만 조회
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _menus = (res as List? ?? [])
              .map((r) => MenuItem.fromJson(r as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleDisplay(MenuItem m) async {
    final newStatus = m.displayStatus == 'approved' ? 'hidden' : 'approved';
    try {
      await _client
          ?.from('menu_items')
          .update({'display_status': newStatus})
          .eq('id', m.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'approved' ? '메뉴를 다시 노출했어요.' : '메뉴를 숨겼어요.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('변경에 실패했어요.')));
      }
    }
  }

  Future<void> _toggleAvailable(MenuItem m) async {
    try {
      await _client
          ?.from('menu_items')
          .update({'is_available': !m.isAvailable})
          .eq('id', m.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('변경에 실패했어요.')));
      }
    }
  }

  void _showAddMenuDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddMenuSheet(
        restaurantId: widget.restaurantId,
        ownerId: widget.ownerId,
        onMenuAdded: () {
          _load();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('메뉴가 등록됐어요.\n이제 주먹요리 뽑기와 내 가게 페이지에 노출됩니다.'),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text(
          '메뉴 관리',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMenuDialog,
        backgroundColor: AppColors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('메뉴 추가', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            )
          : _menus.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('🍽️', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    '아직 등록된 메뉴가 없어요.',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '메뉴를 추가해 뽑기에 노출해 보세요.',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: _menus.length,
              itemBuilder: (_, i) => _menuCard(_menus[i]),
            ),
    );
  }

  Widget _menuCard(MenuItem m) {
    final isHidden = m.displayStatus != 'approved';
    final isSoldOut = !m.isAvailable;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHidden ? AppColors.softGray : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isHidden
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isHidden
                              ? AppColors.midGray
                              : AppColors.darkInk,
                        ),
                      ),
                    ),
                    if (isHidden) _tag('숨김', Colors.grey),
                    if (isSoldOut && !isHidden) _tag('품절', Colors.red.shade300),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmtPrice(m.price)}원',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isHidden ? AppColors.midGray : AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'toggle_display') _toggleDisplay(m);
              if (v == 'toggle_available') _toggleAvailable(m);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle_display',
                child: Text(isHidden ? '다시 노출' : '숨기기'),
              ),
              PopupMenuItem(
                value: 'toggle_available',
                child: Text(isSoldOut ? '판매 재개' : '품절 처리'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
    ),
  );

  String _fmtPrice(int p) {
    final s = p.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _AddMenuSheet extends StatefulWidget {
  final String restaurantId;
  final String ownerId;
  final VoidCallback onMenuAdded;
  const _AddMenuSheet({
    required this.restaurantId,
    required this.ownerId,
    required this.onMenuAdded,
  });
  @override
  State<_AddMenuSheet> createState() => _AddMenuSheetState();
}

class _AddMenuSheetState extends State<_AddMenuSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  XFile? _pickedImage;
  String? _uploadedImageUrl;
  bool _uploadingImage = false;
  bool _showUrlFallback = false;
  bool _saving = false;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null) return;
      setState(() {
        _pickedImage = picked;
        _uploadingImage = true;
      });

      try {
        final client = _client;
        if (client == null) throw Exception('no client');
        final bytes = await picked.readAsBytes();
        final ext = picked.name.contains('.')
            ? picked.name.split('.').last
            : 'jpg';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'menu_$timestamp.$ext';

        await client.storage
            .from('menu-images')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
            );
        final url = client.storage.from('menu-images').getPublicUrl(path);
        if (!mounted) return;
        setState(() {
          _uploadedImageUrl = url;
          _uploadingImage = false;
        });
      } catch (e) {
        debugPrint('Upload failed: $e');
        if (!mounted) return;
        setState(() {
          _uploadingImage = false;
          _showUrlFallback = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 업로드에 실패했어요. URL을 직접 입력해 주세요.')),
        );
      }
    } catch (e) {
      debugPrint('Image pick failed: $e');
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final imageUrl =
        _uploadedImageUrl ??
        (_urlCtrl.text.trim().isNotEmpty ? _urlCtrl.text.trim() : null);

    try {
      final client = _client;
      if (client == null) throw Exception('no client');
      await client.from('menu_items').insert({
        'restaurant_id': widget.restaurantId,
        'owner_id': widget.ownerId,
        'name': _nameCtrl.text.trim(),
        'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        'image_url': ?imageUrl,
        'approval_status': 'approved',
        'display_status': 'approved',
        'is_available': true,
        'source': 'owner_registered',
      });
      await AnalyticsService.log(
        eventType: 'menu_created',
        userId: widget.ownerId,
        restaurantId: widget.restaurantId,
        ownerId: widget.ownerId,
      );
      if (mounted) Navigator.pop(context);
      widget.onMenuAdded();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '메뉴 추가',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _buildImagePicker(),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '메뉴 이름 *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: '가격 (원) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: '설명 (선택)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (_showUrlFallback) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: '이미지 URL 직접 입력',
                  border: OutlineInputBorder(),
                  hintText: 'https://...',
                ),
              ),
            ],
            const SizedBox(height: 16),
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
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '메뉴 등록하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.softGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.midGray),
        ),
        child: _uploadingImage
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              )
            : _pickedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      File(_pickedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '사진 변경',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  if (_uploadedImageUrl == null && !_uploadingImage)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.upload,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: AppColors.midGray,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '메뉴 사진 추가',
                    style: TextStyle(
                      color: AppColors.midGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    '탭하여 갤러리에서 선택',
                    style: TextStyle(fontSize: 11, color: AppColors.textGray),
                  ),
                ],
              ),
      ),
    );
  }
}
