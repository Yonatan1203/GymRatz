import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppRadius {
  AppRadius._();

  // Plain values safe for theme definitions (no ScreenUtil dependency).
  static const double sm = 6;     // calc(var(--radius) - 4px)
  static const double md = 8;     // calc(var(--radius) - 2px)
  static const double lg = 10;    // var(--radius)
  static const double xl = 14;    // calc(var(--radius) + 4px)
  static const double xxl = 16;   // rounded-2xl
  static const double full = 999; // rounded-full

  // Adaptive variants (use in widget build methods only, after ScreenUtil init).
  static double get smR => 6.r;
  static double get mdR => 8.r;
  static double get lgR => 10.r;
  static double get xlR => 14.r;
  static double get xxlR => 16.r;
  static double get fullR => 999.r;

  // BorderRadius helpers (plain — safe for themes)
  static BorderRadius get headerBottom => const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      );
  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
  static BorderRadius get borderXl => BorderRadius.circular(xl);
  static BorderRadius get borderXxl => BorderRadius.circular(xxl);
  static BorderRadius get borderFull => BorderRadius.circular(full);
}
