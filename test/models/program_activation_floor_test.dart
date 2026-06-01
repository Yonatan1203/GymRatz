import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/models/program.dart';

Program _program({DateTime? activatedAt, DateTime? createdAt}) => Program(
      id: 'p1',
      name: 'Test',
      workouts: 0,
      weeks: 8,
      activatedAt: activatedAt,
      createdAt: createdAt,
    );

void main() {
  group('Program.activationFloor', () {
    test('uses activatedAt when present, time-truncated', () {
      final p = _program(
        activatedAt: DateTime(2026, 3, 15, 14, 30),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(p.activationFloor, DateTime(2026, 3, 15));
    });

    test('falls back to createdAt when activatedAt is null', () {
      final p = _program(createdAt: DateTime(2026, 1, 10, 9));
      expect(p.activationFloor, DateTime(2026, 1, 10));
    });

    test('is null when both activatedAt and createdAt are null', () {
      expect(_program().activationFloor, isNull);
    });

    test('boundary: a date equal to the floor is NOT before it (eligible)', () {
      final p = _program(activatedAt: DateTime(2026, 3, 15, 23, 59));
      final floor = p.activationFloor!;
      final sameDay = DateTime(2026, 3, 15);
      final dayBefore = DateTime(2026, 3, 14);
      // On the activation day → eligible (not before floor).
      expect(sameDay.isBefore(floor), isFalse);
      // Day before activation → not eligible (before floor).
      expect(dayBefore.isBefore(floor), isTrue);
    });
  });
}
