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
          icon: Icon(Icons.map_rounded), label: '주먹지도'),
      if (showStoreTab)
        const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_rounded), label: '내 가게'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded), label: '마이페이지'),
    ];

    final safeIdx = _idx.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIdx, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIdx,
        onTap: (i) => setState(() => _idx = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.midGray,
        backgroundColor: AppColors.white,
        elevation: 8,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: items,
      ),
    );
  }
}
