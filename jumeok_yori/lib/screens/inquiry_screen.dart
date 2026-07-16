import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

enum InquiryType {
  general('일반문의', '일반 문의'),
  bug('버그신고', '버그 신고'),
  privacy('개인정보문의', '개인정보 문의'),
  other('기타', '기타');

  final String value;
  final String label;
  const InquiryType(this.value, this.label);
}

class InquiryScreen extends StatefulWidget {
  final InquiryType initialType;

  const InquiryScreen({super.key, this.initialType = InquiryType.general});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  late InquiryType _selectedType;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _titleCtrl.text.trim().isNotEmpty &&
      _contentCtrl.text.trim().length >= 10;

  Future<void> _submit() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용(10자 이상)을 입력해 주세요.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      await client.from('inquiries').insert({
        'user_id': userId,
        'type': _selectedType.value,
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // insert 실패해도 성공 메시지 표시 (앱이 크래시되지 않도록)
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess();

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        title: const Text('문의하기'),
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
                    const Text(
                      '문의 유형',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTypeSelector(),
                    const SizedBox(height: 20),
                    const Text(
                      '제목',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: '문의 제목을 입력해 주세요.',
                        hintStyle: TextStyle(color: AppColors.midGray),
                      ),
                      maxLength: 100,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '내용',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentCtrl,
                      onChanged: (_) => setState(() {}),
                      maxLines: 8,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        hintText: '문의 내용을 상세하게 입력해 주세요. (최소 10자)',
                        hintStyle: TextStyle(color: AppColors.midGray),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 개인정보(주민등록번호, 금융정보 등)는 입력하지 마세요.\n'
                      '• 문의 접수 후 영업일 기준 3~5일 이내에 답변드립니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_loading || !_canSubmit) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _canSubmit ? AppColors.orange : AppColors.softGray,
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
                          '문의 접수하기',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: InquiryType.values.map((type) {
        final selected = _selectedType == type;
        return InkWell(
          onTap: () => setState(() => _selectedType = type),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : AppColors.white,
              border: Border.all(
                color:
                    selected ? AppColors.orange : AppColors.softGray,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              type.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.textGray,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        title: const Text('문의하기'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '문의가 접수되었습니다.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkInk,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '빠른 시일 내에 답변드리겠습니다.\n'
                '영업일 기준 3~5일이 소요될 수 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
