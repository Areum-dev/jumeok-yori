import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'jumeok_map_screen.dart';
import 'my_store_tab_screen.dart';
import 'my_page_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final showStoreTab = appState.hasStoreAccess;

    final screens = <Widget>[
      const HomeScreen(),
      const JumeokMapScreen(),
      if (showStoreTab) const MyStoreTabScreen(),
      const MyPageScreen(),
    ];

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.map_rounded),
        label: '주먹지도',
      ),
      if (showStoreTab)
        const BottomNavigationBarItem(
          icon: Icon(Icons.storefront_rounded),
          label: '내 가게',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: '마이페이지',
      ),
    ];

    final safeIdx = _idx.clamp(0, screens.length - 1);
    final myPageIndex = screens.length - 1; // 마이페이지는 항상 마지막 탭

    return Scaffold(
      body: IndexedStack(index: safeIdx, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIdx,
        onTap: (i) {
          setState(() => _idx = i);
          // IndexedStack 은 탭을 바꿔도 위젯을 다시 만들지 않아 initState 가
          // 재실행되지 않으므로, 마이페이지 탭으로 들어올 때마다 여기서
          // 명시적으로 최신 데이터를 다시 불러온다.
          if (i == myPageIndex && appState.isLoggedIn) {
            appState.loadSaved();
            appState.loadHistory();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.midGray,
        backgroundColor: AppColors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: items,
      ),
    );
  }
}
