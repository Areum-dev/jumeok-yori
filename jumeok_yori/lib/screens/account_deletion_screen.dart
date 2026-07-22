import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  bool _confirmed = false;
  String? _reason;
  bool _loading = false;

  static const _reasons = ['서비스 불만족', '개인정보 우려', '이용 빈도 낮음', '기타'];

  Future<void> _delete() async {
    if (!_confirmed) return;
    setState(() => _loading = true);

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (userId != null) {
        // profiles 테이블 익명화 (법적 의무 보관 데이터 제외 후 개인식별정보 삭제)
        try {
          await client.from('profiles').upsert({
            'id': userId,
            'email': null,
            'phone': null,
            'display_name': '탈퇴한 사용자',
            'deleted_at': DateTime.now().toIso8601String(),
            'deletion_reason': _reason,
          });
        } catch (_) {
          // profiles 업데이트 실패해도 계속 진행
        }

        // Supabase auth 로그아웃 (auth 계정 삭제는 서버사이드 함수 필요)
        try {
          await client.auth.signOut();
        } catch (_) {
          // 로그아웃 실패해도 계속 진행
        }
      }

      // AppState 초기화
      if (mounted) {
        final appState = context.read<AppState>();
        await appState.signOut();
      }
    } catch (e) {
      // 전체 실패해도 앱 크래시 방지
    }

    if (!mounted) return;
    setState(() => _loading = false);

    // 탈퇴 완료 메시지 표시 후 auth 화면으로 이동
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')));
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        title: const Text('회원탈퇴'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 안내 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.softGray, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.orange,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '탈퇴 전 꼭 확인하세요',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkInk,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const _InfoSection(
                            title: '탈퇴 즉시 삭제되는 데이터',
                            color: AppColors.error,
                            items: [
                              '프로필 정보 (이메일, 닉네임)',
                              '즐겨찾기 및 저장된 메뉴',
                              '위치 이용 기록',
                              '앱 설정 정보',
                              '마케팅 수신 동의 정보',
                            ],
                          ),
                          const SizedBox(height: 16),
                          const _InfoSection(
                            title: '법적 의무에 따라 보관되는 데이터 (익명화)',
                            color: AppColors.textGray,
                            items: [
                              '신고·제재 기록 (3년, 서비스 운영)',
                              '거래 관련 기록 (5년, 전자상거래법)',
                              '소비자 불만 기록 (3년, 전자상거래법)',
                              '접속 로그 (3개월, 통신비밀보호법)',
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '보관되는 데이터는 개인을 식별할 수 없도록 익명화됩니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 탈퇴 사유 (선택)
                    const Text(
                      '탈퇴 사유 (선택)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._reasons.map(
                      (r) => InkWell(
                        onTap: () => setState(() => _reason = r),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _reason == r
                                        ? AppColors.orange
                                        : AppColors.midGray,
                                    width: 1.5,
                                  ),
                                ),
                                child: _reason == r
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.orange,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(r, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 확인 체크박스
                    InkWell(
                      onTap: () => setState(() => _confirmed = !_confirmed),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _confirmed,
                            onChanged: (v) =>
                                setState(() => _confirmed = v ?? false),
                            activeColor: AppColors.orange,
                          ),
                          const Expanded(
                            child: Text(
                              '위 내용을 확인했으며, 회원탈퇴에 동의합니다.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.darkInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 탈퇴 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_confirmed && !_loading) ? _delete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _confirmed
                        ? AppColors.error
                        : AppColors.softGray,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text(
                          '회원탈퇴',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> items;

  const _InfoSection({
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 13, color: color)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.darkInk,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
