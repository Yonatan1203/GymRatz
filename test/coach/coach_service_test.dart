import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/coach/domain/coach_service.dart';
import 'package:gymratz/core/constants.dart';

void main() {
  group('CoachService.maxClientsForTier', () {
    test('returns correct max for each tier', () {
      expect(AppConstants.maxClientsForTier('coach_5'), 5);
      expect(AppConstants.maxClientsForTier('coach_10'), 10);
      expect(AppConstants.maxClientsForTier('coach_20'), 20);
      expect(AppConstants.maxClientsForTier('unknown'), 0);
    });
  });

  group('CoachService API surface', () {
    test('class exists and can be referenced', () {
      expect(CoachService, isNotNull);
    });
  });
}
