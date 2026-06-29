/// Centralized animation duration constants.
///
/// Use these instead of raw `Duration(milliseconds: N)` literals so that
/// the app's motion feel can be tuned in one place.
class AppDurations {
  AppDurations._();

  /// 150 ms — micro-interaction pop (nav icon pulse, scale-tap).
  static const extraFast = Duration(milliseconds: 150);

  /// 200 ms — quick transitions (tab switch, stat counter tween, indicator pill).
  static const fast = Duration(milliseconds: 200);

  /// 250 ms — standard animated values (progress bars, slide-up entrances).
  static const medium = Duration(milliseconds: 250);

  /// 350 ms — immersive modal entrances (slide-from-bottom route transitions).
  static const slow = Duration(milliseconds: 350);

  /// 1 500 ms — looping shimmer skeleton animation.
  static const skeleton = Duration(milliseconds: 1500);
}
