import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../repositories/admin_repository.dart';
import '../theme/app_theme.dart';

class AdminMenuApplicationsScreen extends StatefulWidget {
  const AdminMenuApplicationsScreen({super.key});

  @override
  State<AdminMenuApplicationsScreen> createState() =>
      _AdminMenuApplicationsScreenState();
}

class _AdminMenuApplicationsScreenState
    extends State<AdminMenuApplicationsScreen> {
  final _repo = AdminRepository();
  bool _loading = true;
  List<MenuItem> _menus = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _menus = await _repo.fetchPendingMenus();
    } catch (_) {
      _menus = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(MenuItem m) async {
    try {
      await _repo.approveMenu(m.id);
      _snack('승인되었습니다.');
      _load();
    } catch (_) {
      _snack('승인 중 오류가 발생했습니다.');
    }
  }

  Future<void> _reject(MenuItem m) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('반려 사유'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '사유를 입력하세요'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('반려')),
        ],
      ),
    );
    if (note == null) return;
    try {
      await _repo.rejectMenu(m.id, note);
      _snack('반려되었습니다.');
      _load();
    } catch (_) {
      _snack('반려 중 오류가 발생했습니다.');
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_menus.isEmpty) {
      return const Center(
          child: Text('대기 중인 메뉴 신청이 없습니다.',
              style: TextStyle(color: AppColors.textGray)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _menus.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final m = _menus[i];
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
                Text(m.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${m.restaurant?.name ?? ''} · ${m.priceText} · ${m.category}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textGray),
                ),
                if (m.description != null) ...[
                  const SizedBox(height: 4),
                  Text(m.description!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.midGray)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approve(m),
                        child: const Text('승인'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _reject(m),
                        child: const Text('반려'),
                      ),
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
