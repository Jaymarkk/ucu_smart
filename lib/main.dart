import 'dart:async';
import 'package:flutter/material.dart';
import 'navigation/campus_graph.dart';
import 'navigation/route_service.dart';
import 'navigation/dynamic_building_route_service.dart';
import 'navigation/map_coordinates.dart';
import 'services/building_api_service.dart';
import 'services/campus_geofence_service.dart';
import 'services/campus_map_development_policy.dart';
import 'services/student_auth_service.dart';
import 'widgets/campus_access_gate.dart';
import 'screens/splash_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/student_room_availability_screen.dart';
import 'screens/student_profile_screen.dart';
import 'screens/unified_login_screen.dart';
import 'widgets/student_portal_components.dart';

void main() {
  runApp(const UcuSmartPlusApp());
}

class _CampusRouteObserver extends NavigatorObserver {
  final ValueNotifier<String?> currentRouteName = ValueNotifier(null);
  final List<Route<dynamic>> _pageRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pageRoutes.remove(route);
    _publish();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pageRoutes.remove(route);
    _publish();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _pageRoutes.remove(oldRoute);
    if (newRoute != null && newRoute is! PopupRoute<dynamic>) {
      _pageRoutes.add(newRoute);
    }
    _publish();
  }

  void _record(Route<dynamic> route) {
    if (route is PopupRoute<dynamic>) return;
    _pageRoutes.remove(route);
    _pageRoutes.add(route);
    _publish();
  }

  void _publish() {
    currentRouteName.value =
        _pageRoutes.isEmpty ? null : _pageRoutes.last.settings.name ?? '';
  }

  void dispose() => currentRouteName.dispose();
}

class UcuSmartPlusApp extends StatefulWidget {
  const UcuSmartPlusApp({
    super.key,
    this.studentAuthService,
    this.buildingApi,
    this.geofenceService,
  });

  final StudentAuthService? studentAuthService;
  final BuildingApiService? buildingApi;
  final CampusGeofenceService? geofenceService;

  @override
  State<UcuSmartPlusApp> createState() => _UcuSmartPlusAppState();
}

class _UcuSmartPlusAppState extends State<UcuSmartPlusApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _routeObserver = _CampusRouteObserver();
  late StudentAuthService _studentAuthService;
  late CampusGeofenceService _geofenceService;
  late bool _wasStudentAuthenticated;
  bool _isVisitorMode = false;

  @override
  void initState() {
    super.initState();
    _studentAuthService =
        widget.studentAuthService ?? StudentAuthService.instance;
    _geofenceService = widget.geofenceService ?? CampusGeofenceService.instance;
    _wasStudentAuthenticated = _studentAuthService.isStudentAuthenticated;
    _studentAuthService.addListener(_onStudentAuthChanged);
  }

  @override
  void didUpdateWidget(covariant UcuSmartPlusApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextStudentAuthService =
        widget.studentAuthService ?? StudentAuthService.instance;
    final nextGeofenceService =
        widget.geofenceService ?? CampusGeofenceService.instance;
    final dependenciesChanged = nextStudentAuthService != _studentAuthService ||
        nextGeofenceService != _geofenceService;
    if (!dependenciesChanged) return;

    _studentAuthService.removeListener(_onStudentAuthChanged);
    _studentAuthService = nextStudentAuthService;
    _geofenceService = nextGeofenceService;
    _wasStudentAuthenticated = _studentAuthService.isStudentAuthenticated;
    _studentAuthService.addListener(_onStudentAuthChanged);
  }

  @override
  void dispose() {
    _studentAuthService.removeListener(_onStudentAuthChanged);
    _routeObserver.dispose();
    super.dispose();
  }

  void _onStudentAuthChanged() {
    final isAuthenticated = _studentAuthService.isStudentAuthenticated;
    if (_wasStudentAuthenticated == isAuthenticated) return;
    _wasStudentAuthenticated = isAuthenticated;
    if (isAuthenticated && mounted) {
      setState(() => _isVisitorMode = false);
    }
  }

  void _setVisitorMode(bool active) {
    if (_isVisitorMode != active && mounted) {
      setState(() => _isVisitorMode = active);
    }
  }

  Future<void> _openVisitorEntry() async {
    final isAuthenticated = _studentAuthService.isStudentAuthenticated;
    if (!isAuthenticated) {
      _setVisitorMode(true);
    }
    if (campusMapDevelopmentBypassEnabled) {
      _navigateToCampusMap();
      return;
    }
    if (!isAuthenticated) {
      _navigateToVisitorVerification();
      return;
    }
    await _geofenceService.refresh(forceFresh: true);
    if (!mounted) return;
    _navigateToCampusMap();
  }

  void _navigateToCampusMap() {
    if (_routeObserver.currentRouteName.value == '/campus-map') return;
    _navigatorKey.currentState?.pushNamedAndRemoveUntil<void>(
      '/campus-map',
      (_) => false,
    );
  }

  void _navigateToVisitorVerification() {
    if (_routeObserver.currentRouteName.value == '/campus-verification') return;
    _navigatorKey.currentState?.pushNamedAndRemoveUntil<void>(
      '/campus-verification',
      (_) => false,
    );
  }

  Widget _buildLogin(
      BuildContext context,
      StudentAuthService studentAuthService) {
    return UnifiedLoginScreen(
      studentAuthService: studentAuthService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentAuthService = _studentAuthService;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      navigatorObservers: [_routeObserver],
      debugShowCheckedModeBanner: false,
      title: 'UCU Smart Plus',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF12356B),
        ),
      ),
      builder: (context, child) => CampusAccessGate(
        geofenceService: _geofenceService,
        isVisitorMode: _isVisitorMode,
        currentRouteName: _routeObserver.currentRouteName,
        onVisitorAccessGranted: _navigateToCampusMap,
        onVisitorAccessRestricted: _navigateToVisitorVerification,
        studentAuthService: studentAuthService,
        child: child ?? const SizedBox.shrink(),
      ),
      routes: {
        '/student-login': (context) =>
            _buildLogin(context, studentAuthService),
        '/login': (context) =>
            _buildLogin(context, studentAuthService),
        '/campus-verification': (_) => const Scaffold(body: SizedBox.shrink()),
        '/student-dashboard': (_) => StudentDashboardScreen(
              authService: studentAuthService,
              api: studentAuthService.portalApi,
            ),
        '/student/profile': (_) => StudentProfileScreen(
              authService: studentAuthService,
            ),
        '/student/room-availability': (_) => StudentRoomAvailabilityScreen(
              authService: studentAuthService,
              api: studentAuthService.portalApi,
            ),
        '/campus-map': (context) => CampusMapPage(
              buildingApi: widget.buildingApi ?? BuildingApiService.instance,
              studentAuthService: studentAuthService,
              openedFromStudentPortal:
                  ModalRoute.of(context)?.settings.arguments ==
                      StudentPortalMapOrigin.studentPortal,
            ),
      },
      home: SplashScreen(
        loginBuilder: (_) => UnifiedLoginScreen(
          studentAuthService: studentAuthService,
        ),
        destinationBuilder: (_) => CampusMapPage(
          buildingApi: widget.buildingApi ?? BuildingApiService.instance,
        ),
        onVisitorTap: () => unawaited(_openVisitorEntry()),
      ),
    );
  }
}

