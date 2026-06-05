// GYM-101: Golden tests for CustomButton, CustomCard, EmptyStateWidget
//
// Generate / update baselines:
//   flutter test --update-goldens test/golden/
//
// Run normally (compare against baselines):
//   flutter test test/golden/

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymratz/shared/widgets/custom_button.dart';
import 'package:gymratz/shared/widgets/custom_card.dart';
import 'package:gymratz/shared/widgets/empty_state_widget.dart';

// ---------------------------------------------------------------------------
// Test wrapper
// ---------------------------------------------------------------------------

/// Wraps a widget in a MaterialApp with a fixed surface size so goldens are
/// stable across machines. Uses the same design size as the rest of the test
/// suite (390 × 844 — the ScreenUtil reference device).
Widget _wrap(Widget child, {bool dark = false}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

// Golden baselines are not committed yet.
// To generate: flutter test --update-goldens test/golden/
// Then commit the generated files in test/golden/goldens/.
const _goldenSkip = 'Golden baseline images not yet committed — run flutter test --update-goldens to initialise';

void main() {
  group('CustomButton golden tests', () {
    testWidgets('enabled primary button matches golden', skip: _goldenSkip, (tester) async {
      await _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          CustomButton(
            text: 'Start Workout',
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CustomButton),
        matchesGoldenFile('goldens/custom_button_enabled.png'),
      );
    });

    testWidgets('disabled button (onPressed null) matches golden', skip: _goldenSkip, (tester) async {
      await _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          const CustomButton(
            text: 'Start Workout',
            onPressed: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CustomButton),
        matchesGoldenFile('goldens/custom_button_disabled.png'),
      );
    });

    testWidgets('loading state matches golden', skip: _goldenSkip, (tester) async {
      await _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          CustomButton(
            text: 'Start Workout',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );
      // Don't call pumpAndSettle — CircularProgressIndicator animates forever.
      await tester.pump();

      await expectLater(
        find.byType(CustomButton),
        matchesGoldenFile('goldens/custom_button_loading.png'),
      );
    });
  });

  group('CustomCard golden tests', () {
    testWidgets('standard card with text content matches golden', skip: _goldenSkip, (tester) async {
      await _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          const CustomCard(
            child: Text('Card content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CustomCard),
        matchesGoldenFile('goldens/custom_card_standard.png'),
      );
    });

    testWidgets('workout variant card matches golden', skip: _goldenSkip, (tester) async {
      await _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          const CustomCard(
            variant: CardVariant.workout,
            child: Text('Workout Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CustomCard),
        matchesGoldenFile('goldens/custom_card_workout.png'),
      );
    });
  });

  group('EmptyStateWidget golden tests', () {
    testWidgets('empty state without action matches golden', skip: _goldenSkip, (tester) async {
      await _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          const EmptyStateWidget(
            icon: Icons.fitness_center,
            title: 'No Workouts Yet',
            subtitle: 'Start your first workout to see your progress here.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(EmptyStateWidget),
        matchesGoldenFile('goldens/empty_state_no_action.png'),
      );
    });

    testWidgets('empty state with action button matches golden', skip: _goldenSkip, (tester) async {
      await _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          EmptyStateWidget(
            icon: Icons.fitness_center,
            title: 'No Workouts Yet',
            subtitle: 'Start your first workout to see your progress here.',
            actionLabel: 'Start Workout',
            onAction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(EmptyStateWidget),
        matchesGoldenFile('goldens/empty_state_with_action.png'),
      );
    });
  });
}
