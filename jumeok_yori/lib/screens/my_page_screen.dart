import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/recommendation_result.dart';
import '../providers/app_state.dart';
import '../services/map_launcher_service.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/logo_widget.dart';
import '../widgets/my_page_entry_card.dart';

/// 마이페이지. 홈 화면 우측 상단 사람 아이콘(/my-page 라우트)과 하단 탭
/// 모두 이 위젯을 그대로 사용한다 - 두 진입 경로가 서로 다른 화면처럼
/// 보이는 문제를 피하기 위해 공통 화면/공통 provider(AppState)를 쓴다.
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 서버 최신 상태로 새로고침 (저장 직후 이동한 경우는 이미
    // AppState 에 반영돼 있어 여기서 다시 불러와도 화면이 튀지 않는다).
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final state = context.read<AppState>();
    if (!state.isLoggedIn) return;
    await Future.wait([state.loadSaved(), state.loadHistory()]);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          title: const Text('마이페이지'),
          bottom: const TabBar(
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.textGray,
            indicatorColor: AppColors.orange,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            tabs: [
              Tab(text: '저장한 메뉴'),
              Tab(text: '추천 기록'),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _profileHeader(context, state),
              Expanded(
                child: TabBarView(
                  children: [
                    _savedTab(context, state),
                    _historyTab(context, state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 저장한 메뉴 탭 ──────────────────────────────────────────
  Widget _savedTab(BuildContext context, AppState state) {
    if (!state.isLoggedIn) {
      return _loginPrompt(context, '저장한 메뉴를 보려면 로그인이 필요해요.');
    }
    if (state.savedLoading && state.savedItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return _entryList(
      context,
      items: state.savedItems,
      emptyMsg: '저장한 메뉴가 없어요.',
      onRefresh: () => context.read<AppState>().loadSaved(),
      onDelete: (r) => context.read<AppState>().deleteSavedItem(r),
      deletedSnackText: '저장을 취소했어요.',
    );
  }

  // ── 추천 기록 탭 ────────────────────────────────────────────
  Widget _historyTab(BuildContext context, AppState state) {
    if (!state.isLoggedIn) {
      return _loginPrompt(context, '추천 기록을 보려면 로그인이 필요해요.');
    }
    if (state.historyLoading && state.persistentHistory.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        if (state.persistentHistory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmClearAllHistory(context),
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  size: 18,
                  color: AppColors.midGray,
                ),
                label: const Text(
                  '전체 삭제',
                  style: TextStyle(color: AppColors.midGray, fontSize: 13),
                ),
              ),
            ),
          ),
        Expanded(
          child: _entryList(
            context,
            items: state.persistentHistory,
            emptyMsg: '추천 기록이 없어요.',
            onRefresh: () => context.read<AppState>().loadHistory(),
            onDelete: (r) => context.read<AppState>().deleteHistoryEntry(r),
            deletedSnackText: '기록을 삭제했어요.',
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClearAllHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('추천 기록 전체 삭제'),
        content: const Text('모든 추천 기록을 삭제할까요? 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<AppState>().clearAllHistory();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해 주세요.')));
      }
    }
  }

  Widget _loginPrompt(BuildContext context, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 40,
            color: AppColors.midGray,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGray, fontSize: 14),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/auth'),
            child: const Text('로그인'),
          ),
        ],
      ),
    ),
  );

  Widget _entryList(
    BuildContext context, {
    required List<RecommendationResult> items,
    required String emptyMsg,
    required Future<void> Function() onRefresh,
    required Future<void> Function(RecommendationResult) onDelete,
    required String deletedSnackText,
  }) {
    // 하단 탭 바(BottomNavigationBar)에 목록 마지막 카드가 가려지지 않도록
    // 화면 하단 안전영역 + 여유 패딩을 확보한다.
    final bottomPadding = MediaQuery.of(context).padding.bottom + 88;

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomPadding),
          children: [
            SizedBox(
              height: 360,
              child: EmptyState(emoji: '🍱', title: emptyMsg),
            ),
          ],
        ),
      );
    }

    // iPad/태블릿처럼 화면이 넓을 때 카드가 지나치게 옆으로 늘어나지 않도록
    // 목록 폭에 상한을 두고 가운데 정렬한다. 일반 휴대전화 폭에서는
    // maxWidth 가 화면보다 넓어 아무 영향이 없다.
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = items[i];
              return MyPageEntryCard(
                result: r,
                onTap: () {
                  context.read<AppState>().currentRecommendation = r;
                  Navigator.pushNamed(context, '/result');
                },
                onMap: () => MapLauncherService.openDirections(
                  restaurantName: r.restaurant?.name,
                  menuName: r.menuName,
                  address: r.restaurant?.address,
                  lat: r.restaurant?.lat,
                  lng: r.restaurant?.lng,
                  recommendationType: r.type,
                  context: context,
                ),
                onShare: () => ShareService.shareRecommendation(context, r),
                onDelete: () async {
                  try {
                    await onDelete(r);
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(deletedSnackText)));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해 주세요.')),
                      );
                    }
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(BuildContext context, AppState state) {
    final profile = state.currentProfile;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: LogoWidget(size: 40, showText: false),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Builder(
                builder: (context) {
                  final avatarUrl = profile?.avatarUrl;
                  final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                  return CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.orange,
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    // 프로필 사진 로드 실패해도(만료/거절 등) 앱 기본 아바타로
                    // 자연스럽게 대체되도록 에러를 조용히 무시한다.
                    onBackgroundImageError: hasAvatar ? (_, _) {} : null,
                    child: hasAvatar
                        ? null
                        : Text(
                            profile?.displayName?.characters.first ?? '게',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                  );
                },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 이름이 길거나 시스템 글자 크기를 키운 상태에서
                        // 배지들과 함께 Row 폭을 넘지 않도록 Flexible 로 감싼다.
                        Flexible(
                          child: Text(
                            profile?.displayName ?? '게스트',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (state.isSupabaseMode)
                          _badge('LIVE', AppColors.success),
                        if (state.isAdmin) ...[
                          const SizedBox(width: 4),
                          _badge('관리자', AppColors.orange),
                        ] else if (state.isOwner) ...[
                          const SizedBox(width: 4),
                          _badge('사장님', AppColors.orange),
                        ],
                      ],
                    ),
                    Text(
                      profile?.email ?? '로그인하지 않음',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isOwner)
            _linkTile(
              context,
              Icons.dashboard_outlined,
              '사장님 대시보드',
              '/owner-dashboard',
            ),
          if (state.isAdmin)
            _linkTile(
              context,
              Icons.admin_panel_settings_outlined,
              '관리자 페이지',
              '/admin',
            ),
          _linkTile(
            context,
            Icons.storefront_outlined,
            '내 가게 등록하기',
            '/owner-apply',
          ),
          const Divider(color: AppColors.softGray, height: 16),
          _linkTile(context, Icons.settings_outlined, '설정', '/settings'),
          if (state.isLoggedIn) ...[
            _linkTile(
              context,
              Icons.person_outline_rounded,
              '개인정보 조회/수정',
              '/settings',
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.location_on_outlined,
                color: AppColors.textGray,
              ),
              title: const Text('위치 권한 설정', style: TextStyle(fontSize: 14)),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.midGray,
              ),
              onTap: () async {
                await Geolocator.openAppSettings();
              },
            ),
            _linkTile(
              context,
              Icons.notifications_outlined,
              '마케팅 수신 변경',
              '/settings',
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.person_off_outlined,
                color: AppColors.error,
              ),
              title: const Text(
                '회원탈퇴',
                style: TextStyle(fontSize: 14, color: AppColors.error),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.midGray,
              ),
              onTap: () => Navigator.pushNamed(context, '/account-deletion'),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                if (state.isLoggedIn) {
                  await context.read<AppState>().signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/auth',
                      (_) => false,
                    );
                  }
                } else {
                  Navigator.pushNamed(context, '/auth');
                }
              },
              child: Text(state.isLoggedIn ? '로그아웃' : '로그인'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkTile(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.textGray),
    title: Text(label, style: const TextStyle(fontSize: 14)),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.midGray),
    onTap: () => Navigator.pushNamed(context, route),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
    ),
  );
}
