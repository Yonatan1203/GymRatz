import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/widgets/offline_banner.dart';

Widget _wrap(Stream<List<ConnectivityResult>> stream) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(body: OfflineBanner(connectivityStream: stream)),
      ),
    );

void main() {
  group('OfflineBanner', () {
    test('is pure Dart widget — constructor accepts connectivityStream', () {
      expect(
        () => OfflineBanner(connectivityStream: const Stream.empty()),
        returnsNormally,
      );
    });

    testWidgets('visible when stream emits [ConnectivityResult.none]',
        (tester) async {
      final ctrl = StreamController<List<ConnectivityResult>>.broadcast();
      await tester.pumpWidget(_wrap(ctrl.stream));

      ctrl.add([ConnectivityResult.none]);
      await tester.pump();

      expect(find.textContaining('offline'), findsOneWidget);
      ctrl.close();
    });

    testWidgets('hidden when stream emits [ConnectivityResult.wifi]',
        (tester) async {
      final ctrl = StreamController<List<ConnectivityResult>>.broadcast();
      await tester.pumpWidget(_wrap(ctrl.stream));

      ctrl.add([ConnectivityResult.wifi]);
      await tester.pump();

      expect(find.textContaining('offline'), findsNothing);
      ctrl.close();
    });

    testWidgets('visible when stream emits empty list (treated as offline)',
        (tester) async {
      final ctrl = StreamController<List<ConnectivityResult>>.broadcast();
      await tester.pumpWidget(_wrap(ctrl.stream));

      ctrl.add([]);
      await tester.pump();

      expect(find.textContaining('offline'), findsOneWidget);
      ctrl.close();
    });

    testWidgets('nothing rendered before stream emits (loading state)',
        (tester) async {
      final ctrl = StreamController<List<ConnectivityResult>>.broadcast();
      await tester.pumpWidget(_wrap(ctrl.stream));
      // No event emitted yet
      await tester.pump();

      expect(find.textContaining('offline'), findsNothing);
      ctrl.close();
    });
  });
}
