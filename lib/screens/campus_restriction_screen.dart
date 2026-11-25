import 'package:flutter/material.dart';

import 'campus_restriction_copy.dart';
import '../services/campus_geofence_service.dart';

class CampusRestrictionScreen extends StatefulWidget {
  const CampusRestrictionScreen({
    required this.state,
    required this.onOpenSettings,
    super.key,
  });

  final CampusAccessState state;
  final Future<void> Function() onOpenSettings;

  @override
  State<CampusRestrictionScreen> createState() =>
      _CampusRestrictionScreenState();
}

class _CampusRestrictionScreenState extends State<CampusRestrictionScreen> {
  static const _navy = Color(0xFF123665);
  static const _mutedText = Color(0xFF596579);

  bool get _showSettings =>
      widget.state.status == CampusAccessStatus.permissionDenied ||
      widget.state.status == CampusAccessStatus.permissionDeniedForever ||
      widget.state.status == CampusAccessStatus.locationServicesDisabled;

  bool get _isUnsupported =>
      widget.state.status == CampusAccessStatus.unsupported;

  bool get _isWarning =>
      widget.state.status != CampusAccessStatus.unsupported &&
      widget.state.status != CampusAccessStatus.granted &&
      widget.state.status != CampusAccessStatus.checking;

  String get _statusLabel => switch (widget.state.status) {
        CampusAccessStatus.checking => 'Location Verification in Progress',
        CampusAccessStatus.granted => 'Campus Location Confirmed',
        CampusAccessStatus.unconfigured ||
        CampusAccessStatus.invalidBoundary ||
        CampusAccessStatus.unavailable ||
        CampusAccessStatus.unsupported =>
          CampusRestrictionCopy.unavailableTitle,
        CampusAccessStatus.outside => 'Location Outside Campus Boundary',
        CampusAccessStatus.inaccurate => 'Location Accuracy Insufficient',
        CampusAccessStatus.boundaryUncertain ||
        CampusAccessStatus.permissionDenied ||
        CampusAccessStatus.permissionDeniedForever ||
        CampusAccessStatus.locationServicesDisabled ||
        CampusAccessStatus.stale =>
          'Location Verification Required',
      };

  String get _statusMessage => switch (widget.state.status) {
        CampusAccessStatus.checking =>
          'Your current location is being checked. Please wait for verification to complete.',
        CampusAccessStatus.granted =>
          'Your current location has been successfully verified within Urdaneta City University.',
        CampusAccessStatus.unconfigured ||
        CampusAccessStatus.invalidBoundary =>
          'Campus location verification is currently unavailable. Please contact the university support team.',
        CampusAccessStatus.outside =>
          'Your current location is outside the authorized Urdaneta City University campus boundary.',
        CampusAccessStatus.inaccurate =>
          'Your current location cannot be verified accurately. Please ensure that location services are enabled and that your device can obtain a reliable location reading.',
        CampusAccessStatus.boundaryUncertain =>
          'Your current location is too close to the campus boundary to be verified with confidence. Access remains restricted until your location can be confirmed.',
        CampusAccessStatus.permissionDenied ||
        CampusAccessStatus.permissionDeniedForever =>
          'Location permission is required to verify campus access. Please allow location access in your device settings.',
        CampusAccessStatus.locationServicesDisabled =>
          'Please enable location services on your device to verify campus access.',
        CampusAccessStatus.unsupported =>
          CampusRestrictionCopy.unsupportedDescription,
        CampusAccessStatus.stale =>
          'A current location reading is required. Please keep the app open while location verification continues.',
        CampusAccessStatus.unavailable =>
          'Your current location is temporarily unavailable. Campus access requires a valid location verification.',
      };

  IconData get _statusIcon => switch (widget.state.status) {
        CampusAccessStatus.checking => Icons.location_searching,
        CampusAccessStatus.granted => Icons.verified_outlined,
        CampusAccessStatus.permissionDenied ||
        CampusAccessStatus.permissionDeniedForever ||
        CampusAccessStatus.locationServicesDisabled =>
          Icons.location_disabled_outlined,
        CampusAccessStatus.unsupported => Icons.location_off_outlined,
        CampusAccessStatus.outside ||
        CampusAccessStatus.boundaryUncertain ||
        CampusAccessStatus.inaccurate ||
        CampusAccessStatus.stale ||
        CampusAccessStatus.unconfigured ||
        CampusAccessStatus.invalidBoundary ||
        CampusAccessStatus.unavailable =>
          Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _isUnsupported
        ? const Color(0xFF2457A7)
        : _isWarning
            ? const Color(0xFF9A681B)
            : const Color(0xFF40536D);
    final statusBackground = _isUnsupported
        ? const Color(0xFFEAF2FF)
        : _isWarning
            ? const Color(0xFFFFF8E8)
            : const Color(0xFFF3F6FA);
    final statusBorder = _isUnsupported
        ? const Color(0xFFD4E3FA)
        : _isWarning
            ? const Color(0xFFF2DFB6)
            : const Color(0xFFE0E7F0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xD9062B5C),
                  Color(0xB3073B78),
                  Color(0xF2061835),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 700;
                final narrow = constraints.maxWidth < 480;
                final horizontalPadding = narrow ? 18.0 : 28.0;
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: compact ? 14 : 28,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: narrow ? 22 : 38,
                          vertical: compact ? 24 : 34,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE4EAF2)),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3007193A),
                              blurRadius: 30,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F6FC),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    semanticLabel: 'UCU Smart+ logo',
                                  ),
                                ),
                                const SizedBox(width: 13),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        CampusRestrictionCopy.appName,
                                        style: TextStyle(
                                          color: _navy,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        CampusRestrictionCopy.headerSubtitle,
                                        style: TextStyle(
                                          color: _mutedText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFF7892B8),
                                  size: 23,
                                ),
                              ],
                            ),
                            SizedBox(height: compact ? 25 : 34),
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF2FF),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF2457A7),
                                  size: 34,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              CampusRestrictionCopy.title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: _navy,
                                fontSize: narrow ? 23 : 27,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 11),
                            const Text(
                              CampusRestrictionCopy.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _mutedText,
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: compact ? 22 : 28),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(17),
                              decoration: BoxDecoration(
                                color: statusBackground,
                                border: Border.all(
                                  color: statusBorder,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.82),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      _statusIcon,
                                      color: statusColor,
                                      size: 23,
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _statusLabel,
                                          style: const TextStyle(
                                            color: _navy,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _statusMessage,
                                          style: TextStyle(
                                            color: _isUnsupported
                                                ? const Color(0xFF526B8D)
                                                : _mutedText,
                                            fontSize: 14,
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 18 : 22),
                            const Text(
                              'Location verification occurs automatically while '
                              'the app is active and when it resumes. Campus Map '
                              'access remains restricted until your location is '
                              'successfully verified.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _mutedText,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            if (_showSettings) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: widget.onOpenSettings,
                                  icon: const Icon(Icons.settings_outlined),
                                  label: const Text('Open location settings'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _navy,
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFD3DDE9),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: compact ? 21 : 26),
                            const Divider(
                              height: 1,
                              color: Color(0xFFE8EDF3),
                            ),
                            const SizedBox(height: 17),
                            const Center(
                              child: Text(
                                CampusRestrictionCopy.footer,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF748196),
                                  fontSize: 12,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
