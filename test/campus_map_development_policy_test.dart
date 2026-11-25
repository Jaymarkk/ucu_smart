import 'package:flutter_test/flutter_test.dart';
import 'package:ucu_smart_plus/services/campus_map_development_policy.dart';

void main() {
  test('development bypass is enabled by default for debug runs', () {
    expect(
      shouldEnableCampusMapDevelopmentBypass(
        isDebugBuild: true,
        requested: true,
      ),
      isTrue,
    );
  });

  test('development bypass can be explicitly disabled for debug runs', () {
    expect(
      shouldEnableCampusMapDevelopmentBypass(
        isDebugBuild: true,
        requested: false,
      ),
      isFalse,
    );
  });

  test('profile and release builds cannot enable the bypass', () {
    expect(
      shouldEnableCampusMapDevelopmentBypass(
        isDebugBuild: false,
        requested: true,
      ),
      isFalse,
    );
  });
}
