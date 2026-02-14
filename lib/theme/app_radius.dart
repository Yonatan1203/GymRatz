import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppRadius {
  AppRadius._();

  // Base: --radius: 0.625rem = 10px
  static double get sm => 6.r;     // calc(var(--radius) - 4px)
  static double get md => 8.r;     // calc(var(--radius) - 2px)
  static double get lg => 10.r;    // var(--radius)
  static double get xl => 14.r;    // calc(var(--radius) + 4px)
  static double get xxl => 16.r;   // rounded-2xl
  static double get full => 999.r; // rounded-full

  // BorderRadius helpers
  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
  static BorderRadius get borderXl => BorderRadius.circular(xl);
  static BorderRadius get borderXxl => BorderRadius.circular(xxl);
  static BorderRadius get borderFull => BorderRadius.circular(full);
}
