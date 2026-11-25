import 'package:flutter_test/flutter_test.dart';
import 'package:ucu_smart_plus/models/student_portal_models.dart';
import 'package:ucu_smart_plus/services/student_api_service.dart';

void main() {
  test('parses dashboard summary without inventing omitted counts', () {
    final dashboard = StudentDashboardData.fromJson({
      'data': {
        'total_buildings': 8,
        'total_rooms': '64',
        'room_availability': {
          'available_rooms': 11,
          'occupied_rooms': 42,
          'unavailable_rooms': 11,
        },
      },
    });

    expect(dashboard.totalBuildings, 8);
    expect(dashboard.totalRooms, 64);
    expect(dashboard.availableRooms, 11);
    expect(dashboard.occupiedRooms, 42);
    expect(dashboard.unavailableRooms, 11);
    expect(
      StudentDashboardData.fromJson(<String, dynamic>{}).totalRooms,
      isNull,
    );
  });

  test('parses buildings and room totals from Laravel response fields', () {
    final building = StudentBuilding.fromJson({
      'data': {
        'id': 7,
        'building_code': 'SCI',
        'building_name': 'Science Building',
        'rooms_count': 12,
      },
    });

    expect(building.id, 7);
    expect(building.code, 'SCI');
    expect(building.name, 'Science Building');
    expect(building.roomCount, 12);
  });

  test('parses Laravel room detail fields and nested availability', () {
    final room = StudentRoom.fromJson({
      'data': {
        'id': '91',
        'room_number': 'BB - 202',
        'room_name': 'BB - 202',
        'floor': 2,
        'capacity': 0,
        'building': {
          'id': 4,
          'building_code': 'B04',
          'building_name': 'BADAR BUILDING',
          'room_count': 8,
        },
        'availability': {
          'status': 'available',
          'checked_at': '2026-11-03T01:45:26+08:00',
          'current_schedule': null,
        },
      },
    });

    expect(room.id, 91);
    expect(room.roomNumber, 'BB - 202');
    expect(room.name, 'BB - 202');
    expect(room.floor, '2');
    expect(room.capacity, 0);
    expect(room.availability, 'available');
    expect(room.isAvailable, isTrue);
    expect(room.currentSchedule, isNull);
    expect(room.building?.name, 'BADAR BUILDING');
  });

  test('parses occupied schedule details from Laravel availability data', () {
    final room = StudentRoom.fromJson({
      'data': {
        'id': 12,
        'room_number': 'BB - 202',
        'floor': 2,
        'capacity': 0,
        'availability': {
          'status': 'occupied',
          'current_schedule': {
            'subject_code': 'IT-201',
            'subject_name': 'Systems Analysis',
            'day': 'Tuesday',
            'start_time': '01:00:00',
            'end_time': '02:00:00',
            'instructor_name': 'Instructor Example',
          },
        },
      },
    });

    expect(room.availability, 'occupied');
    expect(room.isAvailable, isFalse);
    expect(room.currentSchedule?.subjectName, 'Systems Analysis');
    expect(room.currentSchedule?.instructorName, 'Instructor Example');
  });

  test('uses the supplied building when a room response omits it', () {
    const building = StudentBuilding(
      id: 3,
      code: 'LIB',
      name: 'Library',
    );
    final room = StudentRoom.fromJson(
      const {
        'id': 1,
        'room_number': 'L-1',
      },
      fallbackBuilding: building,
    );

    expect(room.building, same(building));
    expect(room.name, 'L-1');
    expect(room.availability, isNull);
  });

  test('rejects malformed building and room payloads', () {
    expect(
      () => StudentBuilding.fromJson(const {'id': 1, 'name': 'No code'}),
      throwsA(isA<StudentApiException>()),
    );
    expect(
      () => StudentRoom.fromJson(const {'id': 1}),
      throwsA(isA<StudentApiException>()),
    );
  });
}
