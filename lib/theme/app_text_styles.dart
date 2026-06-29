import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static String? _fontFamily;

  static String get fontFamily {
    _fontFamily ??= GoogleFonts.montserrat().fontFamily;
    return _fontFamily!;
  }

  // ─── Display ───
  static TextStyle get display => TextStyle(
        fontFamily: fontFamily,
        fontSize: 48.sp,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  // ─── Headings ───
  static TextStyle get h1 => TextStyle(
        fontFamily: fontFamily,
        fontSize: 24.sp,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get h2 => TextStyle(
        fontFamily: fontFamily,
        fontSize: 20.sp,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get h3 => TextStyle(
        fontFamily: fontFamily,
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get h4 => TextStyle(
        fontFamily: fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  // ─── Body ───
  static TextStyle get body => TextStyle(
        fontFamily: fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: fontFamily,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get caption => TextStyle(
        fontFamily: fontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ─── Special ───

  /// Bottom navigation bar label. 10sp keeps 5 labels legible without crowding.
  static TextStyle get navLabel => TextStyle(
        fontFamily: fontFamily,
        fontSize: 10.sp,
        fontWeight: FontWeight.w400,
        height: 1.0,
      );

  static TextStyle get buttonText => TextStyle(
        fontFamily: fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  static TextStyle get label => TextStyle(
        fontFamily: fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get tabular => TextStyle(
        fontFamily: fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
