import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'repositories/mock_data_repository.dart';
import 'repositories/supabase_menu_repository.dart';
import 'repositories/restaurant_repository.dart';
import 'repositories/auth_repository.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_tab_screen.dart';
import 'screens/filter_screen.dart';
import 'screens/draw_loading_screen.dart';
import 'screens/recommendation_result_screen.dart';
import 'screens/my_page_screen.dart';
import 'screens/owner_store_application_screen.dart';
import 'screens/owner_dashboard_screen.dart';
import 'screens/menu_edit_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/admin_store_applications_screen.dart';
import 'screens/admin_menu_applications_screen.dart';
import 'screens/my_store_tab_screen.dart';
import 'screens/terms_agreement_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/inquiry_screen.dart';
import 'screens/account_deletion_screen.dart';
import 'screens/legal_document_screen.dart';

class JumeokYoriApp extends StatelessWidget {
  const JumeokYoriApp({super.key, this.supabaseReady = false});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) {
    final useReal = supabaseReady;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(
            menuRepository: useReal
                ? SupabaseMenuRepository()
                : MockDataRepository(),
            restaurantRepository: useReal
                ? SupabaseRestaurantRepository()
                : MockRestaurantRepository(),
            authRepository: AuthRepository(),
            isSupabaseMode: useReal,
          ),
        ),
      ],
      child: MaterialApp(
        title: '주먹요리',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/auth': (_) => const AuthScreen(),
          '/home': (_) => const MainTabScreen(),
          '/filter': (_) => const FilterScreen(),
          '/draw-loading': (_) => const DrawLoadingScreen(),
          '/result': (_) => const RecommendationResultScreen(),
          '/my-page': (_) => const MyPageScreen(),
          '/owner-apply': (_) => const OwnerStoreApplicationScreen(),
          '/owner-dashboard': (_) => const OwnerDashboardScreen(),
          '/my-store': (_) => const MyStoreTabScreen(),
          '/menu-edit': (_) => const MenuEditScreen(),
          '/admin': (_) => const AdminScreen(),
          '/admin/stores': (_) => const AdminStoreApplicationsScreen(),
          '/admin/menus': (_) => const AdminMenuApplicationsScreen(),
          '/terms-agreement': (_) => const TermsAgreementScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/inquiry': (_) => const InquiryScreen(),
          '/account-deletion': (_) => const AccountDeletionScreen(),
          '/legal/terms': (_) => const LegalDocumentScreen(
            title: '서비스 이용약관',
            assetPath: 'lib/legal/terms.md',
          ),
          '/legal/privacy': (_) => const LegalDocumentScreen(
            title: '개인정보처리방침',
            assetPath: 'lib/legal/privacy.md',
          ),
          '/legal/location': (_) => const LegalDocumentScreen(
            title: '위치정보 이용약관',
            assetPath: 'lib/legal/location-policy.md',
          ),
        },
      ),
    );
  }
}
