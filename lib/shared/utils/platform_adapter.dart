import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

abstract final class PlatformAdapter {
  static bool get isCupertino =>
      Platform.isIOS || Platform.isMacOS;

  static ScrollPhysics get scrollPhysics => isCupertino
      ? const BouncingScrollPhysics()
      : const ClampingScrollPhysics();

  static Page<T> buildPage<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    if (isCupertino) {
      return CupertinoPage<T>(key: state.pageKey, child: child);
    }
    return MaterialPage<T>(key: state.pageKey, child: child);
  }

  static void hapticLight() => HapticFeedback.lightImpact();
  static void hapticMedium() => HapticFeedback.mediumImpact();
  static void hapticHeavy() => HapticFeedback.heavyImpact();
  static void hapticSelection() => HapticFeedback.selectionClick();
}