class CampusLocation {
  const CampusLocation({
    required this.number,
    required this.name,
    required this.x,
    required this.y,
    this.details = 'Campus facility',
    this.databaseId,
    this.code,
    this.category,
    this.description,
    this.floorInfo,
    this.locationDetails,
    this.routeNodeId,
    this.routeConnectionVerified = false,
  });

  final int number;
  final String name;
  final double? x;
  final double? y;
  final String details;
  final int? databaseId;
  final String? code;
  final String? category;
  final String? description;
  final String? floorInfo;
  final String? locationDetails;
  final String? routeNodeId;
  final bool routeConnectionVerified;

  bool get isDatabaseBuilding => databaseId != null;
  bool get hasMapCoordinates =>
      x != null &&
      y != null &&
      x!.isFinite &&
      y!.isFinite &&
      x! >= 0 &&
      x! <= 100 &&
      y! >= 0 &&
      y! <= 100;
  bool get hasVerifiedRoute {
    final nodeId = routeNodeId;
    return hasMapCoordinates &&
        routeConnectionVerified &&
        nodeId != null &&
        nodeId.trim().isNotEmpty &&
        CampusGraph.nodeById(nodeId) != null;
  }

  factory CampusLocation.fromBuilding(BuildingRecord building) {
    final details = building.locationDetails?.trim().isNotEmpty == true
        ? building.locationDetails!.trim()
        : building.description?.trim().isNotEmpty == true
            ? building.description!.trim()
            : building.category;
    return CampusLocation(
      number: -building.id,
      name: building.name,
      x: building.mapXPct,
      y: building.mapYPct,
      details: details,
      databaseId: building.id,
      code: building.code,
      category: building.category,
      description: building.description,
      floorInfo: building.floorInfo,
      locationDetails: building.locationDetails,
      routeNodeId: building.routeNodeId,
      routeConnectionVerified: building.routeConnectionVerified,
    );
  }
}

