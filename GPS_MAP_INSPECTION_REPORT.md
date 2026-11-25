# UCU SMART+ Map and GPS Inspection Report

Inspection only. No map, marker, GPS, navigation, route, or UI files were modified.

## A. Map Image

The active map image is:

`assets/images/ucu_campus_map.png`

It is declared in [pubspec.yaml](pubspec.yaml) and loaded by the active Campus Map screen in [lib/main.dart](lib/main.dart).

## B. Map Dimensions

- Resolution: **1412 x 1114 pixels**
- Aspect ratio: approximately **1.268**

## C-D. Coordinate System and Marker Format

The active implementation stores marker coordinates as percentages of the map container:

- `x`: percentage from left to right
- `y`: percentage from top to bottom
- `(0, 0)`: top-left
- `(100, 100)`: bottom-right

Marker positions are calculated as:

```dart
left = mapWidth * location.x / 100 - 15;
top = mapHeight * location.y / 100 - 15;
```

The subtraction centers the approximately 30-pixel marker on its coordinate.

The map image and markers are children of the same `Stack`, inside the same `InteractiveViewer`.

## Active Campus Map Screen

The active startup path is:

```text
main()
  -> SplashScreen
  -> CampusMapPage in lib/main.dart
```

The separate `lib/screens/campus_map.dart` implementation is not wired into the current startup path.

The active `InteractiveViewer` uses:

- Minimum scale: `0.6`
- Maximum scale: `4.0`
- Boundary margin: `500`
- `constrained: false`

The map is resized according to available screen dimensions. The image uses `BoxFit.fill`, so the displayed map can be stretched relative to the original image dimensions.

## E. Active Marker Coordinates

Coordinates below are percentages: `(x%, y%)`.

| # | Location | X% | Y% |
|---:|---|---:|---:|
| 1 | Dr. Leoncio Ancheta Bldg. 1 | 53.0 | 22.0 |
| 2 | Dr. Leoncio Ancheta Bldg. 2 | 67.0 | 27.0 |
| 3 | Dr. Solidad F. Caringal Bldg. | 63.5 | 32.0 |
| 4 | Nursing Bldg. 1 | 56.0 | 32.5 |
| 5 | Resorts World | 60.0 | 38.5 |
| 6 | Badar Building | 82.0 | 43.0 |
| 7 | Honasan Hall | 77.0 | 49.5 |
| 8 | Nursing Bldg. 2 | 62.0 | 50.5 |
| 9 | Dr. Teofidez E. Calvero | 46.0 | 47.0 |
| 10 | Dr. Pedro T. Orata Bldg. 1 | 31.0 | 34.0 |
| 11 | Julio E. Parayno Bldg. | 27.5 | 37.0 |
| 12 | Dr. Pedro T. Orata Bldg. 2 | 26.0 | 24.0 |
| 13 | Gymnasium | 49.0 | 81.0 |
| 14 | Mini Gymnasium | 44.0 | 92.0 |
| 15 | P.E. Office | 38.0 | 87.0 |
| 16 | Fitness Gym. 2 | 48.3 | 90.3 |
| 17 | Fitness Gym. 1 | 40.0 | 79.0 |
| 18 | Wellness Spa | 40.0 | 76.0 |
| 19 | E.M.A.S. | 37.0 | 74.0 |
| 20 | Green Home | 38.0 | 76.5 |
| 21 | Generator Set | 32.0 | 53.0 |
| 22 | Animal Clinic | 30.0 | 49.0 |
| 23 | University Clinic | 44.0 | 53.0 |
| 24 | Mock Hotel | 41.0 | 40.0 |
| 25 | Audio Visual Room | 80.0 | 36.0 |
| 26 | Dr. Orata Park | 85.0 | 35.0 |
| 27 | Quadrangle | 72.0 | 43.0 |
| 28 | Square Garden | 56.0 | 45.0 |
| 29 | NDRRMO | 50.0 | 32.0 |
| 30 | Airplane Bldg. | 40.0 | 20.0 |
| 31 | Turnstile | 34.0 | 13.0 |
| 32 | Entrep. & Law Bldg. | 34.0 | 7.5 |
| 33 | Sewer Treatment Plant | 40.0 | 34.5 |
| 34 | Toilet | 40.0 | 93.8 |
| 35 | Parking | 19.0 | 29.0 |

There is a numbering issue in the active table: `Fitness Gym. 2` is assigned number `1` instead of `16`.

## F. GPS Reference Point Matches

| GPS point | Existing marker match |
|---|---|
| Point 1 - Main Gate | No exact `Main Gate` marker exists. `Turnstile` is semantically related but cannot be confirmed as the same point. |
| Point 2 - Gymnasium | #13 Gymnasium at `(49.0%, 81.0%)` |
| Point 3 - University Clinic | #23 University Clinic at `(44.0%, 53.0%)` |
| Point 4 - Dr. Leoncio | Ambiguous: #1 Dr. Leoncio Ancheta Bldg. 1 at `(53.0%, 22.0%)`, or #2 Bldg. 2 at `(67.0%, 27.0%)` |
| Point 5 - Reference Point #5 | No corresponding named marker exists. |

## G. Can Existing Coordinates Be Reused?

Yes, the active percentage coordinates can be reused as the target map coordinate system for GPS calibration.

However, the five readings are not yet sufficient for reliable calibration because:

- Main Gate has no confirmed map marker.
- Reference Point #5 has no map marker.
- Dr. Leoncio is ambiguous between two existing markers.
- Existing marker accuracy is not documented.
- The active map is resized and rendered with `BoxFit.fill`.

For original-image pixel coordinates, a percentage coordinate would correspond to:

```text
pixelX = xPercent / 100 * 1412
pixelY = yPercent / 100 * 1114
```

## H. Information Still Missing

Before implementing GPS-to-map conversion, the following information is needed:

1. Confirmed map coordinates for Main Gate and Reference Point #5.
2. Confirmation whether GPS Point 4 represents Building 1 or Building 2.
3. Confirmation whether each GPS point represents a building center, entrance, gate, or another physical reference.
4. More reliable GPS-to-map correspondences, preferably 3 to 5 well-distributed control points.
5. A selected transformation model, such as affine or projective calibration.
6. Confirmation that the marker table in `lib/main.dart` is authoritative.

## Additional Repository Finding

There is an inactive alternative implementation in [lib/screens/campus_map.dart](lib/screens/campus_map.dart) that uses normalized coordinates from `0.0` to `1.0` and contains different marker values. There is also different marker data in [lib/data/campus_locations.dart](lib/data/campus_locations.dart). Neither is used by the current application startup path.

## GPS Conversion Status

GPS-to-map conversion is currently disabled. [lib/services/coordinate_converter.dart](lib/services/coordinate_converter.dart) returns `null` and reports `isAvailable == false` until real calibration data is provided.
