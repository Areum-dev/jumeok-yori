import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/env.dart';
import '../models/restaurant.dart';
import '../providers/app_state.dart';
import '../repositories/map_repository.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/store_marker_preview_card.dart';
import 'restaurant_detail_screen.dart';

/// 주먹지도: 네이버 지도(공식 flutter_naver_map SDK) 기반 전체화면 지도.
/// - 지도가 화면 전체를 차지
/// - 상단 슬림 플로팅 헤더
/// - 하단은 (핀 선택 시) 가게 카드 / (미선택 시) 내 주변 요약 / 빈 상태 중 하나만
class JumeokMapScreen extends StatefulWidget {
  const JumeokMapScreen({super.key});
  @override
  State<JumeokMapScreen> createState() => _JumeokMapScreenState();
}

class _JumeokMapScreenState extends State<JumeokMapScreen> {
  static const double _nearbyRadiusKm = 3.0;
  static const String _userLocationOverlayId = '__user_location__';

  // SDK init 결과를 앱 수명 동안 캐시 (화면 재방문 때 재시도 방지)
  static bool _sdkInitialized = false;
  static String? _sdkInitError;

  final _repo = MapRepository();

  NaverMapController? _mapController;
  RealtimeChannel? _realtimeChannel;

  List<Restaurant> _restaurants = [];
  List<Restaurant> _nearbyRestaurants = [];
  bool _loading = true;
  double _userLat = AppConfig.defaultLat;
  double _userLng = AppConfig.defaultLng;
  bool _isDefaultLocation = true;
  Restaurant? _selectedRestaurant;

  // 카메라 초기 위치는 딱 한 번만 설정한다.
  bool _cameraInitialized = false;

