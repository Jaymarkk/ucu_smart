import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/campus_restriction_screen.dart';
import '../services/campus_geofence_service.dart';
import '../services/campus_map_development_policy.dart';
import '../services/campus_visitor_access_session.dart';
import '../services/student_auth_service.dart';

class CampusAccessGate extends StatefulWidget {
  const CampusAccessGate({
    required this.child,
    required this.geofenceService,
    this.studentAuthService,
    this.isVisitorMode = false,
    this.currentRouteName,
    this.onVisitorAccessGranted,
    this.onVisitorAccessRestricted,
    super.key,
  });

  final Widget child;
  final CampusGeofenceService geofenceService;
  final StudentAuthService? studentAuthService;
  final bool isVisitorMode;
  final ValueListenable<String?>? currentRouteName;
  final VoidCallback? onVisitorAccessGranted;
  final VoidCallback? onVisitorAccessRestricted;

  @override
  State<CampusAccessGate> createState() => _CampusAccessGateState();
}

class _CampusAccessGateState extends State<CampusAccessGate>
    with WidgetsBindingObserver {
  Timer? _recheckTimer;
  late CampusVisitorAccessSession _visitorAccessSession;

  @override
  void initState() {
    super.initState();
    _visitorAccessSession = _createVisitorAccessSession();
    WidgetsBinding.instance.addObserver(this);
    widget.geofenceService.addListener(_onAccessChanged);
    widget.studentAuthService?.addListener(_onStudentAuthChanged);
    widget.currentRouteName?.addListener(_onRouteChanged);
    _syncGeofenceMonitoring();
  }

  CampusVisitorAccessSession _createVisitorAccessSession() =>
      CampusVisitorAccessSession(
        maxLocationAge: widget.geofenceService.maxLocationAge,
        clock: DateTime.now,
      );

  @override
  void didUpdateWidget(covariant CampusAccessGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    final serviceChanged = oldWidget.geofenceService != widget.geofenceService;
    final authServiceChanged =
        oldWidget.studentAuthService != widget.studentAuthService;
    final visitorModeChanged = oldWidget.isVisitorMode != widget.isVisitorMode;
    final routeListenableChanged =
        oldWidget.currentRouteName != widget.currentRouteName;
    if (serviceChanged) {
      oldWidget.geofenceService.removeListener(_onAccessChanged);
      widget.geofenceService.addListener(_onAccessChanged);
      _visitorAccessSession = _createVisitorAccessSession();
    }
    if (authServiceChanged) {
      oldWidget.studentAuthService?.removeListener(_onStudentAuthChanged);
      widget.studentAuthService?.addListener(_onStudentAuthChanged);
    }
    if (routeListenableChanged) {
      oldWidget.currentRouteName?.removeListener(_onRouteChanged);
      widget.currentRouteName?.addListener(_onRouteChanged);
    }
    if (serviceChanged ||
        authServiceChanged ||
        visitorModeChanged ||
        routeListenableChanged) {
      if (visitorModeChanged && !widget.isVisitorMode) {
        _visitorAccessSession.reset();
      }
      _syncGeofenceMonitoring();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isDevelopmentBypassedCampusMapRoute ||
          _isAuthenticatedStudentPortalRoute) {
        _recheckTimer?.cancel();
        _recheckTimer = null;
      } else {
        unawaited(widget.geofenceService.refresh());
        _startRecheckTimer();
      }
    } else {
      _recheckTimer?.cancel();
      _recheckTimer = null;
    }
  }

  void _startRecheckTimer() {
    _recheckTimer?.cancel();
    _recheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(widget.geofenceService.refresh()),
    );
  }

  void _onAccessChanged() {
    if (!mounted) return;
    if (!widget.geofenceService.isChecking) {
      _updateVisitorAccess();
    }
    setState(() {});
  }

  void _onRouteChanged() {
    if (!mounted) return;
    _syncGeofenceMonitoring();
    _rebuildForStateChange();
  }

  void _onStudentAuthChanged() {
    if (!mounted) return;
    _syncGeofenceMonitoring();
    _rebuildForStateChange();
  }

  void _updateVisitorAccess() {
    if (!widget.isVisitorMode) {
      _visitorAccessSession.reset();
      return;
    }
    final transition = _visitorAccessSession.update(
      state: widget.geofenceService.state,
      diagnostic: widget.geofenceService.lastGpsDiagnostic,
    );
    if (transition == CampusVisitorAccessTransition.entered) {
      widget.onVisitorAccessGranted?.call();
    } else if (transition == CampusVisitorAccessTransition.exited ||
        transition == CampusVisitorAccessTransition.expired) {
      widget.onVisitorAccessRestricted?.call();
    }
  }

  void _rebuildForStateChange() {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    binding.ensureVisualUpdate();
  }

  void _syncGeofenceMonitoring() {
    if (_isBootstrapRoute ||
        _isDevelopmentBypassedCampusMapRoute ||
        _isAuthenticatedStudentPortalRoute) {
      _recheckTimer?.cancel();
      _recheckTimer = null;
      return;
    }
    unawaited(widget.geofenceService.refresh());
    _startRecheckTimer();
  }

  bool get _isBootstrapRoute {
    final routeNameListenable = widget.currentRouteName;
    if (routeNameListenable == null) return false;
    final routeName = routeNameListenable.value;
    return routeName == null ||
        routeName.isEmpty ||
        routeName == '/' ||
        routeName == '/login' ||
        routeName == '/student-login';
  }

  bool get _isCampusVerificationRoute =>
      widget.currentRouteName?.value == '/campus-verification';

  bool get _isDevelopmentBypassedCampusMapRoute =>
      campusMapDevelopmentBypassEnabled &&
      widget.currentRouteName?.value == '/campus-map';

  bool get _isAuthenticatedStudentPortalRoute {
    if (widget.studentAuthService?.isStudentAuthenticated != true) {
      return false;
    }

    final routeName = widget.currentRouteName?.value;
    return routeName == '/student-dashboard' ||
        routeName == '/student/profile' ||
        routeName == '/student/room-availability' ||
        routeName?.startsWith('/student/buildings/') == true ||
        routeName?.startsWith('/student/rooms/') == true;
  }

  bool get _visitorRouteAllowed {
    final routeName = widget.currentRouteName?.value;
    return routeName == null ||
        routeName.isEmpty ||
        routeName == '/' ||
        routeName == '/login' ||
        routeName == '/student-login' ||
        routeName == '/campus-map' ||
        routeName == '/campus-verification';
  }

  @override
  void dispose() {
    _recheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.geofenceService.removeListener(_onAccessChanged);
    widget.studentAuthService?.removeListener(_onStudentAuthChanged);
    widget.currentRouteName?.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.geofenceService.state;
    if (_isBootstrapRoute && !widget.isVisitorMode) return widget.child;
    if (widget.isVisitorMode && !_visitorRouteAllowed) {
      return _buildVisitorRestrictedPage();
    }
    if (_isDevelopmentBypassedCampusMapRoute) return widget.child;
    if (_isAuthenticatedStudentPortalRoute) return widget.child;
    if (widget.isVisitorMode) {
      if (_isCampusVerificationRoute || !_visitorAccessSession.isActive) {
        return _buildRestrictionScreen(state);
      }
      return widget.child;
    }
    if (state.isGranted) return widget.child;
    return _buildRestrictionScreen(state);
  }

  Widget _buildRestrictionScreen(CampusAccessState state) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FocusScope(
          canRequestFocus: false,
          descendantsAreFocusable: false,
          child: ExcludeSemantics(
            child: IgnorePointer(child: widget.child),
          ),
        ),
        CampusRestrictionScreen(
          state: state,
          onOpenSettings: () => widget.geofenceService.openSettings(),
        ),
      ],
    );
  }

  Widget _buildVisitorRestrictedPage() => Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Color(0xFF2457A7),
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Visitor mode is limited to the Campus Map.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sign in with a Student account to access Student pages.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
