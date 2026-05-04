import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/coach/data/coach_repository.dart';

void main() {
  group('CoachRepository API surface', () {
    test('class exists and can be referenced', () {
      expect(CoachRepository, isNotNull);
    });
  });

  group('CoachInvite code generation', () {
    test('generateInviteCode returns 6-char alphanumeric string', () {
      final code = CoachRepository.generateInviteCode();
      expect(code.length, 6);
      expect(RegExp(r'^[A-Z0-9]{6}$').hasMatch(code), true);
    });

    test('generateInviteCode produces unique codes', () {
      final codes = List.generate(100, (_) => CoachRepository.generateInviteCode());
      expect(codes.toSet().length, codes.length);
    });
  });
}
