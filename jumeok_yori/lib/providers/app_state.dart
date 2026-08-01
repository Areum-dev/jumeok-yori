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
import '../repositories/saved_menu_repository.dart';
import '../repositories/recommendation_history_repository.dart';
import '../services/recommendation_service.dart';
import '../services/location_service.dart';
import '../services/local_user_service.dart';
import '../services/analytics_service.dart';

class AppState extends ChangeNotifier {
  final MenuRepository menuRepository;
  final RestaurantRepository restaurantRepository;
  final AuthRepository authRepository;
  final bool isSupabaseMode;
  final SavedMenuRepository _savedMenuRepository = SavedMenuRepository();
  final RecommendationHistoryRepository _historyRepository =
      RecommendationHistoryRepository();

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
    savedItems.clear();
    persistentHistory.clear();
    savedLoadError = null;
    historyLoadError = null;
    currentRecommendation = null;
    currentProfile = await authRepository.fetchProfile();
    notifyListeners();
    await loadMyStoreInfo();
    // 로그인 계정의 저장 메뉴/추천 기록을 서버에서 다시 불러온다
    // (registeredMenus/starterMenus 는 loadData() 에서 이미 채워져 있어야 함).
    await loadSaved();
    await loadHistory();
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    currentProfile = null;
    // 사장님 가게 관련 상태 초기화 (다음 로그인 사용자에게 이전 데이터 노출 방지)
    _hasStoreApplication = false;
    _myStoreApplicationStatus = null;
    _myRestaurantId = null;
    savedItems.clear();
    persistentHistory.clear();
    savedLoadError = null;
    historyLoadError = null;
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
      final userId = currentProfile?.id;
      final row = await client
          .from('recommendation_logs')
          .insert({
            'user_id': userId,
            'anonymous_user_id': anonymousUserId,
            'recommendation_type': result.isRegistered
                ? 'registered'
                : 'starter',
            'menu_item_id': result.menuItem?.id,
            'starter_menu_id': result.starterMenu?.id,
            'restaurant_id': result.restaurant?.id,
            'filters_json': filter.toJson(),
            'user_lat': userLat,
            'user_lng': userLng,
          })
          .select('id, created_at')
          .single();
      if (userId != null) {
        persistentHistory.insert(
          0,
          _withRecord(
            result,
            recordId: row['id'] as String,
            recordedAt: DateTime.parse(row['created_at'] as String),
          ),
        );
        notifyListeners();
      }
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
  // Supabase 모드 + 로그인 상태에서는 saved_menu_items 테이블이 실제 저장소다
  // (기기 로컬 저장이 아니라 계정에 연결됨 - 다른 기기/재설치에서도 유지되고,
  // 계정이 다르면 서로 다른 목록이 보인다). Mock 모드(로그인 개념이 약한 개발용
  // 데모)에서는 기존처럼 기기 로컬(SharedPreferences)을 사용한다.
  final List<RecommendationResult> savedItems = [];
  bool savedLoading = false;
  String? savedLoadError;
  bool _saveToggleInFlight = false;

  Future<void> loadSaved() async {
    final userId = currentProfile?.id;
    if (isSupabaseMode && userId != null) {
      savedLoading = true;
      savedLoadError = null;
      notifyListeners();
      try {
        final rows = await _savedMenuRepository.fetchSaved(userId);
        final loadedItems = <RecommendationResult>[];
        for (final row in rows) {
          final result = _matchSavedOrHistoryRow(
            type: row.recommendationType,
            menuItemId: row.menuItemId,
            starterMenuId: row.starterMenuId,
            recordedAt: row.createdAt,
            recordId: row.id,
          );
          if (result != null) loadedItems.add(result);
        }
        savedItems
          ..clear()
          ..addAll(loadedItems);
      } catch (e) {
        debugPrint('저장한 메뉴 불러오기 실패: $e');
        savedLoadError = '저장한 메뉴를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.';
      } finally {
        savedLoading = false;
      }
      notifyListeners();
      return;
    }
    // Mock 모드 / 비로그인: 기존 로컬 저장 방식 유지 (개발 편의용).
    if (!isSupabaseMode) {
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
    } else {
      savedItems.clear();
      savedLoadError = null;
    }
    notifyListeners();
  }

  bool isSaved(RecommendationResult r) =>
      savedItems.any((x) => x.type == r.type && x.id == r.id);

