import '../services/student_api_service.dart';

class StudentDashboardData {
  const StudentDashboardData({
    this.totalBuildings,
    this.totalRooms,
    this.availableRooms,
    this.occupiedRooms,
    this.unavailableRooms,
  });

  final int? totalBuildings;
  final int? totalRooms;
  final int? availableRooms;
  final int? occupiedRooms;
  final int? unavailableRooms;

  factory StudentDashboardData.fromJson(Object? value) {
    final map = _payloadMap(
      value,
      const ['dashboard', 'summary', 'statistics', 'data'],
    );
    final availability = _optionalMap(
      map['availability'] ?? map['room_availability'],
    );
    return StudentDashboardData(
      totalBuildings: _optionalInt(
        _first(map, const [
          'total_buildings',
          'buildings_count',
          'building_count',
        ]),
      ),
      totalRooms: _optionalInt(
        _first(map, const ['total_rooms', 'rooms_count', 'room_count']),
      ),
      availableRooms: _optionalInt(
        _first(availability ?? map, const [
          'available_rooms',
          'available',
          'available_count',
        ]),
      ),
      occupiedRooms: _optionalInt(
        _first(availability ?? map, const [
          'occupied_rooms',
          'occupied',
          'occupied_count',
        ]),
      ),
      unavailableRooms: _optionalInt(
        _first(availability ?? map, const [
          'unavailable_rooms',
          'unavailable',
          'unavailable_count',
        ]),
      ),
    );
  }
}

class StudentBuilding {
  const StudentBuilding({
    required this.id,
    required this.code,
    required this.name,
    this.roomCount,
    this.description,
    this.imageUrl,
  });

  final int id;
  final String code;
  final String name;
  final int? roomCount;
  final String? description;
  final String? imageUrl;

  factory StudentBuilding.fromJson(Object? value) {
    final map = _payloadMap(value, const ['building', 'data']);
    final id = _optionalInt(map['id']);
    final code = _optionalString(
      _first(map, const ['code', 'building_code']),
    );
    final name = _optionalString(_first(map, const ['name', 'building_name']));
    if (id == null || code == null || name == null) {
      throw const StudentApiException(
        'The server returned an invalid building record.',
      );
    }

    return StudentBuilding(
      id: id,
      code: code,
      name: name,
      roomCount: _optionalInt(
        _first(map, const ['rooms_count', 'room_count', 'total_rooms']),
      ),
      description: _optionalString(map['description']),
      imageUrl: _optionalString(_first(map, const ['image_url', 'image'])),
    );
  }
}

class StudentRoom {
  const StudentRoom({
    required this.id,
    required this.roomNumber,
    required this.name,
    this.floor,
    this.capacity,
    this.availability,
    this.currentSchedule,
    this.building,
  });

  final int id;
  final String roomNumber;
  final String name;
  final String? floor;
  final int? capacity;
  final String? availability;
  final StudentRoomSchedule? currentSchedule;
  final StudentBuilding? building;

  bool get isAvailable {
    final value = availability?.trim().toLowerCase();
    return value == 'available' || value == 'vacant';
  }

  factory StudentRoom.fromJson(
    Object? value, {
    StudentBuilding? fallbackBuilding,
  }) {
    final map = _payloadMap(value, const ['room', 'data']);
    final id = _optionalInt(map['id']);
    final number = _optionalString(
      _first(map, const ['room_number', 'room_no', 'number']),
    );
    if (id == null || number == null) {
      throw const StudentApiException(
        'The server returned an invalid room record.',
      );
    }

    final buildingMap = _optionalMap(map['building']);
    StudentBuilding? building = fallbackBuilding;
    if (buildingMap != null && buildingMap['id'] != null) {
      building = StudentBuilding.fromJson(buildingMap);
    }
    return StudentRoom(
      id: id,
      roomNumber: number,
      name: _optionalString(_first(map, const ['name', 'room_name'])) ?? number,
      floor: _displayString(_first(map, const ['floor', 'floor_name'])),
      capacity: _optionalInt(map['capacity']),
      availability: _availabilityString(map),
      currentSchedule: _roomSchedule(map['availability']),
      building: building,
    );
  }
}

String? _availabilityString(Map<String, dynamic> room) {
  final availability = _optionalMap(room['availability']);
  final nestedStatus = availability?['status'];
  if (nestedStatus is String && nestedStatus.trim().isNotEmpty) {
    return nestedStatus.trim();
  }

  final value = _first(
    room,
    const ['availability_status', 'status', 'availability'],
  );
  if (value is Map<String, dynamic>) return null;
  if (value is bool) return value ? 'available' : 'unavailable';
  if (value is String && value.trim().isNotEmpty) return value.trim();
  final available = room['is_available'];
  if (available is bool) return available ? 'available' : 'unavailable';
  return null;
}

StudentRoomSchedule? _roomSchedule(Object? availabilityValue) {
  final availability = _optionalMap(availabilityValue);
  final schedule = _optionalMap(availability?['current_schedule']);
  if (schedule == null) return null;

  return StudentRoomSchedule(
    subjectCode: _optionalString(schedule['subject_code']),
    subjectName: _optionalString(schedule['subject_name']),
    day: _optionalString(schedule['day']),
    startTime: _optionalString(schedule['start_time']),
    endTime: _optionalString(schedule['end_time']),
    instructorName: _optionalString(schedule['instructor_name']),
  );
}

class StudentRoomSchedule {
  const StudentRoomSchedule({
    this.subjectCode,
    this.subjectName,
    this.day,
    this.startTime,
    this.endTime,
    this.instructorName,
  });

  final String? subjectCode;
  final String? subjectName;
  final String? day;
  final String? startTime;
  final String? endTime;
  final String? instructorName;
}

Map<String, dynamic> _payloadMap(Object? value, List<String> wrappers) {
  if (value is! Map<String, dynamic>) {
    throw const StudentApiException('The server returned invalid data.');
  }
  var current = value;
  for (var depth = 0; depth < wrappers.length; depth++) {
    var changed = false;
    for (final wrapper in wrappers) {
      final nested = current[wrapper];
      if (nested is Map<String, dynamic>) {
        current = nested;
        changed = true;
        break;
      }
    }
    if (!changed) break;
  }
  return current;
}

Map<String, dynamic>? _optionalMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;

Object? _first(Map<String, dynamic> value, List<String> keys) {
  for (final key in keys) {
    if (value.containsKey(key)) return value[key];
  }
  return null;
}

int? _optionalInt(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  if (value is String) return int.tryParse(value);
  return null;
}

String? _optionalString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

String? _displayString(Object? value) {
  if (value is num) return value.toString();
  return _optionalString(value);
}
