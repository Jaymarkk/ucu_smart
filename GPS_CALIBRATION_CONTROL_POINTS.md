# GPS Calibration Inspection Report

## Scope

Inspection and calibration preparation only. No Dart files, marker coordinates, GPS conversion logic, GPS markers, map assets, or UI were modified.

Active map: `assets/images/ucu_campus_map.png`

Image resolution: **1412 x 1114 pixels**

Coordinate origin: `(0, 0)` is the top-left; `(100%, 100%)` is the bottom-right.

## Percentage-to-Pixel Conversions

Formula:

```text
pixelX = xPercent / 100 * 1412
pixelY = yPercent / 100 * 1114
```

| Location | Map percentage | Pixel coordinate |
|---|---:|---:|
| Gymnasium | `(49%, 81%)` | `(692, 902)` |
| University Clinic | `(44%, 53%)` | `(621, 590)` |
| Dr. Leoncio Ancheta Bldg. 1 | `(53%, 22%)` | `(748, 245)` |
| Dr. Leoncio Ancheta Bldg. 2 | `(67%, 27%)` | `(946, 301)` |
| Turnstile | `(34%, 13%)` | `(480, 145)` |

Values are rounded to the nearest pixel.

## Visual Comparison

- **Gymnasium `(692, 902)`** lands within the large lower-campus building area and is visually plausible as the gymnasium.
- **University Clinic `(621, 590)`** lands in the central building cluster, but the unlabeled image does not prove the exact building or entrance.
- **Dr. Leoncio Bldg. 1 `(748, 245)`** and **Bldg. 2 `(946, 301)`** land in distinct upper-campus building areas. The image itself does not label them.
- **Turnstile `(480, 145)`** lands near an upper access/road area and is visually plausible.
- **Main Gate** cannot be selected confidently because multiple road/access edges are visible and none is labeled.
- **Reference Point #5** cannot be identified from the map.

GPS coordinates cannot yet be converted into map percentages because no verified GPS-to-map correspondence exists for Main Gate or Point #5, and the Dr. Leoncio reading is ambiguous between two buildings.

## GPS CALIBRATION CONTROL POINTS

| GPS Point | Location | Latitude | Longitude | Accuracy | Map X pixel | Map Y pixel | Map X % | Map Y % | Reference type |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | Main Gate | 15.981357 | 120.560273 | 13.0 m | **UNKNOWN** | **UNKNOWN** | **UNKNOWN** | **UNKNOWN** | gate |
| 2 | Gymnasium | 15.980468 | 120.560556 | 21.6 m | **692** | **902** | **49%** | **81%** | building entrance, exact entrance unverified |
| 3 | University Clinic | 15.980168 | 120.560537 | 15.9 m | **621** | **590** | **44%** | **53%** | building entrance, exact entrance unverified |
| 4 | Dr. Leoncio | 15.980414 | 120.561446 | 16.3 m | **748 or 946** | **245 or 301** | **53% or 67%** | **22% or 27%** | **AMBIGUOUS — needs confirmation** |
| 5 | Reference Point #5 | 15.979941 | 120.561352 | 11.6 m | **UNKNOWN** | **UNKNOWN** | **UNKNOWN** | **UNKNOWN** | **UNKNOWN — needs manual identification** |

## Missing Information

- **Main Gate:** The actual gate or entrance location on the image must be manually identified, preferably with a pixel click or clearly marked map reference.
- **Point #5:** **UNKNOWN — needs manual identification**. No reliable visual identity is available from the current image.
- **Dr. Leoncio:** **AMBIGUOUS — needs confirmation**. Confirm whether the GPS reading corresponds to Building 1 or Building 2, and whether the reading was taken at the center, entrance, or nearby road.
