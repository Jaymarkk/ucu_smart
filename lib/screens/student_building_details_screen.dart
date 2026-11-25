import'dart:async';

import 'package:flutter/material.dart';

import '../models/student_portal_models.dart';
import '../services/student_api_service.dart';
import '../services/student_auth_service.dart';
import '../widgets/student_portal_components.dart';

class StudentBuildingDetailsScreen extends StatefulWidget {
  const StudentBuildingDetailsScreen({
    super.key,
    required this.authService,
    required this.api,
    required this.building,
  });

  final StudentAuthService authService;
  final StudentApiService api;
  final StudentBuilding building;

  @override
  State<StudentBuildingDetailsScreen> createState() =>
      _StudentBuildingDetailsScreenState();
}

class _StudentBuildingDetailsScreenState
    extends State<StudentBuildingDetailsScreen> {
  List<StudentRoom> _rooms = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRooms());
  }

  Future<void> _loadRooms() async {
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
      final rooms = await widget.api.fetchBuildingRooms(
        token,
        widget.building,
      );
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
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

  @override
  Widget build(BuildContext context) => StudentPortalScaffold(
        authService: widget.authService,
        title: widget.building.name,
        actions: [
          IconButton(
            tooltip: 'Refresh rooms',
            onPressed: _isLoading ? null : _loadRooms,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        child: StudentLoadState(
          isLoading: _isLoading,
          error: _error,
          onRetry: _loadRooms,
          loadingLabel: 'Loading rooms…',
          child: _rooms.isEmpty
              ? const StudentEmptyState(
                  title: 'No rooms listed',
                  message: 'No rooms are currently listed for this building.',
                  icon: Icons.meeting_room_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      _BuildingHeader(building: widget.building),
                      const SizedBox(height: 24),
                      const StudentSectionHeader(title: 'Rooms'),
                      const SizedBox(height: 12),
                      ..._rooms.map(
                        (room) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RoomAvailabilityCard(
                            room: room,
                            onTap: () => _openRoom(room),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );

  void _openRoom(StudentRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/student/rooms/${room.id}'),
        builder: (_) => StudentRoomDetailsScreen(
          authService: widget.authService,
          api: widget.api,
          room: room,
        ),
      ),
    );
  }
}

class _BuildingHeader extends StatelessWidget {
  const _BuildingHeader({required this.building});

  final StudentBuilding building;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              building.name,
              style: const TextStyle(
                color: studentNavy,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a classroom to view its current availability.',
              style: TextStyle(color: studentMuted, height: 1.4),
            ),
          ],
        ),
      );
}

class _RoomAvailabilityCard extends StatelessWidget {
  const _RoomAvailabilityCard({
    required this.room,
    required this.onTap,
  });

  final StudentRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E5E9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0x140E4C6B),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.home_work_outlined,
                      color: Color(0xFF0E4C6B),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.roomNumber,
                          style: const TextStyle(
                            color: studentNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          room.name,
                          style: const TextStyle(
                            color: studentMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _RoomSummaryValue(
                      label: 'Floor',
                      value: room.floor ?? 'Not provided',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoomSummaryValue(
                      label: 'Capacity',
                      value: room.capacity == null
                          ? 'Not provided'
                          : '${room.capacity}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFF0F2F5)),
              const SizedBox(height: 15),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Check availability',
                    style: TextStyle(
                      color: studentMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Color(0xFF0E4C6B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomSummaryValue extends StatelessWidget {
  const _RoomSummaryValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F2F5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: studentMuted, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: studentInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class StudentRoomDetailsScreen extends StatefulWidget {
  const StudentRoomDetailsScreen({
    super.key,
    required this.authService,
    required this.api,
    required this.room,
  });

  final StudentAuthService authService;
  final StudentApiService api;
  final StudentRoom room;

  @override
  State<StudentRoomDetailsScreen> createState() =>
      _StudentRoomDetailsScreenState();
}

class _StudentRoomDetailsScreenState extends State<StudentRoomDetailsScreen> {
  late StudentRoom _room = widget.room;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRoom());
  }

  Future<void> _loadRoom() async {
    final token = widget.authService.verifiedStudentToken;
    if (token == null) {
      setState(() {
        _error = 'Your Student session is unavailable. Please sign in again.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final room = await widget.api.fetchRoom(token, widget.room.id);
      if (!mounted) return;
      setState(() {
        _room = room.building == null && widget.room.building != null
            ? StudentRoom(
                id: room.id,
                roomNumber: room.roomNumber,
                name: room.name,
                floor: room.floor,
                capacity: room.capacity,
                availability: room.availability,
                currentSchedule: room.currentSchedule,
                building: widget.room.building,
              )
            : room;
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

  @override
  Widget build(BuildContext context) => StudentPortalScaffold(
        authService: widget.authService,
        title: 'Room Details',
        actions: [
          IconButton(
            tooltip: 'Refresh room',
            onPressed: _isLoading ? null : _loadRoom,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null) ...[
              _RoomError(message: _error!, onRetry: _loadRoom),
              const SizedBox(height: 14),
            ],
            if (_isLoading) const LinearProgressIndicator(),
            _RoomDetailCard(room: _room),
          ],
        ),
      );
}

class _RoomDetailCard extends StatelessWidget {
  const _RoomDetailCard({required this.room});

  final StudentRoom room;

  @override
  Widget build(BuildContext context) {
    final available = room.isAvailable;
    final normalizedStatus = room.availability?.trim().toLowerCase();
    final status = room.availability == null
        ? 'Not provided'
        : _displayStatus(room.availability!);
    final isOccupied = normalizedStatus == 'occupied';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B0D2B50),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.meeting_room_rounded, color: studentBlue),
          ),
          const SizedBox(height: 18),
          Text(
            room.roomNumber,
            style: const TextStyle(
              color: studentInk,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(room.name, style: const TextStyle(color: studentMuted)),
          const SizedBox(height: 22),
          _CurrentAvailabilityCard(
            status: status,
            available: available,
            message: normalizedStatus == null
                ? 'Availability information is not provided.'
                : available
                    ? 'No class is currently using this room.'
                    : isOccupied
                        ? 'A class is currently using this room.'
                        : 'Availability status: $status.',
            isOccupied: isOccupied,
            schedule: room.currentSchedule,
          ),
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 8),
          StudentInfoRow(
            label: 'Building',
            value: room.building == null ? 'Not provided' : room.building!.name,
            icon: Icons.apartment_outlined,
          ),
          const Divider(height: 1),
          StudentInfoRow(
            label: 'Floor',
            value: room.floor ?? 'Not provided',
            icon: Icons.layers_outlined,
          ),
          const Divider(height: 1),
          StudentInfoRow(
            label: 'Capacity',
            value: room.capacity == null ? 'Not provided' : '${room.capacity}',
            icon: Icons.groups_outlined,
          ),
        ],
      ),
    );
  }

  String _displayStatus(String status) {
    final value = status.replaceAll('_', ' ').trim();
    if (value.isEmpty) return 'Status unavailable';
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _CurrentAvailabilityCard extends StatelessWidget {
  const _CurrentAvailabilityCard({
    required this.status,
    required this.available,
    required this.message,
    required this.isOccupied,
    required this.schedule,
  });

  final String status;
  final bool available;
  final String message;
  final bool isOccupied;
  final StudentRoomSchedule? schedule;

  @override
  Widget build(BuildContext context) {
    final color = available
        ? const Color(0xFF16845B)
        : isOccupied
            ? const Color(0xFFB42318)
            : studentMuted;
    final background = available
        ? const Color(0xFFEFFAF3)
        : isOccupied
            ? const Color(0xFFFFF1F0)
            : const Color(0xFFF8F9FB);
    final border = available
        ? const Color(0xFFC9EBD6)
        : isOccupied
            ? const Color(0xFFFED7D4)
            : const Color(0xFFE2EAF3);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                available
                    ? Icons.check_circle_rounded
                    : isOccupied
                        ? Icons.cancel_rounded
                        : Icons.info_outline_rounded,
                color: color,
                size: 23,
              ),
              const SizedBox(width: 10),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(message, style: TextStyle(color: color, height: 1.4)),
          if (isOccupied && schedule != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (schedule!.subjectName != null)
              _ScheduleDetail(
                label: 'Subject',
                value: schedule!.subjectName!,
                code: schedule!.subjectCode,
              ),
            if (schedule!.instructorName != null)
              _ScheduleDetail(
                label: 'Instructor',
                value: schedule!.instructorName!,
              ),
            if (schedule!.startTime != null && schedule!.endTime != null)
              _ScheduleDetail(
                label: 'Time',
                value: '${schedule!.startTime} – ${schedule!.endTime}',
              ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleDetail extends StatelessWidget {
  const _ScheduleDetail({
    required this.label,
    required this.value,
    this.code,
  });

  final String label;
  final String value;
  final String? code;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF7A271A),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (code != null)
              Text(
                code!,
                style: const TextStyle(
                  color: Color(0xFFB42318),
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );
}

class _RoomError extends StatelessWidget {
  const _RoomError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
