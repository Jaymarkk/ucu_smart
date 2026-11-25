import 'campus_geofence_service.dart';

enum CampusVisitorAccessTransition { none, entered, exited, expired }

class CampusVisitorAccessSession {
  CampusVisitorAccessSession({
    required this.maxLocationAge,
    required this.clock,
    this.requiredOutsideConfirmations = 2,
  }) {
    if (maxLocationAge <= Duration.zero || requiredOutsideConfirmations < 1) {
      throw ArgumentError('Visitor access session policy is invalid.');
    }
  }

  final Duration maxLocationAge;
  final DateTime Function() clock;
  final int requiredOutsideConfirmations;

  bool _isActive = false;
  DateTime? _lastAccessVerifiedAt;
  int _consecutiveOutsideResults = 0;

  bool get isActive {
    final lastAccess = _lastAccessVerifiedAt;
    final age = lastAccess == null ? null : clock().difference(lastAccess);
    return _isActive && age != null && !age.isNegative && age <= maxLocationAge;
  }

  int get consecutiveOutsideResults => _consecutiveOutsideResults;

  CampusVisitorAccessTransition update({
    required CampusAccessState state,
    required CampusGpsDiagnostic? diagnostic,
  }) {
    if (state.status == CampusAccessStatus.granted && diagnostic != null) {
      final wasActive = isActive;
      _isActive = true;
      _lastAccessVerifiedAt = clock();
      _consecutiveOutsideResults = 0;
      return wasActive
          ? CampusVisitorAccessTransition.none
          : CampusVisitorAccessTransition.entered;
    }

    if (state.status == CampusAccessStatus.outside) {
      _consecutiveOutsideResults++;
      if (_isActive &&
          _consecutiveOutsideResults >= requiredOutsideConfirmations) {
        reset();
        return CampusVisitorAccessTransition.exited;
      }
    } else {
      _consecutiveOutsideResults = 0;
    }

    if (_isActive && !isActive) {
      reset();
      return CampusVisitorAccessTransition.expired;
    }
    return CampusVisitorAccessTransition.none;
  }

  CampusVisitorAccessTransition expireIfNeeded() {
    if (_isActive && !isActive) {
      reset();
      return CampusVisitorAccessTransition.expired;
    }
    return CampusVisitorAccessTransition.none;
  }

  void reset() {
    _isActive = false;
    _lastAccessVerifiedAt = null;
    _consecutiveOutsideResults = 0;
  }
}
