import 'package:flutter/foundation.dart';

const String campusMapDevelopmentBypassDefine =
    'UCU_SMART_DEV_CAMPUS_MAP_BYPASS';

bool shouldEnableCampusMapDevelopmentBypass({
  required bool isDebugBuild,
  required bool requested,
}) =>
    isDebugBuild && requested;

final bool campusMapDevelopmentBypassEnabled =
    shouldEnableCampusMapDevelopmentBypass(
  isDebugBuild: kDebugMode,
  requested: const bool.fromEnvironment(
    campusMapDevelopmentBypassDefine,
    defaultValue: true,
  ),
);
