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

/// 사용자 위치 확인 진행 상태.
/// checking: 권한/위치 조회 중 (아직 강남역 등 어떤 위치도 "사용자 위치"로 보여주지 않음)
/// resolved: 실제 GPS 위치 확보 성공
/// denied / deniedForever / serviceDisabled / timeout: 실패 사유별 상태.
/// 이 4가지 실패 상태에서만 AppConfig.defaultLat/defaultLng ("기본 지도 위치")를
/// 사용하며, 이때는 반드시 화면에 기본 위치임을 명확히 표시한다.
enum _LocationPhase { checking, resolved, denied, deniedForever, serviceDisabled, timeout }

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

  // SDK init 결과를 앱 수명 동안 캐시 (화면 재방문 때 재시도 방지)
  static bool _sdkInitialized = false;
  static String? _sdkInitError;

  final _repo = MapRepository();

  NaverMapController? _mapController;
  RealtimeChannel? _realtimeChannel;

  List<Restaurant> _restaurants = [];
  List<Restaurant> _nearbyRestaurants = [];
  bool _loading = true;

  // 실제 위치가 확인되기 전까지는 강남역 등 어떤 값도 "사용자 위치"로 사용하지 않는다.
  // _locationPhase 가 resolved 이거나 실패 상태(_fallbackToDefault 호출됨)로
  // 확정된 이후에만 이 값들이 화면/카메라에 사용된다.
  double _userLat = AppConfig.defaultLat;
  double _userLng = AppConfig.defaultLng;
  bool _isDefaultLocation = false;
  _LocationPhase _locationPhase = _LocationPhase.checking;
  bool _locationRetrying = false;

  Restaurant? _selectedRestaurant;

  // 네이버 지도 SDK 초기화 상태 (정적 캐시 반영)
  bool _naverMapReady = _sdkInitialized;
  String? _naverMapError = _sdkInitError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureNaverMapInit();
      _resolveInitialLocation();
      _loadRestaurants();
      _subscribeRealtime();
    });
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    // 네이티브 위치/방향 추적(스트림)을 명시적으로 종료. 위젯이 이미 해제된
    // 이후 컨트롤러 호출이 실패하더라도 dispose 흐름을 막지 않도록 방어.
    try {
      _mapController?.setLocationTrackingMode(NLocationTrackingMode.none);
    } catch (_) {
      // no-op
    }
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

  bool _isValidCoordinate(double lat, double lng) {
    if (lat.isNaN || lng.isNaN) return false;
    if (lat == 0 && lng == 0) return false;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
    return true;
  }

  /// 위치 서비스/권한을 확인하고 성공 시 위치를, 실패 시 실패 사유를 반환한다.
  /// 이미 영구 거부된 상태에서는 권한 요청 창을 다시 띄우지 않는다.
  Future<({Position? position, _LocationPhase? failPhase})>
      _checkAndFetchPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[MAP] 위치 서비스 비활성화');
      return (position: null, failPhase: _LocationPhase.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      debugPrint('[MAP] 위치 권한 영구 거부 상태 → 권한 요청 창을 다시 띄우지 않음');
      return (position: null, failPhase: _LocationPhase.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      // 아직 최종 거부가 아닌 "미요청" 상태에서만 권한 창을 띄운다 (최초 1회 또는 사용자가
      // 명시적으로 재시도/내 위치 버튼을 눌렀을 때만 이 메서드가 호출됨).
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return (position: null, failPhase: _LocationPhase.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      debugPrint('[MAP] 위치 권한 거부');
      return (position: null, failPhase: _LocationPhase.denied);
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!_isValidCoordinate(pos.latitude, pos.longitude)) {
        debugPrint('[MAP] 유효하지 않은 좌표 수신: ${pos.latitude}, ${pos.longitude}');
        return (position: null, failPhase: _LocationPhase.timeout);
      }
      debugPrint('[MAP] GPS 확보: lat=${pos.latitude} lng=${pos.longitude} '
          'accuracy=${pos.accuracy}m heading=${pos.heading}');
      return (position: pos, failPhase: null);
    } catch (e) {
      debugPrint('[MAP] 위치 조회 실패: $e');
      return (position: null, failPhase: _LocationPhase.timeout);
    }
  }

  /// 앱 진입 시 최초 1회 위치를 확인한다. 실패 시에만 "기본 지도 위치"로 대체하며,
  /// 그 경우 UI에서 반드시 기본 위치임을 표시한다 (사용자 위치로 위장하지 않음).
  Future<void> _resolveInitialLocation() async {
    debugPrint('[MAP] 위치 초기화 시작');
    if (!mounted) return;
    setState(() => _locationPhase = _LocationPhase.checking);

    final result = await _checkAndFetchPosition();
    if (!mounted) return;

    if (result.position != null) {
      setState(() {
        _userLat = result.position!.latitude;
        _userLng = result.position!.longitude;
        _isDefaultLocation = false;
        _locationPhase = _LocationPhase.resolved;
      });
      _recomputeNearby();
      return;
    }

    debugPrint('[MAP] 위치 확인 실패(${result.failPhase}) → 기본 지도 위치(강남역) 표시');
    setState(() {
      _userLat = AppConfig.defaultLat;
      _userLng = AppConfig.defaultLng;
      _isDefaultLocation = true;
      _locationPhase = result.failPhase ?? _LocationPhase.timeout;
    });
    _recomputeNearby();
  }

  /// "다시 시도" 버튼: 권한이 아직 최종 거부(deniedForever)가 아니라면 다시 확인한다.
  Future<void> _retryLocation() async {
    if (_locationRetrying) return;
    setState(() => _locationRetrying = true);
    try {
      await _resolveInitialLocation();
      if (_locationPhase == _LocationPhase.resolved) {
        await _ensureLocationTrackingStarted();
        if (mounted) {
          await _moveCameraTo(NLatLng(_userLat, _userLng), 15, 'retry_success');
        }
      }
    } finally {
      if (mounted) setState(() => _locationRetrying = false);
    }
  }

  /// 내 위치 버튼: 최신 위치를 다시 확인하고 현재 위치로 부드럽게 이동한다.
  /// (최초 진입 자동 이동과는 별개로, 항상 사용자가 직접 눌렀을 때만 카메라를 이동시킨다.)
  Future<void> _onMyLocationButtonPressed() async {
    if (_locationPhase == _LocationPhase.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    if (_locationPhase == _LocationPhase.serviceDisabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    setState(() => _locationRetrying = true);
    try {
      final result = await _checkAndFetchPosition();
      if (!mounted) return;

      if (result.position == null) {
        setState(() {
          _isDefaultLocation = true;
          _locationPhase = result.failPhase ?? _LocationPhase.timeout;
        });
        return;
      }

      setState(() {
        _userLat = result.position!.latitude;
        _userLng = result.position!.longitude;
        _isDefaultLocation = false;
        _locationPhase = _LocationPhase.resolved;
      });
      await _ensureLocationTrackingStarted();
      await _moveCameraTo(
          NLatLng(_userLat, _userLng), 15, 'my_location_button');
      _recomputeNearby();
    } finally {
      if (mounted) setState(() => _locationRetrying = false);
    }
  }

  // ─── 카메라 ────────────────────────────────────────────────

  Future<void> _moveCameraTo(NLatLng center, double zoom, String reason) async {
    debugPrint('[MAP] 카메라 강제 이동: reason=$reason '
        'target=${center.latitude},${center.longitude} zoom=$zoom');
    await _mapController?.updateCamera(
      NCameraUpdate.withParams(target: center, zoom: zoom),
    );
  }

  // ─── 지도 준비 ─────────────────────────────────────────────

  /// 지도가 준비된 시점은 이미 _locationPhase 가 확정된 이후이므로(빌드 단계에서
  /// _LocationPhase.checking 동안은 NaverMap 자체를 만들지 않음), 초기 카메라는
  /// NaverMapViewOptions.initialCameraPosition 값이 그대로 사용된다.
  /// 여기서는 위치가 성공적으로 확보된 경우에만 네이티브 위치 오버레이(방향 포함)를 켠다.
  Future<void> _onMapReady() async {
    debugPrint('[MAP] onMapReady 호출 (locationPhase=$_locationPhase)');
    if (_locationPhase == _LocationPhase.resolved) {
      await _ensureLocationTrackingStarted();
    }
    await _addStoreMarkers(_restaurants.where(_hasCoords).toList());
  }

  /// 네이버 지도 SDK 내장 위치 오버레이를 사용해 사용자 위치(파란 점 + 정확도 링)와
  /// 바라보는 방향(부채꼴 오버레이)을 표시한다. NLocationTrackingMode.noFollow 는
  /// "위치를 실시간으로 보여주되 카메라는 따라 움직이지 않는" 모드로, 지도 자동
  /// 회전/자동 재중심 없이 오버레이만 갱신된다 (SDK 자체 문서화된 동작).
  /// 방향(bearing)은 GPS course 또는 기기 방향 센서 중 사용 가능한 값을 SDK가
  /// 내부적으로 선택해 제공하며, 신뢰할 수 없을 때는 SDK가 자체적으로 갱신을
  /// 보류하므로 이 앱에서 별도로 0도를 강제하거나 보정하지 않는다.
  ///
  /// 색상: 정확도 링/점 색상을 SDK 기본값(파란색)에서 바꾸지 않는다. 예전에는
  /// 브랜드 오렌지로 덮어써서 "파란 점 위에 주황 원"이 겹쳐 보이는 중복 표시
  /// 문제가 있었음 — 이제 SDK 기본 파란색 하나로만 표시되도록 커스텀 색상
  /// 지정을 제거했다 (요구사항: 파란색 표시만 유지, 주황색 완전 제거).
  Future<void> _ensureLocationTrackingStarted() async {
    final controller = _mapController;
    if (controller == null) return;
    if (controller.locationTrackingMode == NLocationTrackingMode.noFollow) {
      return; // 이미 켜져 있으면 중복 구독하지 않음
    }
    final overlay = controller.getLocationOverlay();
    overlay.setSubIcon(NLocationOverlay.faceModeSubIcon); // 방향 표시용 부채꼴 아이콘
    controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
    debugPrint('[MAP] 네이티브 위치 오버레이 추적 시작 (noFollow, 기본 파란색 유지)');
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
    // 참고: 이전에는 GPS를 못 가져온 경우 카메라를 "첫 번째 가게" 위치로 자동
    // 이동시켰으나, 이는 "최초 진입 또는 내 위치 버튼 클릭 시에만 카메라를 이동한다"
    // 는 정책과 충돌하고 목록 순서에 따라 임의의 지역으로 튀는 문제가 있어 제거함.
    // 위치 확보 실패 시에는 _resolveInitialLocation 이 설정한 "기본 지도 위치"
    // (명확히 라벨링됨)를 그대로 유지한다.
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

  // 가게 마커 아이콘은 위젯 1개를 이미지로 변환해 생성하므로(NOverlayImage.fromWidget),
  // 매 렌더링마다 다시 만들지 않도록 Future 자체를 캐싱해 재사용한다.
  // (일반/선택 상태 2종류만 있으면 되므로 최대 2번만 생성됨)
  Future<NOverlayImage>? _pinIconNormal;
  Future<NOverlayImage>? _pinIconSelected;

  static const double _pinSizeNormal = 30;
  static const double _pinSizeSelected = 40;

  /// 작고 깔끔한 원형 가게 핀. 파란색 사용자 위치 오버레이와 확실히 구분되도록
  /// 브랜드 오렌지 계열을 사용하되 채도를 과하게 올리지 않았고, 흰 테두리와
  /// 옅은 그림자로 지도 위에서도 잘 보이게 했다. anchor 를 중앙(0.5, 0.5)으로
  /// 지정해 원의 중심이 실제 좌표를 정확히 가리키도록 함(기본값은 하단 중앙이라
  /// 원형 아이콘에는 맞지 않음).
  Widget _pinIconWidget({required bool selected}) {
    final size = selected ? _pinSizeSelected : _pinSizeNormal;
    final iconSize = selected ? 20.0 : 15.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.orange : AppColors.orange.withValues(alpha: 0.92),
        border: Border.all(color: Colors.white, width: selected ? 3 : 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.restaurant_rounded, color: Colors.white, size: iconSize),
    );
  }

  Future<NOverlayImage> _getPinIcon({required bool selected}) {
    if (selected) {
      return _pinIconSelected ??= NOverlayImage.fromWidget(
        context: context,
        size: const Size(_pinSizeSelected, _pinSizeSelected),
        widget: _pinIconWidget(selected: true),
      );
    }
    return _pinIconNormal ??= NOverlayImage.fromWidget(
      context: context,
      size: const Size(_pinSizeNormal, _pinSizeNormal),
      widget: _pinIconWidget(selected: false),
    );
  }

  Future<void> _addStoreMarkers(List<Restaurant> stores) async {
    final controller = _mapController;
    if (controller == null) {
      debugPrint('[MAP] _addStoreMarkers: controller null, 스킵');
      return;
    }
    debugPrint('[MAP] 마커 렌더링 시작: ${stores.length}개');
    await controller.clearOverlays(type: NOverlayType.marker);

    final normalIcon = await _getPinIcon(selected: false);
    final selectedIcon = await _getPinIcon(selected: true);
    if (!mounted) return;

    for (final r in stores) {
      final isSelected = _selectedRestaurant?.id == r.id;
      final marker = NMarker(
        id: r.id,
        position: NLatLng(r.lat, r.lng),
        icon: isSelected ? selectedIcon : normalIcon,
        anchor: const NPoint(0.5, 0.5),
        size: Size(
          isSelected ? _pinSizeSelected : _pinSizeNormal,
          isSelected ? _pinSizeSelected : _pinSizeNormal,
        ),
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
          else if (_locationPhase == _LocationPhase.checking)
            // 위치가 확정되기 전까지는 강남역 등 어떤 좌표도 지도에 보여주지 않는다.
            // (여기서 지도를 아예 그리지 않으므로, initialCameraPosition 에 잘못된
            // 좌표가 잠깐이라도 노출되는 경우 자체가 발생하지 않음)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.orange),
                  SizedBox(height: 12),
                  Text('현재 위치를 확인하고 있습니다',
                      style: TextStyle(fontSize: 14, color: AppColors.textGray)),
                ],
              ),
            )
          else
            // 이 지점에 도달했다는 것은 _locationPhase 가 resolved 이거나(실제 GPS)
            // 실패 상태(_fallbackToDefault 로 "기본 지도 위치"가 명확히 설정됨)라는
            // 뜻이므로, _userLat/_userLng 는 항상 의미있는 값이다.
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

          if (_naverMapReady && _isDefaultLocation) _defaultLocationBanner(),

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
                      _isDefaultLocation
                          ? '기본 지도 위치'
                          : '내 위치',
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
                  _onMyLocationButtonPressed();
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

  /// 기본 지도 위치(강남역)를 표시 중일 때 그 사실과 사유, 대응 방법을 명확히
  /// 안내하는 배너. 위치 권한/서비스 상태에 따라 다른 안내와 버튼을 보여준다.
  Widget _defaultLocationBanner() {
    final (String message, String actionLabel, VoidCallback action) =
        switch (_locationPhase) {
      _LocationPhase.deniedForever => (
          '위치 권한이 거부되어 ${AppConfig.defaultLocationLabel} 기준으로 표시하고 있어요.',
          '위치 권한 설정 열기',
          () => Geolocator.openAppSettings(),
        ),
      _LocationPhase.serviceDisabled => (
          '기기 위치 서비스가 꺼져 있어 ${AppConfig.defaultLocationLabel} 기준으로 표시하고 있어요.',
          '위치 설정 열기',
          () => Geolocator.openLocationSettings(),
        ),
      _LocationPhase.denied => (
          '위치 권한이 없어 ${AppConfig.defaultLocationLabel} 기준으로 표시하고 있어요.',
          '다시 시도',
          _retryLocation,
        ),
      _ => (
          '현재 위치를 확인하지 못해 ${AppConfig.defaultLocationLabel} 기준으로 표시하고 있어요.',
          '다시 시도',
          _retryLocation,
        ),
    };

    return Positioned(
      top: 72,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.darkInk)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _locationRetrying ? null : action,
                child: _locationRetrying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.orange),
                      )
                    : Text(actionLabel,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange)),
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
            _locationRetrying ? null : _onMyLocationButtonPressed,
            filled: true,
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback? onTap,
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
