import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final bool showText;

  const LogoWidget({super.key, this.size = 80, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _logoImage(),
        if (showText) ...[
          const SizedBox(height: 12),
          const Text(
            '주먹요리',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.darkInk,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '주는대로 먹는 요리',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textGray,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }

  Widget _logoImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: Image.asset(
        'assets/images/logo-square.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(size * 0.2),
          ),
          child: Center(
            child: Text('✊', style: TextStyle(fontSize: size * 0.55)),
          ),
        ),
      ),
    );
  }
}
