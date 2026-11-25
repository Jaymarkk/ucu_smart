import 'dart:async';

import 'package:flutter/material.dart';

import '../models/student_portal_models.dart';
import '../services/student_api_service.dart';
import '../services/student_auth_service.dart';
import '../widgets/student_portal_components.dart';
import 'student_building_details_screen.dart';

class StudentRoomAvailabilityScreen extends StatefulWidget {
  const StudentRoomAvailabilityScreen({
    super.key,
    required this.authService,
    required this.api,
  });

  final StudentAuthService authService;
  final StudentApiService api;

  @override
  State<StudentRoomAvailabilityScreen> createState() =>
      _StudentRoomAvailabilityScreenState();
}

class _StudentRoomAvailabilityScreenState
    extends State<StudentRoomAvailabilityScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<StudentBuilding> _buildings = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBuildings());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    final token = widget.authService.verifiedStudentToken;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Your Student session is unavailable. Please sign in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final buildings = await widget.api.fetchBuildings(token);
      if (!mounted) return;
      setState(() {
        _buildings = buildings;
        _isLoading = false;
      });
    } on StudentApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    }
  }

  List<StudentBuilding> get _filteredBuildings {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _buildings;
    return _buildings
        .where(
          (building) =>
              building.code.toLowerCase().contains(query) ||
              building.name.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) => StudentPortalScaffold(
        authService: widget.authService,
        title: 'Room Availability',
        actions: [
          IconButton(
            tooltip: 'Refresh buildings',
            onPressed: _isLoading ? null : _loadBuildings,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 620
                    ? 2
                    : 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Room Availability',
                            style: TextStyle(
                              color: studentNavy,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Browse campus buildings, then select a room to check availability.',
                            style: TextStyle(color: studentMuted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: const Color(0xFFE2E5E9)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search building name or code',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2EAF3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2EAF3)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StudentLoadState(
                    isLoading: _isLoading,
                    error: _error,
                    onRetry: _loadBuildings,
                    loadingLabel: 'Loading campus buildings…',
                    child: _buildings.isEmpty
                        ? const StudentEmptyState(
                            title: 'No buildings available',
                            message:
                                'There are no buildings available to browse right now.',
                            icon: Icons.apartment_outlined,
                          )
                        : _filteredBuildings.isEmpty
                            ? const StudentEmptyState(
                                title: 'No matching buildings',
                                message:
                                    'Try another building name or building code.',
                                icon: Icons.search_off_rounded,
                              )
                            : RefreshIndicator(
                                onRefresh: _loadBuildings,
                                child: GridView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 4, 18, 24),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    mainAxisExtent: 338,
                                  ),
                                  itemCount: _filteredBuildings.length,
                                  itemBuilder: (context, index) {
                                    final building =
                                        _filteredBuildings[index];
                                    return _BuildingAvailabilityCard(
                                      building: building,
                                      onTap: () => _openBuilding(building),
                                    );
                                  },
                                ),
                              ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  void _openBuilding(StudentBuilding building) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: '/student/buildings/${building.id}/rooms',
        ),
        builder: (_) => StudentBuildingDetailsScreen(
          authService: widget.authService,
          api: widget.api,
          building: building,
        ),
      ),
    );
  }
}

class _BuildingAvailabilityCard extends StatelessWidget {
  const _BuildingAvailabilityCard({
    required this.building,
    required this.onTap,
  });

  final StudentBuilding building;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E5E9)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 154,
                child: building.imageUrl == null
                    ? const _BuildingImagePlaceholder()
                    : Image.network(
                        building.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _BuildingImagePlaceholder(),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        building.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: studentNavy,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Expanded(
                        child: Text(
                          building.description?.isNotEmpty == true
                              ? building.description!
                              : 'No description available.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: studentMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              building.roomCount == null
                                  ? 'Room count not provided'
                                  : '${building.roomCount} '
                                      '${building.roomCount == 1 ? 'room' : 'rooms'}',
                              style: const TextStyle(
                                color: studentMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Text(
                            'View rooms',
                            style: TextStyle(
                              color: Color(0xFF0E4C6B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Color(0xFF0E4C6B),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BuildingImagePlaceholder extends StatelessWidget {
  const _BuildingImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF1F3F6),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment_rounded,
              size: 40,
              color: Color(0xFFB8C2CE),
            ),
            SizedBox(height: 7),
            Text(
              'No image available',
              style: TextStyle(color: studentMuted, fontSize: 12),
            ),
          ],
        ),
      );
}
