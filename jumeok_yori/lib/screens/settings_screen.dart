import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'legal_document_screen.dart';
import 'inquiry_screen.dart';
import 'account_deletion_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _marketingAgreed = false;
  bool _loadingMarketing = false;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadMarketingState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    // package_info_plus 없으므로 pubspec 기반 하드코딩
    setState(() => _appVersion = '1.0.0');
  }

  Future<void> _loadMarketingState() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      final res = await client
          .from('profiles')
          .select('marketing_agreed')
          .eq('id', userId)
          .maybeSingle();
      if (res != null && mounted) {
        setState(() {
          _marketingAgreed = (res['marketing_agreed'] as bool?) ?? false;
        });
      }
    } catch (_) {
      // 조회 실패 시 기본값 유지
    }
  }

  Future<void> _toggleMarketing(bool value) async {
    setState(() => _loadingMarketing = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await client.from('profiles').upsert({
          'id': userId,
          'marketing_agreed': value,
        });
      }
      if (mounted) setState(() => _marketingAgreed = value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정 저장에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
    }
    if (mounted) setState(() => _loadingMarketing = false);
  }

  void _openDoc(String title, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(title: title, assetPath: path),
      ),
    );
  }

  void _openInquiry(InquiryType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InquiryScreen(initialType: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isLoggedIn = appState.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(backgroundColor: AppColors.ivory, title: const Text('설정')),
      body: ListView(
        children: [
          // 약관/정책 섹션
          _SectionHeader(title: '약관 및 정책'),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: '서비스 이용약관',
            onTap: () => _openDoc('서비스 이용약관', 'lib/legal/terms.md'),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보처리방침',
            onTap: () => _openDoc('개인정보처리방침', 'lib/legal/privacy.md'),
          ),
          _SettingsTile(
            icon: Icons.location_on_outlined,
            title: '위치정보 이용약관',
            onTap: () => _openDoc('위치정보 이용약관', 'lib/legal/location-policy.md'),
          ),
          _SettingsTile(
            icon: Icons.code_outlined,
            title: '오픈소스 라이선스',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: '주먹요리',
                applicationVersion: _appVersion,
              );
            },
          ),

          const SizedBox(height: 8),

          // 계정 섹션
          _SectionHeader(title: '계정'),
          if (isLoggedIn) ...[
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: '마케팅 수신 동의',
              trailing: _loadingMarketing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: _marketingAgreed,
                      onChanged: _toggleMarketing,
                      activeThumbColor: AppColors.orange,
                      activeTrackColor: AppColors.orange.withValues(alpha: 0.4),
                    ),
            ),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: '개인정보 삭제 요청',
              onTap: () => _openInquiry(InquiryType.privacy),
            ),
            _SettingsTile(
              icon: Icons.person_off_outlined,
              title: '회원탈퇴',
              titleColor: AppColors.error,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountDeletionScreen(),
                  ),
                );
              },
            ),
          ] else
            _SettingsTile(
              icon: Icons.login_rounded,
              title: '로그인',
              onTap: () => Navigator.pushNamed(context, '/auth'),
            ),

          const SizedBox(height: 8),

          // 고객지원 섹션
          _SectionHeader(title: '고객지원'),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: '문의하기',
            onTap: () => _openInquiry(InquiryType.general),
          ),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            title: '버그 신고',
            onTap: () => _openInquiry(InquiryType.bug),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: '개인정보 문의',
            onTap: () => _openInquiry(InquiryType.privacy),
          ),

          const SizedBox(height: 8),

          // 앱 정보 섹션
          _SectionHeader(title: '앱 정보'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: '앱 버전',
            trailing: Text(
              _appVersion,
              style: const TextStyle(fontSize: 14, color: AppColors.textGray),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textGray,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.white,
      leading: Icon(icon, color: AppColors.textGray, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, color: titleColor ?? AppColors.darkInk),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.midGray,
                )
              : null),
      onTap: onTap,
    );
  }
}
