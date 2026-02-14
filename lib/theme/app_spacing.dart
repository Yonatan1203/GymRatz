import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSpacing {
  AppSpacing._();

  // Base unit: 4px (Tailwind default)
  static double get xs => 2.r;    // gap-0.5
  static double get sm => 4.r;    // gap-1
  static double get md => 8.r;    // gap-2
  static double get lg => 12.r;   // gap-3
  static double get xl => 16.r;   // gap-4, p-4
  static double get xxl => 24.r;  // p-6, px-6 (standard horizontal padding)
  static double get xxxl => 32.r; // p-8

  // Semantic aliases
  static double get screenPadding => 24.r;    // px-6
  static double get headerTopPadding => 48.r; // pt-12
  static double get sectionGap => 24.r;       // mb-6
  static double get cardPadding => 16.r;      // p-4
  static double get itemGap => 12.r;          // gap-3
}
