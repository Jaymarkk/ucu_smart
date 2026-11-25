import 'package:flutter/material.dart';
import '../widgets/numbered_map_marker.dart';

class CampusLocation {
  final int number;
  final String name;
  final double x;
  final double y;

  const CampusLocation({
    required this.number,
    required this.name,
    required this.x,
    required this.y,
  });
}

class CampusMap extends StatefulWidget {
  const CampusMap({super.key});

  @override
  State<CampusMap> createState() => _CampusMapState();
}

class _CampusMapState extends State<CampusMap> {
  final TransformationController _transformationController =
      TransformationController();

  // ============================================================
  // MARKER SIZE
  // ============================================================

  static const double markerSize = 18.0;

  // ============================================================
  // CAMPUS LOCATIONS
  //
  // x = horizontal position
  // y = vertical position
  //
  // Both are normalized:
  // 0.0 = left/top
  // 1.0 = right/bottom
  // ============================================================

  final List<CampusLocation> locations = const [
    // ------------------------------------------------------------
    // 1
    // ------------------------------------------------------------

    CampusLocation(
      number: 1,
      name: 'Dr. Leoncio Ancheta Bldg. 1',
      x: 0.515,
      y: 0.205,
    ),

    // ------------------------------------------------------------
    // 2
    // ------------------------------------------------------------

    CampusLocation(
      number: 2,
      name: 'Dr. Leoncio Ancheta Bldg. 2',
      x: 0.655,
      y: 0.255,
    ),

    // ------------------------------------------------------------
    // 3
    // ------------------------------------------------------------

    CampusLocation(
      number: 3,
      name: 'Dr. Solidad F. Caringal Bldg.',
      x: 0.608,
      y: 0.295,
    ),

    // ------------------------------------------------------------
    // 4
    // ------------------------------------------------------------

    CampusLocation(
      number: 4,
      name: 'Nursing Bldg. 1',
      x: 0.535,
      y: 0.295,
    ),

    // ------------------------------------------------------------
    // 5
    // ------------------------------------------------------------

    CampusLocation(
      number: 5,
      name: 'Resorts World',
      x: 0.566,
      y: 0.355,
    ),

    // ------------------------------------------------------------
    // 6
    // ------------------------------------------------------------

    CampusLocation(
      number: 6,
      name: 'Badar Building',
      x: 0.786,
      y: 0.405,
    ),

    // ------------------------------------------------------------
    // 7
    // ------------------------------------------------------------

    CampusLocation(
      number: 7,
      name: 'Honasan Hall',
      x: 0.745,
      y: 0.472,
    ),

    // ------------------------------------------------------------
    // 8
    // ------------------------------------------------------------

    CampusLocation(
      number: 8,
      name: 'Nursing Bldg. 2',
      x: 0.850,
      y: 0.510,
    ),

    // ------------------------------------------------------------
    // 9
    // ------------------------------------------------------------

    CampusLocation(
      number: 9,
      name: 'Dr. Teofidez E. Calvero',
      x: 0.435,
      y: 0.450,
    ),

    // ------------------------------------------------------------
    // 10
    // ------------------------------------------------------------

    CampusLocation(
      number: 10,
      name: 'Dr. Pedro T. Orata Bldg. 1',
      x: 0.297,
      y: 0.335,
    ),

    // ------------------------------------------------------------
    // 11
    // ------------------------------------------------------------

    CampusLocation(
      number: 11,
      name: 'Julio E. Parayno Bldg.',
      x: 0.262,
      y: 0.365,
    ),

    // ------------------------------------------------------------
    // 12
    // ------------------------------------------------------------

    CampusLocation(
      number: 12,
      name: 'Dr. Pedro T. Orata Bldg. 2',
      x: 0.325,
      y: 0.590,
    ),

    // ------------------------------------------------------------
    // 13
    // ------------------------------------------------------------

    CampusLocation(
      number: 13,
      name: 'Gymnasium',
      x: 0.457,
      y: 0.770,
    ),

    // ------------------------------------------------------------
    // 14
    // ------------------------------------------------------------

    CampusLocation(
      number: 14,
      name: 'Mini Gymnasium',
      x: 0.418,
      y: 0.885,
    ),

    // ------------------------------------------------------------
    // 15
    // ------------------------------------------------------------

    CampusLocation(
      number: 15,
      name: 'P.E. Office',
      x: 0.358,
      y: 0.825,
    ),

    // ------------------------------------------------------------
    // 16
    // ------------------------------------------------------------

    CampusLocation(
      number: 16,
      name: 'Fitness Gym. 2',
      x: 0.458,
      y: 0.862,
    ),

    // ------------------------------------------------------------
    // 17
    // ------------------------------------------------------------

    CampusLocation(
      number: 17,
      name: 'Fitness Gym. 1',
      x: 0.376,
      y: 0.753,
    ),

    // ------------------------------------------------------------
    // 18
    // ------------------------------------------------------------

    CampusLocation(
      number: 18,
      name: 'Wellness Spa',
      x: 0.376,
      y: 0.716,
    ),

    // ------------------------------------------------------------
    // 19
    // ------------------------------------------------------------

    CampusLocation(
      number: 19,
      name: 'E.M.A.S.',
      x: 0.346,
      y: 0.705,
    ),

    // ------------------------------------------------------------
    // 20
    // ------------------------------------------------------------

    CampusLocation(
      number: 20,
      name: 'Green Home',
      x: 0.346,
      y: 0.735,
    ),

    // ------------------------------------------------------------
    // 21
    // ------------------------------------------------------------

    CampusLocation(
      number: 21,
      name: 'Generator Set',
      x: 0.305,
      y: 0.507,
    ),

    // ------------------------------------------------------------
    // 22
    // ------------------------------------------------------------

    CampusLocation(
      number: 22,
      name: 'Animal Clinic',
      x: 0.278,
      y: 0.465,
    ),

    // ------------------------------------------------------------
    // 23
    // ------------------------------------------------------------

    CampusLocation(
      number: 23,
      name: 'University Clinic',
      x: 0.417,
      y: 0.505,
    ),

    // ------------------------------------------------------------
    // 24
    // ------------------------------------------------------------

    CampusLocation(
      number: 24,
      name: 'Mock Hotel',
      x: 0.535,
      y: 0.790,
    ),

    // ------------------------------------------------------------
    // 25
    // ------------------------------------------------------------

    CampusLocation(
      number: 25,
      name: 'Audio Visual Room',
      x: 0.765,
      y: 0.340,
    ),

    // ------------------------------------------------------------
    // 26
    // ------------------------------------------------------------

    CampusLocation(
      number: 26,
      name: 'Dr. Orata Park',
      x: 0.815,
      y: 0.330,
    ),

    // ------------------------------------------------------------
    // 27
    // ------------------------------------------------------------

    CampusLocation(
      number: 27,
      name: 'Quadrangle',
      x: 0.690,
      y: 0.405,
    ),

    // ------------------------------------------------------------
    // 28
    // ------------------------------------------------------------

    CampusLocation(
      number: 28,
      name: 'Square Garden',
      x: 0.185,
      y: 0.235,
    ),

    // ------------------------------------------------------------
    // 29
    // ------------------------------------------------------------

    CampusLocation(
      number: 29,
      name: 'NDRRMO',
      x: 0.474,
      y: 0.275,
    ),

    // ------------------------------------------------------------
    // 30
    // ------------------------------------------------------------

    CampusLocation(
      number: 30,
      name: 'Airplane Bldg.',
      x: 0.386,
      y: 0.178,
    ),

    // ------------------------------------------------------------
    // 31
    // ------------------------------------------------------------

    CampusLocation(
      number: 31,
      name: 'Turnstile',
      x: 0.317,
      y: 0.100,
    ),

    // ------------------------------------------------------------
    // 32
    // ------------------------------------------------------------

    CampusLocation(
      number: 32,
      name: 'Entrep. & Law Bldg.',
      x: 0.325,
      y: 2.080,
    ),

    // ------------------------------------------------------------
    // 33
    // ------------------------------------------------------------

    CampusLocation(
      number: 33,
      name: 'Sewer Treatment Plant',
      x: 0.385,
      y: 0.330,
    ),

    // ------------------------------------------------------------
    // 34
    // ------------------------------------------------------------

    CampusLocation(
      number: 34,
      name: 'Toilet',
      x: 0.430,
      y: 0.575,
    ),

    // ------------------------------------------------------------
    // 35
    // ------------------------------------------------------------

    CampusLocation(
      number: 35,
      name: 'Parking',
      x: 0.175,
      y: 0.270,
    ),
  ];

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // ============================================================
  // RESET MAP
  // ============================================================