const List<CampusLocation> campusLocations = [
  CampusLocation(
    number: 1,
    name: 'Dr. Leoncio Ancheta Bldg. 1',
    x: 53.0,
    y: 20.4,
    details: 'Academic building • classroom block',
  ),
  CampusLocation(
    number: 2,
    name: 'Dr. Leoncio Ancheta Bldg. 2',
    x: 67.0,
    y: 25.5,
    details: 'Academic building • faculty and classrooms',
  ),
  CampusLocation(
    number: 3,
    name: 'Dr. Solidad F. Caringal Bldg.',
    x: 61.5,
    y: 29.5,
    details: 'Academic building • central campus block',
  ),
  CampusLocation(
    number: 4,
    name: 'Nursing Bldg. 1',
    x: 54.0,
    y: 29.5,
    details: 'Nursing program • training facilities',
  ),
  CampusLocation(
    number: 5,
    name: 'Resorts World',
    x: 59.4,
    y: 35.0,
    details: 'Student and hospitality-related facility',
  ),
  CampusLocation(
    number: 6,
    name: 'Badar Building',
    x: 80.3,
    y: 40.0,
    details: 'Administrative and academic use',
  ),
  CampusLocation(
    number: 7,
    name: 'Honasan Hall',
    x: 75.0,
    y: 47.0,
    details: 'Academic and event hall',
  ),
  CampusLocation(
    number: 8,
    name: 'Nursing Bldg. 2',
    x: 62.0,
    y: 47.5,
    details: 'Nursing facilities and practical labs',
  ),
  CampusLocation(
    number: 9,
    name: 'Dr. Teofidez E. Calvero',
    x: 45.2,
    y: 43.0,
    details: 'Academic and administrative block',
  ),
  CampusLocation(
    number: 10,
    name: 'Dr. Pedro T. Orata Bldg. 1',
    x: 31.5,
    y: 34.0,
    details: 'Academic and support block',
  ),
  CampusLocation(
    number: 11,
    name: 'Julio E. Parayno Bldg.',
    x: 27.0,
    y: 34.5,
    details: 'Academic building and classrooms',
  ),
  CampusLocation(
    number: 12,
    name: 'Dr. Pedro T. Orata Bldg. 2',
    x: 24.8,
    y: 24.0,
    details: 'Academic and facility building',
  ),
  CampusLocation(
    number: 13,
    name: 'Gymnasium',
    x: 49.0,
    y: 75.0,
    details: 'Main sports facility',
  ),
  CampusLocation(
    number: 14,
    name: 'Mini Gymnasium',
    x: 45.0,
    y: 86.0,
    details: 'Training and small sports hall',
  ),
  CampusLocation(
    number: 15,
    name: 'P.E. Office',
    x: 38.8,
    y: 78.0,
    details: 'Physical education office',
  ),
  CampusLocation(
    number: 16,
    name: 'Fitness Gym. 2',
    x: 48.7,
    y: 83.0,
    details: 'Fitness and wellness area',
  ),
  CampusLocation(
    number: 17,
    name: 'Fitness Gym. 1',
    x: 39.0,
    y: 71.4,
    details: 'Fitness training facility',
  ),
  CampusLocation(
    number: 18,
    name: 'Wellness Spa',
    x: 39.0,
    y: 68.4,
    details: 'Wellness and spa services',
  ),
  CampusLocation(
    number: 19,
    name: 'E.M.A.S.',
    x: 36.3,
    y: 67.0,
    details: 'Administrative and support facility',
  ),
  CampusLocation(
    number: 20,
    name: 'Green Home',
    x: 36.8,
    y: 69.0,
    details: 'Green and eco-oriented venue',
  ),
  CampusLocation(
    number: 21,
    name: 'Generator Set',
    x: 32.0,
    y: 49.2,
    details: 'Power support infrastructure',
  ),
  CampusLocation(
    number: 22,
    name: 'Animal Clinic',
    x: 29.5,
    y: 45.5,
    details: 'Veterinary and animal welfare clinic',
  ),
  CampusLocation(
    number: 23,
    name: 'University Clinic',
    x: 44.0,
    y: 50.0,
    details: 'Student health and medical support',
  ),
  CampusLocation(
    number: 24,
    name: 'Mock Hotel',
    x: 40.5,
    y: 38.5,
    details: 'Hospitality training facility',
  ),
  CampusLocation(
    number: 25,
    name: 'Audio Visual Room',
    x: 78.0,
    y: 34.0,
    details: 'Presentation and multimedia room',
  ),
  CampusLocation(
    number: 26,
    name: 'Dr. Orata Park',
    x: 83.0,
    y: 33.5,
    details: 'Park and outdoor gathering area',
  ),
  CampusLocation(
    number: 27,
    name: 'Quadrangle',
    x: 70.0,
    y: 40.0,
    details: 'Open student quad and event space',
  ),
  CampusLocation(
    number: 28,
    name: 'Square Garden',
    x: 54.0,
    y: 42.5,
    details: 'Garden and landscaped area',
  ),
  CampusLocation(
    number: 29,
    name: 'NDRRMO',
    x: 48.0,
    y: 29.0,
    details: 'Disaster readiness office',
  ),
  CampusLocation(
    number: 30,
    name: 'Airplane Bldg.',
    x: 40.0,
    y: 18.0,
    details: 'Aviation-related training building',
  ),
  CampusLocation(
    number: 31,
    name: 'Turnstile',
    x: 32.5,
    y: 13.0,
    details: 'Campus access point',
  ),
  CampusLocation(
    number: 32,
    name: 'Entrep. & Law Bldg.',
    x: 32.0,
    y: 7.5,
    details: 'Law and entrepreneurship building',
  ),
  CampusLocation(
    number: 33,
    name: 'Sewer Treatment Plant',
    x: 39.0,
    y: 32.7,
    details: 'Utilities and wastewater treatment',
  ),
  CampusLocation(
    number: 34,
    name: 'Toilet',
    x: 42.0,
    y: 85.5,
    details: 'Public restroom facility',
  ),
  CampusLocation(
    number: 35,
    name: 'Parking',
    x: 21.0,
    y: 29.0,
    details: 'Parking area for students and staff',
  ),
];

