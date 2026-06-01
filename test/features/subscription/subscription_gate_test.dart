import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymratz/app/providers/subscription_providers.dart';
import 'package:gymratz/features/subscription/presentation/subscription_gate.dart';

Widget _testApp(Widget child, {required Override isProOverride}) {
  return ProviderScope(
    overrides: [isProOverride],
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp.router(
        routerConfig: GoRouter(routes: [
          GoRoute(path: '/', builder: (_, __) => child),
          GoRoute(path: '/paywall', builder: (_, __) => const Scaffold(body: Text('Paywall'))),
        ]),
      ),
    ),
  );
}

Override _proOverride(bool isPro) => isProProvider.overrideWith(
      (ref) => Stream.value(isPro),
    );

void main() {
  group('SubscriptionGate — expired subscription (isPro=false)', () {
    testWidgets('non-profile tab shows ExpiredBanner and AbsorbPointer', (tester) async {
      await tester.pumpWidget(_testApp(
        SubscriptionGate(currentIndex: 0, child: const Text('Content')),
        isProOverride: _proOverride(false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your trial has ended. Subscribe to continue.'), findsOneWidget);
      // Verify there is an AbsorbPointer that is actually absorbing (absorbing: true)
      expect(
        find.byWidgetPredicate((w) => w is AbsorbPointer && w.absorbing),
        findsOneWidget,
      );
    });

    testWidgets('profile tab (index 4) shows banner but NOT absorbing AbsorbPointer', (tester) async {
      await tester.pumpWidget(_testApp(
        SubscriptionGate(currentIndex: 4, child: const Text('Profile')),
        isProOverride: _proOverride(false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your trial has ended. Subscribe to continue.'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is AbsorbPointer && w.absorbing),
        findsNothing,
      );
      expect(find.text('Profile'), findsOneWidget);
    });
  });

  group('SubscriptionGate — active subscription (isPro=true)', () {
    testWidgets('renders child without banner', (tester) async {
      await tester.pumpWidget(_testApp(
        SubscriptionGate(currentIndex: 0, child: const Text('Content')),
        isProOverride: _proOverride(true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your trial has ended. Subscribe to continue.'), findsNothing);
      expect(find.text('Content'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is AbsorbPointer && w.absorbing),
        findsNothing,
      );
    });
  });
}
