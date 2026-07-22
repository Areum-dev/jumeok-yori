import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../services/filter_storage_service.dart';
import '../models/profile.dart';
import '../models/menu_item.dart';
import '../models/starter_menu.dart';
import '../models/recommendation_filter.dart';
import '../models/recommendation_result.dart';
import '../models/owner_store_application.dart';
import '../repositories/menu_repository.dart';
import '../repositories/restaurant_repository.dart';
import '../repositories/auth_repository.dart';
import '../services/recommendation_service.dart';
import '../services/location_service.dart';
import '../services/local_user_service.dart';
import '../services/analytics_service.dart';

class AppState extends ChangeNotifier {
  final MenuRepository menuRepository;
  final RestaurantRepository restaurantRepository;
  final AuthRepository authRepository;
  final bool isSupabaseMode;

  AppState({
    required this.menuRepository,
    required this.restaurantRepository,
    required this.authRepository,
    this.isSupabaseMode = false,
  });

  // ── 인증 ──────────────────────────────────────────────────
  Profile? currentProfile;

  /// 비로그인 사용자 추적용 익명 ID (shared_preferences 저장)
  String? anonymousUserId;

  Future<void> initAnonymousId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('anonymous_user_id');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('anonymous_user_id', id);
    }
    anonymousUserId = id;
  }

  bool get isLoggedIn => currentProfile != null;
  bool get isAdmin => currentProfile?.role == 'admin';
  bool get isOwner =>
      currentProfile?.role == 'owner' || currentProfile?.role == 'admin';

  // ── 사장님 가게 접근 ──────────────────────────────────────
  bool _hasStoreApplication = false;
  String? _myStoreApplicationStatus; // 'pending', 'approved', 'rejected', null
  String? _myRestaurantId;

  /// 스토어 탭 접근 가능 여부 (신청 있음 or 사장/관리자)
  bool get hasStoreAccess {
    if (!isLoggedIn) return false;
    if (isAdmin || isOwner) return true;
    return _hasStoreApplication;
  }

  String? get myStoreApplicationStatus => _myStoreApplicationStatus;
  String? get myRestaurantId => _myRestaurantId;

  Future<void> checkStoreApplication() async {
    if (!isLoggedIn || !isSupabaseMode) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final res = await Supabase.instance.client
          .from('owner_store_applications')
          .select('id')
          .eq('user_id', userId)
          .limit(1);
      _hasStoreApplication = (res as List).isNotEmpty;
      notifyListeners();
    } catch (e) {
      debugPrint('checkStoreApplication failed: $e');
    }
  }

  Future<void> loadMyStoreInfo() async {
    // 사용자 전환/로그아웃 시 이전 값이 남지 않도록 항상 먼저 초기화
    _hasStoreApplication = false;
    _myStoreApplicationStatus = null;
    _myRestaurantId = null;

    if (!isLoggedIn || !isSupabaseMode) {
      notifyListeners();
      return;
    }
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        notifyListeners();
        return;
      }
      final res = await Supabase.instance.client
          .from('owner_store_applications')
          .select('status, restaurant_id')
          .eq('user_id', userId) // CRITICAL: 현재 사용자 신청만 조회
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (res != null) {
        _hasStoreApplication = true;
        _myStoreApplicationStatus = res['status'] as String?;
        _myRestaurantId = res['restaurant_id'] as String?;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('loadMyStoreInfo failed: $e');
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (!isSupabaseMode) return;
    // 로그인/계정 전환 시 이전 세션(게스트 또는 다른 계정)의 추천 기록이
    // 새 사용자에게 이어져 보이지 않도록 세션 추천 상태를 초기화
    history.clear();
    currentRecommendation = null;
    currentProfile = await authRepository.fetchProfile();
    notifyListeners();
    await loadMyStoreInfo();
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    currentProfile = null;
    // 사장님 가게 관련 상태 초기화 (다음 로그인 사용자에게 이전 데이터 노출 방지)
    _hasStoreApplication = false;
    _myStoreApplicationStatus = null;
    _myRestaurantId = null;
    savedItems.clear();
    // 추천 기록은 세션 메모리에만 존재하므로 로그아웃 시 반드시 비워
    // 다음 로그인 사용자에게 이전 사용자의 추천 기록이 노출되는 것을 방지
    history.clear();
    currentRecommendation = null;
    notifyListeners();
  }

  // ── 위치 ──────────────────────────────────────────────────
  double userLat = AppConfig.defaultLat;
  double userLng = AppConfig.defaultLng;
  bool isDefaultLocation = true;
  String locationLabel = AppConfig.defaultLocationLabel;

  Future<void> initLocation() async {
    final pos = await LocationService.getPositionOrDefault();
    userLat = pos.lat;
    userLng = pos.lng;
    isDefaultLocation = pos.isDefault;
    locationLabel = pos.isDefault
        ? '${AppConfig.defaultLocationLabel} (기본)'
        : '현재 위치';
    notifyListeners();
  }

  // ── 필터 ──────────────────────────────────────────────────
  RecommendationFilter filter = const RecommendationFilter(
    distanceKm: 2.0,
    maxPrice: 15000,
  );

  Future<void> updateFilter(RecommendationFilter newFilter) async {
    filter = newFilter;
    notifyListeners();
    await FilterStorageService.saveFilter(newFilter);
  }

  Future<void> loadFilterFromStorage() async {
    filter = await FilterStorageService.loadFilter();
    notifyListeners();
  }

  // ── 데이터 ────────────────────────────────────────────────
  List<MenuItem> registeredMenus = [];
  List<StarterMenu> starterMenus = [];
  bool isLoading = false;
  String? loadError;

  Future<void> loadData() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    await initAnonymousId();
    await loadFilterFromStorage();
    try {
      registeredMenus = await menuRepository.fetchApprovedMenus();
    } catch (_) {
      registeredMenus = [];
    }
    try {
      starterMenus = await menuRepository.fetchStarterMenus();
    } catch (_) {
      starterMenus = [];
    }
    if (registeredMenus.isEmpty && starterMenus.isEmpty) {
      loadError = '메뉴 데이터를 불러오지 못했습니다.';
    }
    isLoading = false;
    notifyListeners();
  }

  // ── 추천 ──────────────────────────────────────────────────
  RecommendationResult? currentRecommendation;
  final List<RecommendationResult> history = [];

  Future<RecommendationResult?> recommend() async {
    final recentReg = await LocalUserService.getRecentRegisteredIds();
    final recentStarter = await LocalUserService.getRecentStarterIds();

    final result = RecommendationService.recommend(
      registeredMenus: registeredMenus,
      starterMenus: starterMenus,
      filter: filter,
      userLat: userLat,
      userLng: userLng,
      recentRegisteredIds: recentReg,
      recentStarterIds: recentStarter,
    );

    if (result == null) {
      currentRecommendation = null;
      notifyListeners();
      return null;
    }

    currentRecommendation = result;
    if (result.isRegistered && result.id != null) {
      await LocalUserService.addRecentRegisteredId(result.id!);
    } else if (result.id != null) {
      await LocalUserService.addRecentStarterId(result.id!);
    }

    history.insert(0, result);
    if (history.length > 20) history.removeRange(20, history.length);

    notifyListeners();
    await saveRecommendationLog(result);
    return result;
  }

  /// 추천 결과를 recommendation_logs 테이블에 기록합니다 (실패해도 무시).
  Future<void> saveRecommendationLog(RecommendationResult result) async {
    try {
      if (!isSupabaseMode) return;
      final client = Supabase.instance.client;
      await client.from('recommendation_logs').insert({
        'user_id': currentProfile?.id,
        'anonymous_user_id': anonymousUserId,
        'recommendation_type': result.isRegistered ? 'registered' : 'starter',
        'menu_item_id': result.menuItem?.id,
        'starter_menu_id': result.starterMenu?.id,
        'restaurant_id': result.restaurant?.id,
        'filters_json': filter.toJson(),
        'user_lat': userLat,
        'user_lng': userLng,
      });
    } catch (e) {
      debugPrint('추천 기록 저장 실패: $e');
    }
    // analytics_events 기록 (실패해도 무시)
    await AnalyticsService.log(
      eventType: 'recommendation_drawn',
      userId: currentProfile?.id,
      anonymousUserId: anonymousUserId,
      restaurantId: result.restaurant?.id,
      menuItemId: result.menuItem?.id,
      starterMenuId: result.starterMenu?.id,
      ownerId: result.restaurant?.ownerId,
      recommendationType: result.type,
    );
  }

  // ── 저장 ──────────────────────────────────────────────────
  final List<RecommendationResult> savedItems = [];

  Future<void> loadSaved() async {
    savedItems.clear();
    final regIds = await LocalUserService.getSavedRegisteredIds();
    final starterIds = await LocalUserService.getSavedStarterIds();
    for (final id in regIds) {
      final m = registeredMenus.where((x) => x.id == id).firstOrNull;
      if (m != null) {
        savedItems.add(
          RecommendationResult.registered(
            m,
            distanceM: (m.restaurant?.distanceKm ?? 0) * 1000,
          ),
        );
      }
    }
    for (final id in starterIds) {
      final m = starterMenus.where((x) => x.id == id).firstOrNull;
      if (m != null) savedItems.add(RecommendationResult.starter(m));
    }
    notifyListeners();
  }

  bool isSaved(RecommendationResult r) =>
      savedItems.any((x) => x.type == r.type && x.id == r.id);

  /// 저장 토글. 비로그인 시 저장하지 않고 true 를 반환(호출부가 로그인 유도).
  Future<bool> toggleSave(RecommendationResult r) async {
    if (!isLoggedIn) return true;
    if (r.id == null) return false;
    await LocalUserService.toggleSaved(isRegistered: r.isRegistered, id: r.id!);
    if (isSaved(r)) {
      savedItems.removeWhere((x) => x.type == r.type && x.id == r.id);
    } else {
      savedItems.insert(0, r);
    }
    notifyListeners();
    return false;
  }

  // ── 사장님 신청 ───────────────────────────────────────────
  bool isSubmitting = false;

  Future<void> submitStoreApplication(OwnerStoreApplication app) async {
    isSubmitting = true;
    notifyListeners();
    try {
      await restaurantRepository.submitApplication(app);
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<OwnerStoreApplication?> fetchMyApplication() async {
    final uid = currentProfile?.id;
    if (uid == null) return null;
    return restaurantRepository.fetchMyApplication(uid);
  }
}