class CampusMapPage extends StatefulWidget {
  const CampusMapPage({
    this.buildingApi,
    this.studentAuthService,
    this.openedFromStudentPortal = false,
    super.key,
  });

  final BuildingApiService? buildingApi;
  final StudentAuthService? studentAuthService;
  final bool openedFromStudentPortal;

  @override
  State<CampusMapPage> createState() => _CampusMapPageState();
}

enum _MarkerRole { normal, start, destination }

class _CampusMapPageState extends State<CampusMapPage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationPickerSearchController =
      TextEditingController();
  final RouteService _routeService = const RouteService();
  final DynamicBuildingRouteService _dynamicBuildingRouteService =
      const DynamicBuildingRouteService();
  late final BuildingApiService _buildingApi;
  late final AnimationController _routeAnimationController;

  List<CampusLocation> _dynamicLocations = const [];
  bool _loadingDynamicBuildings = true;
  String? _dynamicBuildingsError;
  CampusLocation? startLocation;
  CampusLocation? destinationLocation;
  CampusLocation? _longPressedMarker;
  RouteResult? routeResult;
  String? _routeError;
  bool _selectingStart = true;

  bool get _showStudentDashboardButton =>
      widget.openedFromStudentPortal &&
      (widget.studentAuthService?.isStudentAuthenticated ?? false) &&
      Navigator.of(context).canPop();

  @override
  void initState() {
    super.initState();
    _buildingApi = widget.buildingApi ?? BuildingApiService.instance;
    _routeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _loadDynamicBuildings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationPickerSearchController.dispose();
    _transformationController.dispose();
    _routeAnimationController.dispose();
    super.dispose();
  }

  void _syncRouteAnimation() {
    if (routeResult == null) {
      _routeAnimationController
        ..stop()
        ..value = 0;
    } else if (!_routeAnimationController.isAnimating) {
      _routeAnimationController.repeat();
    }
  }

  Future<void> _loadDynamicBuildings() async {
    setState(() {
      _loadingDynamicBuildings = true;
      _dynamicBuildingsError = null;
    });
    try {
      final buildings = await _buildingApi.fetchPublicBuildings();
      if (!mounted) return;
      final existingNames = campusLocations
          .map((location) => location.name.trim().toLowerCase())
          .toSet();
      setState(() {
        _dynamicLocations = buildings
            .where(
              (building) =>
                  building.isActive &&
                  building.isPublic &&
                  !existingNames.contains(building.name.trim().toLowerCase()),
            )
            .map(CampusLocation.fromBuilding)
            .toList(growable: false);
        _loadingDynamicBuildings = false;
      });
    } on BuildingApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingDynamicBuildings = false;
        _dynamicBuildingsError = error.message;
      });
    }
  }

  List<CampusLocation> get _allLocations =>
      [...campusLocations, ..._dynamicLocations];

  List<CampusLocation> get filteredLocations {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _allLocations;
    }

    return _allLocations.where((location) {
      return (!location.isDatabaseBuilding &&
              location.number.toString().contains(query)) ||
          location.name.toLowerCase().contains(query) ||
          location.details.toLowerCase().contains(query) ||
          (location.description?.toLowerCase().contains(query) ?? false) ||
          (location.locationDetails?.toLowerCase().contains(query) ?? false) ||
          (location.code?.toLowerCase().contains(query) ?? false) ||
          (location.category?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  bool get _hasSearchQuery => _searchController.text.trim().isNotEmpty;

  List<CampusLocation> get filteredPickerLocations {
    final query = _locationPickerSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _allLocations;
    }

    return _allLocations.where((location) {
      return (!location.isDatabaseBuilding &&
              location.number.toString().contains(query)) ||
          location.name.toLowerCase().contains(query) ||
          location.details.toLowerCase().contains(query) ||
          (location.description?.toLowerCase().contains(query) ?? false) ||
          (location.locationDetails?.toLowerCase().contains(query) ?? false) ||
          (location.code?.toLowerCase().contains(query) ?? false) ||
          (location.category?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  bool _sameLocation(CampusLocation? first, CampusLocation second) {
    if (first == null) return false;
    if (first.databaseId != null || second.databaseId != null) {
      return first.databaseId != null && first.databaseId == second.databaseId;
    }
    return first.number == second.number;
  }

  void _recalculateRoute() {
    if (startLocation == null || destinationLocation == null) {
      setState(() {
        routeResult = null;
        _routeError = 'Choose both a start location and a destination.';
      });
      _syncRouteAnimation();
      return;
    }

    final start = startLocation!;
    final destination = destinationLocation!;
    if (!start.hasMapCoordinates || !destination.hasMapCoordinates) {
      setState(() {
        routeResult = null;
        _routeError =
            'Directions are unavailable because this building has no verified map location.';
      });
      _syncRouteAnimation();
      return;
    }

    RouteResult? result;
    if (start.isDatabaseBuilding || destination.isDatabaseBuilding) {
      result = _dynamicBuildingRouteService.findRoute(
        start: Offset(start.x!, start.y!),
        destination: Offset(destination.x!, destination.y!),
        startRouteNodeId: start.isDatabaseBuilding ? start.routeNodeId : null,
        startConnectionVerified:
            start.isDatabaseBuilding && start.routeConnectionVerified,
        destinationRouteNodeId:
            destination.isDatabaseBuilding ? destination.routeNodeId : null,
        destinationConnectionVerified: destination.isDatabaseBuilding &&
            destination.routeConnectionVerified,
      );
    } else {
      result = _routeService.findRoute(
        startX: start.x!,
        startY: start.y!,
        destinationX: destination.x!,
        destinationY: destination.y!,
      );
    }

    setState(() {
      routeResult = result;
      _routeError = result == null
          ? 'Directions are not available. This building needs a verified connection to the campus path network.'
          : null;
    });
    _syncRouteAnimation();
  }

  void _showLocationSheet({required bool isStart}) {
    _locationPickerSearchController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DCE5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isStart
                            ? 'Select Start Location'
                            : 'Select Destination',
                        style: const TextStyle(
                          color: Color(0xFF073B78),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _locationPickerSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search location...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF073B78),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _locationPickerSearchController,
                  builder: (context, _, __) {
                    final locations = filteredPickerLocations;
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        final isSelected = isStart
                            ? _sameLocation(startLocation, location)
                            : _sameLocation(destinationLocation, location);

                        return InkWell(
                          onTap: () {
                            final selectingDuplicate = isStart
                                ? _sameLocation(destinationLocation, location)
                                : _sameLocation(startLocation, location);
                            if (selectingDuplicate) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Start and destination must be different.',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              if (isStart) {
                                startLocation = location;
                                _selectingStart = false;
                              } else {
                                destinationLocation = location;
                              }
                              routeResult = null;
                              _routeError = null;
                            });
                            _syncRouteAnimation();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFF7D6)
                                  : const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFFC107)
                                    : const Color(0xFFE3EAF2),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: const Color(0xFF073B78),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: location.isDatabaseBuilding
                                        ? const Icon(
                                            Icons.business_rounded,
                                            size: 17,
                                            color: Color(0xFF12356B),
                                          )
                                        : Text(
                                            '${location.number}',
                                            style: const TextStyle(
                                              color: Color(0xFF12356B),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        location.name,
                                        style: const TextStyle(
                                          color: Color(0xFF1F2937),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (location.isDatabaseBuilding)
                                        Text(
                                          '${location.category ?? 'Building'} • '
                                          '${location.hasMapCoordinates ? 'Map location available' : 'No map location'}',
                                          style: const TextStyle(
                                            color: Color(0xFF6C7F9D),
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (location.isDatabaseBuilding)
                                  IconButton(
                                    tooltip: 'Building details',
                                    onPressed: () =>
                                        _showBuildingDetails(location),
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                      color: Color(0xFF0755A0),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBuildingDetails(CampusLocation location) {
    if (!location.isDatabaseBuilding) return;
    final description = location.description?.trim() ?? '';
    final category = location.category?.trim().toLowerCase();
    final hasDescription =
        description.isNotEmpty && description.toLowerCase() != category;
    final locationDetails = location.locationDetails?.trim();
    final locationInformation = locationDetails?.isNotEmpty == true
        ? locationDetails
        : hasDescription
            ? description
            : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5DCE5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  location.name,
                  style: const TextStyle(
                    color: Color(0xFF073B78),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${location.code ?? ''} • ${location.category ?? 'Building'}',
                  style: const TextStyle(color: Color(0xFF536784)),
                ),
                if (locationInformation == null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Location information is not yet available.',
                    style: TextStyle(color: Color(0xFF536784)),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Location on campus',
                    style: TextStyle(
                      color: Color(0xFF203D68),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(locationInformation),
                ],
                if (locationDetails?.isNotEmpty == true && hasDescription) ...[
                  const SizedBox(height: 8),
                  Text('About this building: $description'),
                ],
                if (location.floorInfo?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text('Floor/room: ${location.floorInfo}'),
                ],
                const SizedBox(height: 12),
                if (location.hasMapCoordinates)
                  const Text(
                    'This building is shown at its saved location on the campus map.',
                    style: TextStyle(color: Color(0xFF536784)),
                  )
                else
                  const Text(
                    'A map marker is not yet available for this building.',
                    style: TextStyle(color: Color(0xFF536784)),
                  ),
                const SizedBox(height: 8),
                Text(
                  location.hasVerifiedRoute
                      ? 'Directions are available through the verified walkable-path connection.'
                      : 'Directions are not available until a map location and walkable-path connection are verified.',
                  style: const TextStyle(color: Color(0xFF536784)),
                ),
                if (location.hasVerifiedRoute) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      setState(() {
                        destinationLocation = location;
                        _selectingStart = false;
                        routeResult = null;
                        _routeError = null;
                      });
                      if (startLocation != null) {
                        _recalculateRoute();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Choose a start location to get directions.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.route_rounded),
                    label: const Text('Get Directions'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF073B78),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_showStudentDashboardButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _returnToStudentDashboard,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to Student Dashboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF073B78),
                      side: const BorderSide(color: Color(0xFFB8C9DE)),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _buildSearchBar(),
                        ),
                        if (_hasSearchQuery) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: _buildSearchResults(),
                          ),
                        ],
                        if (_loadingDynamicBuildings &&
                            _dynamicLocations.isEmpty)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        if (_dynamicBuildingsError != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                            child: _VisitorBuildingsError(
                              message: _dynamicBuildingsError!,
                              onRetry: _loadDynamicBuildings,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _buildSelectionMode(),
                        ),
                        if (startLocation != null &&
                            destinationLocation != null) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: _buildNavigationActions(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _buildMapPanel(),
                        ),
                        const SizedBox(height: 16),
                        if (!_hasSearchQuery) _buildLocationsPanel(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _returnToStudentDashboard() {
    final navigator = Navigator.of(context);
    if (widget.studentAuthService?.isStudentAuthenticated != true) {
      navigator.pushReplacementNamed('/login');
      return;
    }

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed('/student-dashboard');
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF062B5C), Color(0xFF073B78)],
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 48,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'UCU SMART+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                icon: const Icon(
                  Icons.construction_rounded,
                  color: Color(0xFF0755A0),
                  size: 36,
                ),
                title: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Color(0xFF073B78),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                content: const Text(
                  'More features will be available here in a future update.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF536784)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
                actionsAlignment: MainAxisAlignment.center,
              ),
            ),
            tooltip: 'Select start location',
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Material(
      elevation: 3,
      shadowColor: const Color(0x14062B5C),
      borderRadius: BorderRadius.circular(28),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search building, room, or facility...',
          hintStyle: const TextStyle(
            color: Color(0xFF536784),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF0755A0),
            size: 32,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSelectionMode() {
    return Row(
      children: [
        Expanded(
          child: _buildModeButton(
            label: 'Start Location',
            icon: Icons.circle,
            color: const Color(0xFF1976D2),
            selected: _selectingStart,
            onPressed: () {
              setState(() => _selectingStart = true);
              _showLocationSheet(isStart: true);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildModeButton(
            label: 'Destination',
            icon: Icons.location_on_rounded,
            color: const Color(0xFFD93025),
            selected: !_selectingStart,
            onPressed: () {
              setState(() => _selectingStart = false);
              _showLocationSheet(isStart: false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? color : const Color(0xFF6C7F9D),
        backgroundColor:
            selected ? color.withValues(alpha: 0.08) : Colors.white,
        side: BorderSide(
          color: selected ? color : const Color(0xFFDCE7F3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFindRouteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _recalculateRoute,
        icon: const Icon(Icons.route_rounded),
        label: const Text('Find Route'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF073B78),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildNavigationActions() {
    return Column(
      children: [
        _buildFindRouteButton(),
        if (_routeError != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _routeError!,
              style: const TextStyle(
                color: Color(0xFF8B2424),
                fontSize: 13,
              ),
            ),
          ),
        ],
        if (routeResult != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelRoute,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF073B78),
                    side: const BorderSide(color: Color(0xFFB8C9DE)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancel Route'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _cancelRoute() {
    setState(() {
      startLocation = null;
      destinationLocation = null;
      routeResult = null;
      _routeError = null;
      _selectingStart = true;
    });
    _syncRouteAnimation();
  }

  Widget _buildMapPanel() {
    const double campusMapAspectRatio = 1412 / 1114;

    return Material(
      elevation: 10,
      shadowColor: const Color(0x1A062B5C),
      borderRadius: BorderRadius.circular(22),
      color: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: campusMapAspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mapWidth = constraints.maxWidth;
                  final mapHeight = constraints.maxHeight;

                  return InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.7,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.all(500),
                    child: SizedBox(
                      width: mapWidth,
                      height: mapHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/ucu_campus_map.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          if (routeResult != null)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: RoutePainter(
                                  routeResult!.points,
                                  animation: _routeAnimationController,
                                ),
                              ),
                            ),
                          ...campusLocations.map((location) {
                            final isStart =
                                startLocation?.number == location.number;
                            final isDestination =
                                destinationLocation?.number == location.number;
                            final role = isStart
                                ? _MarkerRole.start
                                : isDestination
                                    ? _MarkerRole.destination
                                    : _MarkerRole.normal;

                            return Positioned(
                              left: mapWidth * (location.x! / 100) -
                                  (role == _MarkerRole.normal
                                      ? 8
                                      : role == _MarkerRole.destination
                                          ? 20
                                          : 12),
                              top: mapHeight * (location.y! / 100) -
                                  (role == _MarkerRole.normal
                                      ? 8
                                      : role == _MarkerRole.destination
                                          ? 20
                                          : 12),
                              child: _buildMapMarker(
                                location: location,
                                role: role,
                              ),
                            );
                          }),
                          if (_longPressedMarker != null)
                            _buildNumberedMarkerTooltip(
                              _longPressedMarker!,
                              mapWidth: mapWidth,
                              mapHeight: mapHeight,
                            ),
                          ..._dynamicLocations
                              .where((location) => location.hasMapCoordinates)
                              .map((location) {
                            final isStart =
                                _sameLocation(startLocation, location);
                            final isDestination =
                                _sameLocation(destinationLocation, location);
                            final role = isStart
                                ? _MarkerRole.start
                                : isDestination
                                    ? _MarkerRole.destination
                                    : _MarkerRole.normal;
                            final markerPosition = percentToMapPixel(
                              Size(mapWidth, mapHeight),
                              Offset(location.x!, location.y!),
                            );
                            return Positioned(
                              left: markerPosition.dx - 10,
                              top: markerPosition.dy - 10,
                              child: _buildDynamicBuildingMarker(
                                location: location,
                                role: role,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: Column(
                children: [
                  _buildMapControl(
                    icon: Icons.add,
                    onPressed: _zoomIn,
                  ),
                  const SizedBox(height: 10),
                  _buildMapControl(
                    icon: Icons.remove,
                    onPressed: _zoomOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      elevation: 5,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(icon, color: const Color(0xFF0755A0), size: 32),
        ),
      ),
    );
  }

  void _zoomIn() {
    final next = _transformationController.value.clone()
      ..scaleByDouble(1.25, 1.25, 1.0, 1.0);
    _transformationController.value = next;
  }

  void _zoomOut() {
    final next = _transformationController.value.clone()
      ..scaleByDouble(0.8, 0.8, 1.0, 1.0);
    _transformationController.value = next;
  }

  Widget _buildLocationsPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 0, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14062B5C),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF0755A0),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Campus Locations',
                  style: TextStyle(
                    color: Color(0xFF0755A0),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${filteredLocations.length} locations',
                style: const TextStyle(
                  color: Color(0xFF6C7F9D),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                tooltip: 'Refresh building list',
                onPressed:
                    _loadingDynamicBuildings ? null : _loadDynamicBuildings,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 24),
              itemCount:
                  filteredLocations.isEmpty ? 1 : filteredLocations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (filteredLocations.isEmpty) {
                  return const SizedBox(
                    width: 220,
                    child: Center(
                      child: Text(
                        'No buildings found',
                        style: TextStyle(
                          color: Color(0xFF6C7F9D),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                final location = filteredLocations[index];
                return _buildLocationCard(location);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = filteredLocations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${results.length} matching ${results.length == 1 ? 'building' : 'buildings'}',
          style: const TextStyle(
            color: Color(0xFF0755A0),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'No buildings found',
              style: TextStyle(
                color: Color(0xFF6C7F9D),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ...results.map(
            (location) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSearchResultCard(location),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResultCard(CampusLocation location) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7F3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB8C9DE), width: 2),
            ),
            child: Center(
              child: location.isDatabaseBuilding
                  ? const Icon(Icons.business_rounded,
                      size: 18, color: Color(0xFF12356B))
                  : Text(
                      '${location.number}',
                      style: const TextStyle(
                        color: Color(0xFF12356B),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(
                    color: Color(0xFF203D68),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location.category ?? 'Building',
                  style: const TextStyle(
                    color: Color(0xFF7A8EAB),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return location.isDatabaseBuilding
        ? InkWell(
            onTap: () => _showBuildingDetails(location),
            borderRadius: BorderRadius.circular(12),
            child: card,
          )
        : card;
  }

  Widget _buildLocationCard(CampusLocation location) {
    final card = Container(
      width: 190,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE7F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB8C9DE), width: 2),
            ),
            child: Center(
              child: location.isDatabaseBuilding
                  ? const Icon(Icons.business_rounded,
                      size: 18, color: Color(0xFF12356B))
                  : Text(
                      '${location.number}',
                      style: const TextStyle(
                        color: Color(0xFF12356B),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            location.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF203D68),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.business_rounded,
                  color: Color(0xFF7A8EAB), size: 16),
              const SizedBox(width: 6),
              Text(
                location.category ?? 'Building',
                style: const TextStyle(
                  color: Color(0xFF7A8EAB),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return location.isDatabaseBuilding
        ? InkWell(
            onTap: () => _showBuildingDetails(location),
            borderRadius: BorderRadius.circular(14),
            child: card,
          )
        : card;
  }

  Widget _buildMapMarker({
    required CampusLocation location,
    required _MarkerRole role,
  }) {
    return GestureDetector(
      onTap: () => _showLocationSheet(isStart: _selectingStart),
      onLongPressStart: (_) => setState(() {
        _longPressedMarker = location;
      }),
      onLongPressEnd: (_) => _hideNumberedMarkerTooltip(location),
      onLongPressCancel: () => _hideNumberedMarkerTooltip(location),
      child: Transform.scale(
        scale: role == _MarkerRole.normal ? 0.75 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: role == _MarkerRole.normal ? 16 : 24,
          height: role == _MarkerRole.normal ? 16 : 24,
          decoration: BoxDecoration(
            color: role == _MarkerRole.start
                ? const Color(0xFF1976D2)
                : role == _MarkerRole.destination
                    ? const Color(0xFFD93025)
                    : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: role == _MarkerRole.normal
                  ? const Color(0xFF12356B)
                  : Colors.white,
              width: role == _MarkerRole.normal ? 2 : 2.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33062B5C),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${location.number}',
              style: TextStyle(
                color: role == _MarkerRole.normal
                    ? const Color(0xFF073B78)
                    : Colors.white,
                fontSize: role == _MarkerRole.normal ? 7 : 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _hideNumberedMarkerTooltip(CampusLocation location) {
    if (_longPressedMarker?.number == location.number && mounted) {
      setState(() {
        _longPressedMarker = null;
      });
    }
  }

  Widget _buildNumberedMarkerTooltip(
    CampusLocation location, {
    required double mapWidth,
    required double mapHeight,
  }) {
    const horizontalInset = 8.0;
    const tooltipHeight = 44.0;
    final tooltipWidth = mapWidth < 200 ? mapWidth - 24 : 176.0;
    final markerCenterX = mapWidth * (location.x! / 100);
    final markerCenterY = mapHeight * (location.y! / 100);
    final left = (markerCenterX - tooltipWidth / 2)
        .clamp(horizontalInset, mapWidth - tooltipWidth - horizontalInset)
        .toDouble();
    final top = (markerCenterY < tooltipHeight + 16
            ? markerCenterY + 18
            : markerCenterY - tooltipHeight - 8)
        .clamp(8.0, mapHeight - tooltipHeight - 8)
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Material(
          key: const ValueKey('numbered-marker-name-tooltip'),
          color: const Color(0xFF073B78),
          elevation: 3,
          shadowColor: const Color(0x55000000),
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: tooltipWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              child: Center(
                child: Text(
                  location.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicBuildingMarker({
    required CampusLocation location,
    required _MarkerRole role,
  }) {
    final color = role == _MarkerRole.start
        ? const Color(0xFF1976D2)
        : role == _MarkerRole.destination
            ? const Color(0xFFD93025)
            : const Color(0xFF00A6A6);
    return GestureDetector(
      onTap: () => _showBuildingDetails(location),
      child: Tooltip(
        message: location.name,
        child: Container(
          width: role == _MarkerRole.normal ? 20 : 26,
          height: role == _MarkerRole.normal ? 20 : 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44062B5C),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.business_rounded,
            color: Colors.white,
            size: 12,
          ),
        ),
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  RoutePainter(this.points, {required this.animation})
      : super(repaint: animation);

  final List<Offset> points;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final scaled = points
        .map((point) => Offset(
            size.width * (point.dx / 100), size.height * (point.dy / 100)))
        .toList();

    final path = Path()..moveTo(scaled.first.dx, scaled.first.dy);
    for (var i = 1; i < scaled.length; i++) {
      path.lineTo(scaled[i].dx, scaled[i].dy);
    }

    final glow = Paint()
      ..color = const Color(0x333A7AF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final route = Paint()
      ..color = const Color(0xFF1E88E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, outline);
    canvas.drawPath(path, route);

    final metric = path.computeMetrics().first;
    final highlightLength = metric.length * 0.08;
    final highlightStart = animation.value * metric.length;
    final highlightEnd = highlightStart + highlightLength;
    final highlightGlow = Paint()
      ..color = const Color(0x4442A5F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final highlight = Paint()
      ..color = const Color(0xBFE3F2FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (highlightEnd <= metric.length) {
      final movingSegment = metric.extractPath(highlightStart, highlightEnd);
      canvas.drawPath(movingSegment, highlightGlow);
      canvas.drawPath(movingSegment, highlight);
    } else {
      final tail = metric.extractPath(highlightStart, metric.length);
      final head = metric.extractPath(0, highlightEnd - metric.length);
      canvas
        ..drawPath(tail, highlightGlow)
        ..drawPath(head, highlightGlow)
        ..drawPath(tail, highlight)
        ..drawPath(head, highlight);
    }
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) => true;
}

class _VisitorBuildingsError extends StatelessWidget {
  const _VisitorBuildingsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Online building list unavailable. Showing saved campus locations. $message',
              style: const TextStyle(
                color: Color(0xFF755400),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
