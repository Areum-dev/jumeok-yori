import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recommendation_result.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class DrawLoadingScreen extends StatefulWidget {
  const DrawLoadingScreen({super.key});

  @override
  State<DrawLoadingScreen> createState() => _DrawLoadingScreenState();
}

class _DrawLoadingScreenState extends State<DrawLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  Timer? _textTimer;
  Timer? _nameTimer;
  int _textIdx = 0;
  int _nameIdx = 0;
  bool _done = false;
  bool _started = false;

  final _subtitles = const [
    '주먹이 고르는 중...',
    '오늘의 한 끼를 뽑는 중',
    '조건에 맞는 메뉴를 섞는 중',
    '잠깐만요, 골라볼게요',
  ];
  final _names = const [
    '김치제육덮밥',
    '돈카츠',
    '비빔밥',
    '마라탕',
    '떡볶이',
    '초밥',
    '파스타',
    '국밥',
    '냉모밀',
    '햄버거',
  ];

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnim = Tween<double>(
      begin: 0,
      end: -20,
    ).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
    _bounceCtrl.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) return; // 중복 호출 방지
    _started = true;
    final appState = context.read<AppState>();

    _textTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() => _textIdx = (_textIdx + 1) % _subtitles.length);
      }
    });
    _nameTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (mounted) {
        setState(() => _nameIdx = (_nameIdx + 1) % _names.length);
      }
    });

    // 추천 계산을 연출과 병렬로 실행
    final RecommendationResult? result = await appState.recommend();

    // 최소 2.5초 연출 보장
    await Future.delayed(const Duration(milliseconds: 2500));

    _textTimer?.cancel();
    _nameTimer?.cancel();

    if (!mounted) return;

    if (result != null) {
      Navigator.pushReplacementNamed(context, '/result');
    } else {
      setState(() => _done = true);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _textTimer?.cancel();
    _nameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _emptyState();
    return Scaffold(
      backgroundColor: AppColors.darkInk,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _bounceAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _bounceAnim.value),
                child: const Text('✊', style: TextStyle(fontSize: 80)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _names[_nameIdx],
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _subtitles[_textIdx],
              style: TextStyle(
                color: AppColors.ivory.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Scaffold(
    backgroundColor: AppColors.ivory,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😔', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          const Text(
            '조건에 맞는 메뉴가 없어요.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            '거리, 가격, 카테고리 조건을 넓혀보세요.',
            style: TextStyle(color: AppColors.textGray),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/filter'),
            child: const Text('필터 다시 설정'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            child: const Text('홈으로'),
          ),
        ],
      ),
    ),
  );
}
