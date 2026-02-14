import 'package:flutter/material.dart';

import 'platform_adapter.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      PlatformAdapter.scrollPhysics;
}
