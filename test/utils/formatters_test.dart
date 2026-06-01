import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/utils/formatters.dart';

void main() {
  group('Formatters.volume', () {
    test('below 1000 returns integer string', () {
      expect(Formatters.volume(999), '999');
    });

    test('exactly 1000 returns 1.0k', () {
      expect(Formatters.volume(1000), '1.0k');
    });

    test('above 1000 returns k-suffix with one decimal', () {
      expect(Formatters.volume(1500), '1.5k');
      expect(Formatters.volume(10000), '10.0k');
    });

    test('zero returns 0', () {
      expect(Formatters.volume(0), '0');
    });
  });

  group('Formatters.weight', () {
    test('whole number omits decimal', () {
      expect(Formatters.weight(100.0, 'kg'), '100 kg');
    });

    test('fractional number shows one decimal', () {
      expect(Formatters.weight(102.5, 'kg'), '102.5 kg');
    });

    test('unit is appended', () {
      expect(Formatters.weight(45.0, 'lbs'), '45 lbs');
    });
  });

  group('Formatters.duration', () {
    test('under 60 minutes returns Xmin', () {
      expect(Formatters.duration(59), '59min');
      expect(Formatters.duration(1), '1min');
    });

    test('exactly 60 minutes returns 1h', () {
      expect(Formatters.duration(60), '1h');
    });

    test('over 60 with remainder returns Xh Ymin', () {
      expect(Formatters.duration(90), '1h 30min');
      expect(Formatters.duration(125), '2h 5min');
    });

    test('exact hour multiple omits minutes', () {
      expect(Formatters.duration(120), '2h');
    });
  });

  group('Formatters.timer', () {
    test('zero returns 00:00', () {
      expect(Formatters.timer(0), '00:00');
    });

    test('pads single digits', () {
      expect(Formatters.timer(65), '01:05');
    });

    test('minutes can exceed 59', () {
      expect(Formatters.timer(3661), '61:01');
    });

    test('exactly one minute', () {
      expect(Formatters.timer(60), '01:00');
    });
  });
}
