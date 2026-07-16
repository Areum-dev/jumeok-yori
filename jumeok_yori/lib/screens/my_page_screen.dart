import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/logo_widget.dart';
import '../widgets/result_summary_card.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

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
                    _list(context, state.savedItems, '저장한 메뉴가 없어요.'),
                    _list(context, state.history, '추천 기록이 없어요.'),
                  ],
                ),
              ),
            ],
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
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.orange,
                child: Text(
                  profile?.displayName?.characters.first ?? '게',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile?.displayName ?? '게스트',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        if (state.isSupabaseMode) _badge('LIVE', AppColors.success),
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
                          fontSize: 13, color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isOwner)
            _linkTile(context, Icons.dashboard_outlined, '사장님 대시보드',
                '/owner-dashboard'),
          if (state.isAdmin)
            _linkTile(context, Icons.admin_panel_settings_outlined,
                '관리자 페이지', '/admin'),
          _linkTile(context, Icons.storefront_outlined, '내 가게 등록하기',
              '/owner-apply'),
          const Divider(color: AppColors.softGray, height: 16),
          _linkTile(context, Icons.settings_outlined, '설정', '/settings'),
          if (state.isLoggedIn) ...[
            _linkTile(context, Icons.person_outline_rounded, '개인정보 조회/수정',
                '/settings'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined,
                  color: AppColors.textGray),
              title: const Text('위치 권한 설정',
                  style: TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.midGray),
              onTap: () async {
                await Geolocator.openAppSettings();
              },
            ),
            _linkTile(context, Icons.notifications_outlined, '마케팅 수신 변경',
                '/settings'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_off_outlined,
                  color: AppColors.error),
              title: const Text('회원탈퇴',
                  style: TextStyle(fontSize: 14, color: AppColors.error)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.midGray),
              onTap: () =>
                  Navigator.pushNamed(context, '/account-deletion'),
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
                        context, '/auth', (_) => false);
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
          BuildContext context, IconData icon, String label, String route) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.textGray),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: AppColors.midGray),
        onTap: () => Navigator.pushNamed(context, route),
      );

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      );

  Widget _list(BuildContext context, List items, String emptyMsg) {
    if (items.isEmpty) {
      return EmptyState(emoji: '🍱', title: emptyMsg);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => ResultSummaryCard(
        result: items[i],
        onTap: () {
          context.read<AppState>().currentRecommendation = items[i];
          Navigator.pushNamed(context, '/result');
        },
      ),
    );
  }
}