  // 네이버 지도 SDK 초기화 상태 (정적 캐시 반영)
  bool _naverMapReady = _sdkInitialized;
  String? _naverMapError = _sdkInitError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureNaverMapInit();
      _initLocation();
      _loadRestaurants();
      _subscribeRealtime();
    });
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // ─── SDK 초기화 ────────────────────────────────────────────

  Future<void> _ensureNaverMapInit() async {
    if (kIsWeb) return; // 웹 미지원
    if (_sdkInitialized) {
      if (mounted) setState(() { _naverMapReady = true; _naverMapError = null; });
      return;
    }
    debugPrint('[MAP] SDK init start — clientId="${Env.naverMapClientId}"');
    try {
      await FlutterNaverMap().init(
        clientId: Env.naverMapClientId,
        onAuthFailed: (e) {
          // 이전에는 여기서 debugPrint만 하고 화면에는 아무 표시가 없어서,
          // 인증 실패 시 사용자에게는 빈 회색 지도만 보이고 원인을 알 수 없었음.
          // Naver Cloud Platform 콘솔에서 이 Client ID에 "Mobile Dynamic Map" 서비스가
          // 활성화되어 있고, 앱 패키지명(Android: com.jumeokyori.app,
          // iOS: com.jumeok.jumeokYori)이 허용 목록에 등록되어 있는지 확인이 필요합니다.
          debugPrint('[MAP] ❌ 인증 실패: $e');
          // 인증 실패는 init() Future 완료 이후 비동기로 통지될 수 있어,
          // 이미 true로 캐시된 초기화 상태를 되돌려 다음 진입 시에도
          // 성공한 것으로 잘못 간주하지 않도록 함.
          _sdkInitialized = false;
          _sdkInitError = '지도 인증에 실패했습니다: $e';
          if (mounted) {
            setState(() {
              _naverMapReady = false;
              _naverMapError = _sdkInitError;
            });
          }
        },
      );
      _sdkInitialized = true;
      _sdkInitError = null;
      debugPrint('[MAP] SDK init OK');
      if (mounted) setState(() { _naverMapReady = true; _naverMapError = null; });
    } catch (e, st) {
      _sdkInitError = e.toString();
      debugPrint('[MAP] SDK init FAILED: $e\n$st');
      if (mounted) setState(() => _naverMapError = e.toString());
    }
  }

  // ─── Realtime 구독 ─────────────────────────────────────────

  void _subscribeRealtime() {
    if (kIsWeb) return;
    try {
      _realtimeChannel = Supabase.instance.client
          .channel('restaurants_map')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'restaurants',
            callback: (payload) {
              debugPrint('[MAP] Realtime event: ${payload.eventType} → 마커 갱신');
              _loadRestaurants(isAutoRefresh: true);
            },
          )
          .subscribe();
      debugPrint('[MAP] Realtime 구독 시작');
    } catch (e) {
      debugPrint('[MAP] Realtime 구독 실패 (무시됨): $e');
    }
  }

  // ─── 위치 ──────────────────────────────────────────────────

  bool _hasCoords(Restaurant r) => r.lat != 0 && r.lng != 0;

  double _distanceKm(Restaurant r) {
    if (!_hasCoords(r)) return double.infinity;
    return _haversine(_userLat, _userLng, r.lat, r.lng);
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const rad = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLng / 2), 2);
    return rad * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Future<void> _initLocation() async {
    debugPrint('[MAP] 위치 초기화 시작');
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[MAP] 위치 서비스 비활성화 → 기본 위치 사용');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[MAP] 위치 권한 거부 (permission=$permission) → 기본 위치 사용');
        return;
      }

      debugPrint('[MAP] 위치 권한 OK (permission=$permission), GPS 조회 중...');
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _isDefaultLocation = false;
      });
      debugPrint('[MAP] GPS 확보: lat=${pos.latitude} lng=${pos.longitude} '
          'accuracy=${pos.accuracy}m');
      await _moveCameraOnce(NLatLng(_userLat, _userLng), 15, 'gps_location');
      await _updateUserLocationOverlay();
      _recomputeNearby();
    } catch (e) {
      debugPrint('[MAP] 위치 조회 실패: $e → 기본 위치(강남역) 사용 '
          'lat=$_userLat lng=$_userLng');
    }
  }

  // ─── 카메라 ────────────────────────────────────────────────

  Future<void> _moveCameraOnce(
      NLatLng center, double zoom, String reason) async {
    if (_cameraInitialized) {
      debugPrint('[MAP] 카메라 이동 스킵 (이미 설정됨, 요청=$reason)');
      return;
    }
    _cameraInitialized = true;
    debugPrint('[MAP] 카메라 이동: reason=$reason '
        'target=${center.latitude},${center.longitude} zoom=$zoom');
    await _mapController?.updateCamera(
      NCameraUpdate.withParams(target: center, zoom: zoom),
    );
  }

  Future<void> _moveCameraTo(NLatLng center, double zoom, String reason) async {
    debugPrint('[MAP] 카메라 강제 이동: reason=$reason '
        'target=${center.latitude},${center.longitude} zoom=$zoom');
    await _mapController?.updateCamera(
      NCameraUpdate.withParams(target: center, zoom: zoom),
    );
  }

  // ─── 지도 준비 ─────────────────────────────────────────────

  Future<void> _onMapReady() async {
    debugPrint('[MAP] onMapReady 호출');
    await _updateUserLocationOverlay();
    if (!_cameraInitialized) {
      await _moveCameraOnce(
          NLatLng(_userLat, _userLng), 14, 'initial_map_ready');
    }
    await _addStoreMarkers(_restaurants.where(_hasCoords).toList());
  }

  // ─── 가게 데이터 로드 ──────────────────────────────────────

  Future<void> _loadRestaurants({bool isAutoRefresh = false}) async {
    if (!isAutoRefresh) setState(() => _loading = true);
    debugPrint('[MAP] 가게 목록 로드 시작 (autoRefresh=$isAutoRefresh)');

    final prevIds = _restaurants.map((r) => r.id).toSet();
    final list = await _repo.getApprovedRestaurantsForMap();

    if (!mounted) return;
    setState(() {
      _restaurants = list;
      _loading = false;
    });

    _recomputeNearby();
    _logDebug();

    final withCoords = _restaurants.where(_hasCoords).toList();
    await _addStoreMarkers(withCoords);

    // 새로 추가된 가게가 있으면 카메라를 첫 번째 신규 마커로 이동
    final newRestaurants =
        list.where((r) => !prevIds.contains(r.id) && _hasCoords(r)).toList();
    if (isAutoRefresh && newRestaurants.isNotEmpty) {
      final r = newRestaurants.first;
      debugPrint('[MAP] 신규 가게 감지: ${r.name} → 카메라 이동');
      await _moveCameraTo(NLatLng(r.lat, r.lng), 15, 'new_restaurant_${r.id}');
    }

    // 초기 로드에서 GPS 없고 카메라 미설정인 경우: 첫 가게 위치로
    if (!isAutoRefresh && !_cameraInitialized) {
      final first = withCoords.cast<Restaurant?>().firstWhere(
            (_) => true,
            orElse: () => null,
          );
      if (first != null) {
        await _moveCameraOnce(
          NLatLng(first.lat, first.lng),
          14,
          'first_restaurant_with_coords',
        );
      }
    }
  }

  void _recomputeNearby() {
    final nearby = _restaurants
        .where((r) => _hasCoords(r) && _distanceKm(r) < _nearbyRadiusKm)
        .toList()
      ..sort((a, b) => _distanceKm(a).compareTo(_distanceKm(b)));
    if (mounted) setState(() => _nearbyRestaurants = nearby);
  }

  void _logDebug() {
    final appState = context.read<AppState>();
    final user = appState.currentProfile;
    final storesWithCoords = _restaurants.where(_hasCoords).toList();

    debugPrint('=== 주먹지도 디버그 ===');
    debugPrint('[MAP] currentUser: ${user?.email} (${user?.id})');
    debugPrint('[MAP] userLocation: lat=$_userLat lng=$_userLng '
        'isDefault=$_isDefaultLocation');
    debugPrint('[MAP] approvedRestaurants total=${_restaurants.length}');
    for (final r in _restaurants) {
      final d = _distanceKm(r);
      debugPrint('[MAP] restaurant "${r.name}" | '
          'db_lat=${r.lat} db_lng=${r.lng} | '
          'display=${r.displayStatus} verification=${r.verificationStatus} | '
          'hasCoords=${_hasCoords(r)} | dist=${d.toStringAsFixed(2)}km');
    }
    debugPrint('[MAP] markerCount=${storesWithCoords.length}');
    for (final r in storesWithCoords) {
      debugPrint('[MAP] MARKER "${r.name}" | '
          'markerLat=${r.lat} markerLng=${r.lng}');
    }
    debugPrint('[MAP] nearby(<${_nearbyRadiusKm}km)=${_nearbyRestaurants.length}');
    debugPrint('=== 주먹지도 디버그 끝 ===');
  }

  // ─── 오버레이 / 마커 ───────────────────────────────────────

  Future<void> _addStoreMarkers(List<Restaurant> stores) async {
    final controller = _mapController;
    if (controller == null) {
      debugPrint('[MAP] _addStoreMarkers: controller null, 스킵');
      return;
    }
    debugPrint('[MAP] 마커 렌더링 시작: ${stores.length}개');
    await controller.clearOverlays(type: NOverlayType.marker);

    for (final r in stores) {
      final isSelected = _selectedRestaurant?.id == r.id;
      final marker = NMarker(
        id: r.id,
        position: NLatLng(r.lat, r.lng),
        iconTintColor:
            isSelected ? AppColors.orange : AppColors.orange.withValues(alpha: 0.85),
        caption: NOverlayCaption(
          text: r.name,
          textSize: 12,
          color: AppColors.darkInk,
          haloColor: Colors.white,
        ),
      );
      marker.setOnTapListener((_) => _onMarkerTap(r));
      await controller.addOverlay(marker);
    }
    debugPrint('[MAP] 마커 렌더링 완료: ${stores.length}개');
  }

  Future<void> _updateUserLocationOverlay() async {
    final controller = _mapController;
    if (controller == null) return;
    final circle = NCircleOverlay(
      id: _userLocationOverlayId,
      center: NLatLng(_userLat, _userLng),
      radius: 30,
      color: AppColors.orange.withValues(alpha: 0.25),
      outlineColor: AppColors.orange,
      outlineWidth: 3,
    );
    await controller.addOverlay(circle);
    debugPrint('[MAP] 사용자 위치 오버레이 갱신: lat=$_userLat lng=$_userLng');
  }

  // ─── 마커 탭 ───────────────────────────────────────────────

  Future<void> _onMarkerTap(Restaurant r) async {
    setState(() => _selectedRestaurant = r);
    debugPrint('[MAP] 마커 탭: "${r.name}" lat=${r.lat} lng=${r.lng}');
    await _moveCameraTo(NLatLng(r.lat, r.lng), 16, 'marker_tap_${r.id}');
    await _addStoreMarkers(_restaurants.where(_hasCoords).toList());
    if (!mounted) return;
    final appState = context.read<AppState>();
    AnalyticsService.log(
      eventType: 'map_marker_tapped',
      userId: appState.currentProfile?.id,
      anonymousUserId: appState.anonymousUserId,
      ownerId: r.ownerId,
      restaurantId: r.id,
    );
  }

  void _openDetail(Restaurant r) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurantId: r.id),
      ),
    );
  }

  Future<void> _zoomBy(double delta) async {
    await _mapController?.updateCamera(
      NCameraUpdate.withParams(zoomBy: delta),
    );
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          if (_naverMapError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_outlined, size: 48, color: AppColors.orange),
                    const SizedBox(height: 12),
                    Text('지도 초기화 실패\n$_naverMapError',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.darkInk)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _ensureNaverMapInit,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
          else if (!_naverMapReady)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (kIsWeb) ...[
                    const Icon(Icons.smartphone, size: 48, color: AppColors.orange),
                    const SizedBox(height: 12),
                    const Text('주먹지도는 모바일 앱에서 이용 가능합니다',
                        style: TextStyle(fontSize: 15, color: AppColors.darkInk)),
                  ] else ...[
                    const CircularProgressIndicator(color: AppColors.orange),
                    const SizedBox(height: 12),
                    const Text('지도 초기화 중...',
                        style: TextStyle(fontSize: 14, color: AppColors.textGray)),
                  ],
                ],
              ),
            )
          else
            NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(_userLat, _userLng),
                  zoom: 14,
                ),
                locationButtonEnable: false,
                consumeSymbolTapEvents: false,
              ),
              onMapReady: (controller) {
                _mapController = controller;
                _onMapReady();
              },
              onMapTapped: (point, latLng) {
                if (_selectedRestaurant == null) return;
                setState(() => _selectedRestaurant = null);
                _addStoreMarkers(_restaurants.where(_hasCoords).toList());
              },
            ),

          _floatingHeader(),
          _floatingControls(),
          _bottomContent(),

          if (_loading) _loadingChip(),
        ],
      ),
    );
  }

  // ─── UI 위젯들 ─────────────────────────────────────────────

  Widget _floatingHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              const Flexible(
                child: Text('주먹지도 · 내 주변 등록 가게',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDefaultLocation
                      ? AppColors.softGray
                      : AppColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDefaultLocation
                          ? Icons.location_off
                          : Icons.my_location,
                      size: 12,
                      color: _isDefaultLocation
                          ? AppColors.textGray
                          : AppColors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isDefaultLocation ? '강남역' : '내 위치',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isDefaultLocation
                            ? AppColors.textGray
                            : AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _cameraInitialized = false; // 수동 새로고침 시 카메라 재설정 허용
                  _initLocation();
                  _loadRestaurants();
                },
                child: const Icon(Icons.refresh,
                    size: 20, color: AppColors.textGray),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _floatingControls() {
    final double bottomOffset = _selectedRestaurant != null
        ? 250
        : (_nearbyRestaurants.isEmpty ? 120 : 110);
    return Positioned(
      right: 16,
      bottom: bottomOffset,
      child: Column(
        children: [
          _controlButton(Icons.add, () => _zoomBy(1)),
          const SizedBox(height: 4),
          _controlButton(Icons.remove, () => _zoomBy(-1)),
          const SizedBox(height: 8),
          _controlButton(
            Icons.my_location,
            () => _moveCameraTo(
              NLatLng(_userLat, _userLng),
              15,
              'my_location_button',
            ),
            filled: true,
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap,
      {bool filled = false}) {
    return Container(
      decoration: BoxDecoration(
        color: filled ? AppColors.orange : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: (filled ? AppColors.orange : Colors.black)
                  .withValues(alpha: filled ? 0.4 : 0.15),
              blurRadius: filled ? 8 : 6),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: filled ? Colors.white : AppColors.darkInk),
        onPressed: onTap,
        iconSize: 20,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _bottomContent() {
    if (_selectedRestaurant case final sel?) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: StoreMarkerPreviewCard(
          restaurant: sel,
          distanceKm: _hasCoords(sel) ? _distanceKm(sel) : null,
          onViewDetail: () => _openDetail(sel),
          onDismiss: () {
            setState(() => _selectedRestaurant = null);
            _addStoreMarkers(_restaurants.where(_hasCoords).toList());
          },
        ),
      );
    }

    if (_loading) return const SizedBox.shrink();

    if (_nearbyRestaurants.isNotEmpty) {
      return _nearbyChips();
    }

    return _emptyState();
  }

  Widget _nearbyChips() {
    final chips = _nearbyRestaurants.take(3).toList();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), blurRadius: 12),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('내 주변 ${_nearbyRestaurants.length}곳',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Row(
                children: chips.map((r) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => _onMarkerTap(r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.ivory,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    AppColors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                  _distanceKm(r) < 1
                                      ? '${(_distanceKm(r) * 1000).round()}m'
                                      : '${_distanceKm(r).toStringAsFixed(1)}km',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.orange,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12), blurRadius: 12),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('아직 내 주변에 등록된 가게가 없어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/draw-loading'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                      ),
                      child:
                          const Text('오늘 메뉴 뽑기', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/owner-apply'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        side: const BorderSide(color: AppColors.orange),
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('내 가게 등록하기',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingChip() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.orange)),
              SizedBox(width: 10),
              Text('가게 불러오는 중...', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
