import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'legal_document_screen.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  // 필수 항목
  bool _terms = false;
  bool _privacy = false;
  bool _privacyConsent = false;
  bool _locationPolicy = false;
  bool _locationConsent = false;
  bool _ageConfirm = false;

  // 선택 항목
  bool _marketing = false;
  bool _marketingEmail = false;
  bool _marketingPush = false;

  bool get _allRequired =>
      _terms &&
      _privacy &&
      _privacyConsent &&
      _locationPolicy &&
      _locationConsent &&
      _ageConfirm;

  bool get _allItems =>
      _allRequired && _marketing && _marketingEmail && _marketingPush;

  void _toggleAll(bool value) {
    setState(() {
      _terms = value;
      _privacy = value;
      _privacyConsent = value;
      _locationPolicy = value;
      _locationConsent = value;
      _ageConfirm = value;
      _marketing = value;
      _marketingEmail = value;
      _marketingPush = value;
    });
  }

  void _onMarketingChanged(bool value) {
    setState(() {
      _marketing = value;
      if (!value) {
        _marketingEmail = false;
        _marketingPush = false;
      }
    });
  }

  void _onMarketingSubChanged() {
    setState(() {
      _marketing = _marketingEmail || _marketingPush;
    });
  }

  void _confirm() {
    if (!_allRequired) return;
    Navigator.pop(context, <String, bool>{
      'terms': _terms,
      'privacy': _privacy,
      'privacyConsent': _privacyConsent,
      'locationPolicy': _locationPolicy,
      'locationConsent': _locationConsent,
      'ageConfirm': _ageConfirm,
      'marketing': _marketing,
      'marketingEmail': _marketingEmail,
      'marketingPush': _marketingPush,
    });
  }

  void _openDoc(String title, String assetPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(title: title, assetPath: assetPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        title: const Text('약관 동의'),
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
                    // 전체 동의
                    _AllAgreeRow(
                      checked: _allItems,
                      onChanged: _toggleAll,
                    ),
                    const Divider(
                        color: AppColors.softGray,
                        thickness: 1,
                        height: 24),

                    // 필수 항목 섹션
                    const _SectionLabel(text: '필수 동의'),
                    const SizedBox(height: 8),

                    _AgreementRow(
                      label: '[필수] 서비스 이용약관 동의',
                      checked: _terms,
                      onChanged: (v) => setState(() => _terms = v),
                      onViewTap: () => _openDoc(
                        '서비스 이용약관',
                        'lib/legal/terms.md',
                      ),
                    ),
                    _AgreementRow(
                      label: '[필수] 개인정보처리방침 동의',
                      checked: _privacy,
                      onChanged: (v) => setState(() => _privacy = v),
                      onViewTap: () => _openDoc(
                        '개인정보처리방침',
                        'lib/legal/privacy.md',
                      ),
                    ),
                    _AgreementRow(
                      label: '[필수] 개인정보 수집 및 이용 동의',
                      checked: _privacyConsent,
                      onChanged: (v) => setState(() => _privacyConsent = v),
                      onViewTap: () => _openDoc(
                        '개인정보 수집 및 이용 동의',
                        'lib/legal/privacy-consent.md',
                      ),
                    ),
                    _AgreementRow(
                      label: '[필수] 위치정보 이용약관 동의',
                      checked: _locationPolicy,
                      onChanged: (v) => setState(() => _locationPolicy = v),
                      onViewTap: () => _openDoc(
                        '위치정보 이용약관',
                        'lib/legal/location-policy.md',
                      ),
                    ),
                    _AgreementRow(
                      label: '[필수] 위치정보 수집 및 이용 동의',
                      checked: _locationConsent,
                      onChanged: (v) => setState(() => _locationConsent = v),
                      onViewTap: () => _openDoc(
                        '위치정보 수집 및 이용 동의',
                        'lib/legal/location-consent.md',
                      ),
                    ),
                    _AgreementRow(
                      label: '[필수] 만 14세 이상입니다.',
                      checked: _ageConfirm,
                      onChanged: (v) => setState(() => _ageConfirm = v),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.softGray, thickness: 1),
                    const SizedBox(height: 8),

                    // 선택 항목 섹션
                    const _SectionLabel(text: '선택 동의'),
                    const SizedBox(height: 8),

                    _AgreementRow(
                      label: '[선택] 마케팅 정보 수신 동의',
                      checked: _marketing,
                      onChanged: _onMarketingChanged,
                      onViewTap: () => _openDoc(
                        '마케팅 정보 수신 동의',
                        'lib/legal/marketing.md',
                      ),
                    ),

                    // 마케팅 하위 항목
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Column(
                        children: [
                          _SubAgreementRow(
                            label: '이메일 수신 동의',
                            checked: _marketingEmail,
                            onChanged: (v) {
                              setState(() => _marketingEmail = v);
                              _onMarketingSubChanged();
                            },
                          ),
                          _SubAgreementRow(
                            label: '앱 푸시 알림 수신 동의',
                            checked: _marketingPush,
                            onChanged: (v) {
                              setState(() => _marketingPush = v);
                              _onMarketingSubChanged();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      '선택 항목에 동의하지 않아도 서비스 이용이 가능합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _allRequired ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _allRequired ? AppColors.orange : AppColors.softGray,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '동의하고 계속하기',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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

class _AllAgreeRow extends StatelessWidget {
  final bool checked;
  final void Function(bool) onChanged;

  const _AllAgreeRow({required this.checked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _Checkbox(checked: checked, onChanged: onChanged),
            const SizedBox(width: 12),
            const Text(
              '전체 동의',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  final String label;
  final bool checked;
  final void Function(bool) onChanged;
  final VoidCallback? onViewTap;

  const _AgreementRow({
    required this.label,
    required this.checked,
    required this.onChanged,
    this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _Checkbox(checked: checked, onChanged: onChanged),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(!checked),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkInk,
                ),
              ),
            ),
          ),
          if (onViewTap != null)
            TextButton(
              onPressed: onViewTap,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textGray,
                minimumSize: const Size(0, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text('보기', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _SubAgreementRow extends StatelessWidget {
  final String label;
  final bool checked;
  final void Function(bool) onChanged;

  const _SubAgreementRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          _Checkbox(checked: checked, onChanged: onChanged, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(!checked),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textGray,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  final void Function(bool) onChanged;
  final double size;

  const _Checkbox({
    required this.checked,
    required this.onChanged,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked ? AppColors.orange : AppColors.white,
          border: Border.all(
            color: checked ? AppColors.orange : AppColors.midGray,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(size / 4),
        ),
        child: checked
            ? Icon(Icons.check,
                size: size * 0.7, color: AppColors.white)
            : null,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textGray,
      ),
    );
  }
}