  void _resetMap() {
    _transformationController.value = Matrix4.identity();
  }

  // ============================================================
  // SHOW LOCATION DETAILS
  // ============================================================

  void _showLocation(CampusLocation location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  children: [
                    // NUMBER
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0E2958),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${location.number}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // NAME
                    Expanded(
                      child: Text(
                        location.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0E2958),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'Campus Location',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Building / Facility #${location.number}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // CLOSE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E2958),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2958),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.school),
            SizedBox(width: 10),
            Text(
              'UCU Smart Plus',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // SEARCH
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search feature can be added here.
            },
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: Stack(
        children: [
          // ======================================================
          // INTERACTIVE MAP
          // ======================================================

          Positioned.fill(
            child: AspectRatio(
              aspectRatio: 1412 / 1114,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 5.0,
                boundaryMargin: const EdgeInsets.all(300),
                panEnabled: true,
                scaleEnabled: true,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final mapWidth = constraints.maxWidth;
                    final mapHeight = constraints.maxHeight;

                    return SizedBox(
                      width: mapWidth,
                      height: mapHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ==================================================
                          // CAMPUS MAP IMAGE
                          // ==================================================

                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/ucu_campus_map.png',
                              width: mapWidth,
                              height: mapHeight,
                              fit: BoxFit.contain,
                            ),
                          ),

                          // ==================================================
                          // NUMBERED MARKERS
                          // ==================================================

                          ...locations.map(
                            (location) {
                              // Convert normalized coordinate
                              // into actual pixel position.

                              final double left = location.x * mapWidth;

                              final double top = location.y * mapHeight;

                              // Center marker exactly on coordinate.

                              return Positioned(
                                left: left - (markerSize / 2),
                                top: top - (markerSize / 2),
                                child: NumberedMapMarker(
                                  number: location.number,
                                  name: location.name,
                                  onTap: () {
                                    _showLocation(location);
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ========================================================
          // MAP LABEL
          // ========================================================

          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.map,
                    color: Color(0xFF0E2958),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'UCU Campus Map',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========================================================
          // MAP CONTROLS
          // ========================================================

          Positioned(
            right: 20,
            bottom: 30,
            child: Column(
              children: [
                // ZOOM IN
                _mapButton(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                ),

                const SizedBox(height: 10),

                // ZOOM OUT
                _mapButton(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                ),

                const SizedBox(height: 10),

                // RESET
                _mapButton(
                  icon: Icons.center_focus_strong,
                  onPressed: _resetMap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP BUTTON
  // ============================================================

  Widget _mapButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(
            icon,
            color: const Color(0xFF0E2958),
            size: 26,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ZOOM IN
  // ============================================================

  void _zoomIn() {
    final current = _transformationController.value;

    final scale = current.getMaxScaleOnAxis();

    if (scale >= 5.0) {
      return;
    }

    _transformationController.value = current.scaledByDouble(
      1.25,
      1.25,
      1.0,
      1.0,
    );
  }

  // ============================================================
  // ZOOM OUT
  // ============================================================

  void _zoomOut() {
    final current = _transformationController.value;

    final scale = current.getMaxScaleOnAxis();

    if (scale <= 0.5) {
      return;
    }

    _transformationController.value = current.scaledByDouble(
      0.8,
      0.8,
      1.0,
      1.0,
    );
  }
}
