import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recommendation_result.dart';
import '../providers/app_state.dart';
import '../services/map_launcher_service.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/option_chip.dart';
import '../widgets/report_dialog.dart';

class RecommendationResultScreen extends StatelessWidget {
  const RecommendationResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final result = state.currentRecommendation;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('추천 결과가 없습니다.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('오늘의 추천')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: result.isRegistered
              ? _RegisteredView(result: result)
              : _StarterView(result: result),
        ),
      ),
    );
  }
}

Widget _heroImage(String? url) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Container(
      height: 200,
      width: double.infinity,
      color: AppColors.softGray,
      child: url == null
          ? const Center(child: Text('🍽️', style: TextStyle(fontSize: 64)))
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Center(
                  child: Text('🍽️', style: TextStyle(fontSize: 64))),
            ),
    ),
  );
}

Widget _tags(List<String> tags) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((t) => OptionChip(label: t)).toList(),
    );

Widget _actionRow({
  required bool isSaved,
  required VoidCallback onSave,
  required VoidCallback onRedraw,
  required VoidCallback onMap,
  required VoidCallback onShare,
  required VoidCallback onReport,
  required String mapLabel,
}) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onSave,
              icon: Icon(
                isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isSaved ? AppColors.orange : AppColors.darkInk,
              ),
              label: Text(isSaved ? '저장됨' : '저장'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRedraw,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시뽑기'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onMap,
          icon: const Icon(Icons.map_outlined),
          label: Text(mapLabel),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined),
          label: const Text('친구에게 공유'),
        ),
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: onReport,
        icon: const Icon(Icons.flag_outlined,
            size: 16, color: AppColors.midGray),
        label: const Text('정보 오류 신고',
            style: TextStyle(fontSize: 13, color: AppColors.midGray)),
      ),
    ],
  );
}

/// 저장 처리: 비로그인 시 로그인 유도, 로그인 시 저장 후 스낵바.
Future<void> _handleSave(BuildContext context, RecommendationResult r) async {
  final state = context.read<AppState>();
  final wasSaved = state.isSaved(r);
  final needLogin = await state.toggleSave(r);
  if (!context.mounted) return;
  if (needLogin) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('저장하려면 로그인이 필요해요.'),
        action: SnackBarAction(
          label: '로그인',
          onPressed: () => Navigator.pushNamed(context, '/auth'),
        ),
      ),
    );
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(wasSaved ? '저장을 취소했어요.' : '저장됐어요!')),
  );
}

void _handleReport(BuildContext context, RecommendationResult r) {
  final state = context.read<AppState>();
  ReportDialog.show(
    context,
    menuItemId: r.menuItem?.id,
    starterMenuId: r.starterMenu?.id,
    restaurantId: r.restaurant?.id,
    recommendationType: r.type,
    userId: state.currentProfile?.id,
    anonymousUserId: state.anonymousUserId,
  );
}

class _RegisteredView extends StatelessWidget {
  final RecommendationResult result;
  const _RegisteredView({required this.result});

  @override
  Widget build(BuildContext context) {
    final menu = result.menuItem!;
    final r = result.restaurant;
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heroImage(menu.imageUrl),
        const SizedBox(height: 16),
        const Text('오늘은 이거.',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray)),
        const SizedBox(height: 6),
        Text(
          menu.name,
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.darkInk),
        ),
        if (r != null) ...[
          const SizedBox(height: 4),
          Text(r.name,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGray)),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            _badge(menu.priceText, AppColors.orange, AppColors.orangeLight),
            const SizedBox(width: 8),
            if (result.distanceText.isNotEmpty)
              _badge(result.distanceText, AppColors.darkInk,
                  AppColors.softGray),
            const SizedBox(width: 8),
            _badge(menu.category, AppColors.textGray, AppColors.softGray),
          ],
        ),
        if (menu.conditionTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _tags(menu.conditionTags),
        ],
        if (menu.description != null) ...[
          const SizedBox(height: 16),
          Text(menu.description!,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.darkInk, height: 1.5)),
        ],
        if (r != null) ...[
          const SizedBox(height: 20),
          _infoRow(Icons.location_on_outlined, r.address),
          if (r.phone != null) _infoRow(Icons.phone_outlined, r.phone!),
        ],
        const SizedBox(height: 28),
        _actionRow(
          isSaved: state.isSaved(result),
          onSave: () => _handleSave(context, result),
          onRedraw: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/draw-loading');
          },
          onMap: () => MapLauncherService.openNaverDirectionsOrSearch(
            restaurantName: r?.name,
            menuName: menu.name,
            address: r?.address,
            lat: r?.lat,
            lng: r?.lng,
            recommendationType: 'registered',
            context: context,
          ),
          onShare: () => ShareService.shareRecommendation(result),
          onReport: () => _handleReport(context, result),
          mapLabel: '길찾기',
        ),
      ],
    );
  }
}

class _StarterView extends StatelessWidget {
  final RecommendationResult result;
  const _StarterView({required this.result});

  @override
  Widget build(BuildContext context) {
    final menu = result.starterMenu!;
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heroImage(menu.imageUrl),
        const SizedBox(height: 16),
        const Text('오늘은',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray)),
        const SizedBox(height: 6),
        Text(
          menu.name,
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.darkInk),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _badge(menu.priceRangeText, AppColors.orange,
                AppColors.orangeLight),
            const SizedBox(width: 8),
            _badge(menu.category, AppColors.textGray, AppColors.softGray),
          ],
        ),
        if (menu.conditionTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _tags(menu.conditionTags),
        ],
        if (menu.description != null) ...[
          const SizedBox(height: 16),
          Text(menu.description!,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.darkInk, height: 1.5)),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.softGray),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: AppColors.textGray),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '근처에서 이 메뉴를 찾아보세요.',
                  style: TextStyle(fontSize: 13, color: AppColors.textGray),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _actionRow(
          isSaved: state.isSaved(result),
          onSave: () => _handleSave(context, result),
          onRedraw: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/draw-loading');
          },
          onMap: () => MapLauncherService.openNaverDirectionsOrSearch(
            menuName: menu.searchKeyword ?? menu.name,
            recommendationType: 'starter',
            context: context,
          ),
          onShare: () => ShareService.shareRecommendation(result),
          onReport: () => _handleReport(context, result),
          mapLabel: '네이버지도에서 찾기',
        ),
      ],
    );
  }
}

Widget _badge(String text, Color fg, Color bg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: fg),
      ),
    );

Widget _infoRow(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textGray),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.darkInk)),
          ),
        ],
      ),
    );