  /// 저장 토글. 비로그인 시 저장하지 않고 true 를 반환(호출부가 로그인 유도).
  Future<bool> toggleSave(RecommendationResult r) async {
    if (!isLoggedIn) return true;
    if (r.id == null) return false;
    if (_saveToggleInFlight) return false; // 중복 탭 방지
    _saveToggleInFlight = true;
    try {
      final userId = currentProfile?.id;
      if (isSupabaseMode && userId != null) {
        final existing = savedItems
            .where((x) => x.type == r.type && x.id == r.id)
            .firstOrNull;
        if (existing != null) {
          // 이미 저장돼 있으면 취소. recordId 가 없으면(방어적으로) DB 재조회.
          final rowId =
              existing.recordId ??
              await _savedMenuRepository.findExisting(
                userId: userId,
                isRegistered: r.isRegistered,
                id: r.id!,
              );
          if (rowId != null) await _savedMenuRepository.deleteSaved(rowId);
          savedItems.removeWhere((x) => x.type == r.type && x.id == r.id);
        } else {
          // 동시 탭 등으로 이미 DB 에 있을 수 있으니 한 번 더 확인 후 저장
          // (동일 메뉴 중복 저장 방지).
          final dupRowId = await _savedMenuRepository.findExisting(
            userId: userId,
            isRegistered: r.isRegistered,
            id: r.id!,
          );
          final rowId =
              dupRowId ??
              (await _savedMenuRepository.insertSaved(
                userId: userId,
                isRegistered: r.isRegistered,
                id: r.id!,
              )).id;
          savedItems.insert(
            0,
            _withRecord(r, recordId: rowId, recordedAt: DateTime.now()),
          );
        }
      } else {
        // Mock 모드 fallback
        await LocalUserService.toggleSaved(
          isRegistered: r.isRegistered,
          id: r.id!,
        );
        if (isSaved(r)) {
          savedItems.removeWhere((x) => x.type == r.type && x.id == r.id);
        } else {
          savedItems.insert(0, r);
        }
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('저장 처리 실패: $e');
      rethrow;
    } finally {
      _saveToggleInFlight = false;
    }
  }

  Future<void> deleteSavedItem(RecommendationResult r) async {
    if (r.recordId == null) return;
    try {
      await _savedMenuRepository.deleteSaved(r.recordId!);
      savedItems.removeWhere((x) => x.recordId == r.recordId);
      notifyListeners();
    } catch (e) {
      debugPrint('저장 삭제 실패: $e');
      rethrow;
    }
  }

  // ── 추천 기록 (마이페이지, 영구 저장) ─────────────────────────
  // `history` 는 홈 화면의 "최근 추천"용 세션 메모리 목록(즉시 반응, 로그인
  // 여부 무관)이고, `persistentHistory` 는 마이페이지에서 보여주는 계정별
  // 영구 기록이다(recommendation_logs 를 실제로 읽어온다).
  final List<RecommendationResult> persistentHistory = [];
  bool historyLoading = false;
  String? historyLoadError;

  Future<void> loadHistory() async {
    final userId = currentProfile?.id;
    if (!isSupabaseMode || userId == null) {
      persistentHistory.clear();
      historyLoadError = null;
      notifyListeners();
      return;
    }
    historyLoading = true;
    historyLoadError = null;
    notifyListeners();
    try {
      final rows = await _historyRepository.fetchHistory(userId);
      final loadedHistory = <RecommendationResult>[];
      for (final row in rows) {
        final result = _matchSavedOrHistoryRow(
          type: row.recommendationType,
          menuItemId: row.menuItemId,
          starterMenuId: row.starterMenuId,
          recordedAt: row.createdAt,
          recordId: row.id,
        );
        if (result != null) loadedHistory.add(result);
      }
      persistentHistory
        ..clear()
        ..addAll(loadedHistory);
    } catch (e) {
      debugPrint('추천 기록 불러오기 실패: $e');
      historyLoadError = '추천 기록을 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.';
    } finally {
      historyLoading = false;
    }
    notifyListeners();
  }

  Future<void> deleteHistoryEntry(RecommendationResult r) async {
    if (r.recordId == null) return;
    try {
      await _historyRepository.deleteEntry(r.recordId!);
      persistentHistory.removeWhere((x) => x.recordId == r.recordId);
      notifyListeners();
    } catch (e) {
      debugPrint('추천 기록 삭제 실패: $e');
      rethrow;
    }
  }

  Future<void> clearAllHistory() async {
    final userId = currentProfile?.id;
    if (userId == null) return;
    try {
      await _historyRepository.deleteAll(userId);
      persistentHistory.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('추천 기록 전체 삭제 실패: $e');
      rethrow;
    }
  }

  /// saved_menu_items / recommendation_logs 행(참조 id 만 있음)을 이미 불러온
  /// registeredMenus/starterMenus 와 매칭해 화면에 표시 가능한
  /// RecommendationResult 로 변환한다. 참조된 메뉴가 삭제되었거나 더 이상
  /// 승인 상태가 아니면(목록에 없으면) null 을 반환해 조용히 건너뛴다.
  RecommendationResult? _matchSavedOrHistoryRow({
    required String type,
    String? menuItemId,
    String? starterMenuId,
    required DateTime recordedAt,
    required String recordId,
  }) {
    if (type == 'registered' && menuItemId != null) {
      final m = registeredMenus.where((x) => x.id == menuItemId).firstOrNull;
      if (m == null) return null;
      return RecommendationResult.registered(
        m,
        distanceM: (m.restaurant?.distanceKm ?? 0) * 1000,
        recordedAt: recordedAt,
        recordId: recordId,
      );
    }
    if (type == 'starter' && starterMenuId != null) {
      final m = starterMenus.where((x) => x.id == starterMenuId).firstOrNull;
      if (m == null) return null;
      return RecommendationResult.starter(
        m,
        recordedAt: recordedAt,
        recordId: recordId,
      );
    }
    return null;
  }

  RecommendationResult _withRecord(
    RecommendationResult r, {
    required String recordId,
    required DateTime recordedAt,
  }) {
    if (r.isRegistered && r.menuItem != null) {
      return RecommendationResult.registered(
        r.menuItem!,
        distanceM: r.distanceM,
        recordId: recordId,
        recordedAt: recordedAt,
      );
    }
    return RecommendationResult.starter(
      r.starterMenu!,
      recordId: recordId,
      recordedAt: recordedAt,
    );
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
