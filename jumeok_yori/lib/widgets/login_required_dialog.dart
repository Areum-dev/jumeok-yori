import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 로그인이 필요한 기능에서 띄우는 재사용 다이얼로그
class LoginRequiredDialog {
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그인이 필요해요'),
        content: const Text('로그인하면 메뉴 저장, 추천 기록,\n내 가게 등록을 사용할 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/auth');
            },
            child: const Text('로그인하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
