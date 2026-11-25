# UCU SMART+ Live GPS Location Implementation

## Scope

The app now connects the phone's live GPS position to the existing UCU SMART+ 2D campus map.

The following existing behavior remains unchanged:

- Campus map image: `assets/images/ucu_campus_map.png`
- Existing 35 campus markers and their coordinates
- Existing route and navigation drawing
- Existing GPS permission and service handling
- Existing `InteractiveViewer` zoom and pan settings
- Existing GPS status card

## Modified Files

- `lib/main.dart`
- `lib/services/coordinate_converter.dart`
- `lib/widgets/current_location_dot.dart`

## GPS-to-Map Calibration

The converter uses a local planar coordinate system:

```text
latitude/longitude
    -> local East/North meters
    -> weighted affine map transformation
    -> map percentage x/y
```

The transformation does not assume that the campus map is north-up. It uses the collected UCU GPS control points and their map coordinates.

GPS accuracy is used as a weight. More accurate readings have greater influence through inverse accuracy variance:

```text
weight = 1 / accuracy^2
```

The output is a `MapPoint` with values clamped to the valid map range:

```text
x = 0..100 percent from left to right
y = 0..100 percent from top to bottom
```

## Calibration Control Points

| Location | Latitude | Longitude | Accuracy | Map X | Map Y |
|---|---:|---:|---:|---:|---:|
| Main Gate | 15.981357 | 120.560273 | 13.0 m | 34.0% | 7.5% |
| Gymnasium | 15.980468 | 120.560556 | 21.6 m | 49.0% | 81.0% |
| University Clinic | 15.980168 | 120.560537 | 15.9 m | 44.0% | 53.0% |
| Dr. Leoncio Ancheta Bldg. 1 | 15.980414 | 120.561446 | 16.3 m | 53.0% | 22.0% |
| Badar Building | 15.979941 | 120.561352 | 11.6 m | 82.0% | 43.0% |

## Main Gate Constants

The initial Main Gate calibration is centralized in `lib/services/coordinate_converter.dart`:

```dart
CoordinateConverter.MAIN_GATE_MAP_X
CoordinateConverter.MAIN_GATE_MAP_Y
```

Current values:

```text
MAIN_GATE_MAP_X = 34.0
MAIN_GATE_MAP_Y = 7.5
```

These values are an initial calibration near the upper entrance around marker #32. Marker #32 itself was not changed.

## Live Blue Location Dot

The existing `Geolocator.getPositionStream` supplies live GPS updates. For each new position:

1. Latitude, longitude, and accuracy are updated.
2. The coordinates are converted to a `MapPoint`.
3. Flutter rebuilds only the affected widget tree through the existing state update.
4. The blue dot moves to the converted map position.

The dot is rendered as:

- Solid blue center
- White outer border
- Translucent blue accuracy circle
- Subtle shadow

The accuracy circle is visual guidance only. Because the campus map is schematic, it must not be interpreted as exact geographic coverage.

## Zoom and Pan Alignment

The location dot is placed inside the same map `Stack` as:

- The campus map image
- The route painter
- The existing numbered markers

It therefore remains attached to the map during zooming, zooming out, and panning through the existing `InteractiveViewer`.

## My Location Button

The existing My Location button now:

1. Rechecks GPS and permissions through the existing GPS service.
2. Gets the latest GPS position.
3. Converts it to map coordinates.
4. Centers the map on the current dot while preserving the current zoom scale.

Manual panning is still allowed afterward. The map does not continuously force-follow the user.

## Accuracy Limitations

- The collected GPS samples have approximately 10-20 meter accuracy.
- GPS position near buildings can represent an entrance, road, gate, or nearby open area rather than a building center.
- The campus map is a custom 2D/schematic map, not a geographically exact map.
- The blue dot is an estimated map position.
- Main Gate calibration should be refined with additional confirmed field measurements.
- This implementation does not claim meter-level indoor positioning.

## Validation

The following checks passed after implementation:

```text
flutter pub get
flutter analyze
Existing widget test: passed
```

## Real Device Test

Run:

```powershell
flutter devices
flutter run -d <device-id>
```

On a real Android phone, verify:

1. Location permission is granted.
2. The blue dot appears after GPS becomes available.
3. The dot moves after walking a short distance.
4. The accuracy circle changes with GPS accuracy.
5. Zooming keeps the dot attached to the same map position.
6. Panning keeps the dot attached to the map.
7. My Location centers the current dot.
8. Existing markers and route navigation still work.

Wi-Fi is not required for receiving the phone's GNSS/GPS position.
