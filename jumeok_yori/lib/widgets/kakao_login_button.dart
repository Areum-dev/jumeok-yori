import 'package:flutter/material.dart';

/// 카카오 로그인 버튼. 카카오 로그인 디자인 가이드에 가깝게
/// 노란색 배경(#FEE500) + 검은색 텍스트 + 말풍선 아이콘으로 구성했습니다.
/// (실제 카카오 로고 이미지는 사용하지 않고, Material 아이콘으로 단순화한
/// 말풍선 모양만 사용해 상표/저작권 문제를 피했습니다.)
///
/// 다른 로그인 버튼(PrimaryButton, OutlinedButton)과 동일하게
/// 전체 너비 + 높이 54 로 맞춰 화면에서 크기·정렬이 일관되도록 했습니다.
class KakaoLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const KakaoLoginButton({super.key, this.onPressed, this.isLoading = false});

  static const _kakaoYellow = Color(0xFFFEE500);
  static const _kakaoText = Color(0xFF191919);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kakaoYellow,
          foregroundColor: _kakaoText,
          disabledBackgroundColor: _kakaoYellow.withValues(alpha: 0.6),
          disabledForegroundColor: _kakaoText.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(_kakaoText),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_rounded, size: 20, color: _kakaoText),
                  SizedBox(width: 8),
                  Text(
                    '카카오로 시작하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kakaoText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
