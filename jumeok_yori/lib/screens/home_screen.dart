import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/login_required_dialog.dart';
import '../widgets/logo_widget.dart';
import '../widgets/primary_button.dart';
import '../widgets/result_summary_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Row(
          children: [
            const LogoWidget(size: 32, showText: false),
            const SizedBox(width: 10),
            const Text('주먹요리'),
            if (state.isSupabaseMode) ...[
              const SizedBox(width: 8),
              _modeBadge(),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: '마이페이지',
            onPressed: () => Navigator.pushNamed(context, '/my-page'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                '고민 끝.\n오늘은 이거.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkInk,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '조건만 정해. 메뉴는 주먹요리가 고른다.',
                style: TextStyle(fontSize: 14, color: AppColors.textGray),
              ),

              const SizedBox(height: 20),
              _locationBadge(context, state),

              const SizedBox(height: 16),
              _filterSummaryCard(context, state),

              const SizedBox(height: 24),
              PrimaryButton(
                label: '오늘 뭐 먹지? ✊',
                onPressed: state.isLoading
                    ? null
                    : () => Navigator.pushNamed(context, '/draw-loading'),
              ),

              if (state.history.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text(
                  '최근 추천',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkInk,
                  ),
                ),
                const SizedBox(height: 10),
                ...state.history.take(3).map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ResultSummaryCard(
                          result: r,
                          onTap: () {
                            context.read<AppState>().currentRecommendation = r;
                            Navigator.pushNamed(context, '/result');
                          },
                        ),
                      ),
                    ),
              ],

              if (state.loadError != null) ...[
                const SizedBox(height: 16),
                _errorBox(state.loadError!),
              ],

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  if (!state.isLoggedIn) {
                    LoginRequiredDialog.show(context);
                  } else {
                    Navigator.pushNamed(context, '/owner-apply');
                  }
                },
                icon: const Icon(Icons.storefront_outlined,
                    color: AppColors.textGray),
                label: const Text(
                  '내 가게 등록하기',
                  style: TextStyle(color: AppColors.textGray),
                ),
              ),
              if (state.isOwner)
                TextButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/owner-dashboard'),
                  icon: const Icon(Icons.dashboard_outlined,
                      color: AppColors.textGray),
                  label: const Text(
                    '사장님 대시보드',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                ),
              if (state.isAdmin)
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/admin'),
                  icon: const Icon(Icons.admin_panel_settings_outlined,
                      color: AppColors.orange),
                  label: const Text(
                    '관리자 페이지',
                    style: TextStyle(color: AppColors.orange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('LIVE',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.success)),
      );

  Widget _locationBadge(BuildContext context, AppState state) =>
      GestureDetector(
        onTap: () => context.read<AppState>().initLocation(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.softGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.isDefaultLocation
                    ? Icons.location_off_outlined
                    : Icons.location_on_rounded,
                size: 16,
                color: state.isDefaultLocation
                    ? AppColors.textGray
                    : AppColors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                state.locationLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: state.isDefaultLocation
                      ? AppColors.textGray
                      : AppColors.darkInk,
                ),
              ),
              const SizedBox(width: 4),
              const Text('· 새로고침',
                  style: TextStyle(fontSize: 11, color: AppColors.midGray)),
            ],
          ),
        ),
      );

  Widget _filterSummaryCard(BuildContext context, AppState state) =>
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/filter'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.softGray),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 필터',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGray,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.filter.summaryText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkInk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '수정',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _errorBox(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: const TextStyle(color: AppColors.error, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
}
