# GymRatz UI/UX Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Elevate GymRatz from functional to industry-standard premium visuals — unified design system, subtle animations, polished onboarding, and consistent patterns across all screens.

**Architecture:** Foundation-up approach. First harden the design system (colors, animations, header/card variants), then apply the unified screen template to all screens, then overhaul onboarding, then final polish pass. Each phase builds on the previous.

**Tech Stack:** Flutter, Riverpod, GoRouter, flutter_screenutil, Lucide icons, Google Fonts (Montserrat)

**Branch:** `feature/ui-ux-polish` (branched from `feature/production-readiness`)

**Spec:** `docs/superpowers/specs/2026-04-19-ui-ux-polish-design.md`

---

## Phase 1: Design System Foundation

### Task 1: Create branch and add coral accent colors

**Files:**
- Modify: `lib/theme/app_colors.dart`
- Modify: `lib/shared/utils/extensions.dart`

- [ ] **Step 1: Create the feature branch**

```bash
git checkout feature/production-readiness
git checkout -b feature/ui-ux-polish
```

- [ ] **Step 2: Add coral colors to AppColors**

In `lib/theme/app_colors.dart`, add after the existing dark mode colors (after `darkRing`):

```dart
  // Coral accent — warm energy color
  static const lightCoral = Color(0xFFEF6B4A);
  static const darkCoral = Color(0xFFC4553B);
  static const lightCoralForeground = Colors.white;
  static const darkCoralForeground = Colors.white;
```

- [ ] **Step 3: Add coral getters to BuildContext extensions**

In `lib/shared/utils/extensions.dart`, add after the existing color getters:

```dart
  Color get coralColor => isDark ? AppColors.darkCoral : AppColors.lightCoral;
  Color get coralForeground => isDark ? AppColors.darkCoralForeground : AppColors.lightCoralForeground;
```

- [ ] **Step 4: Verify the app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add lib/theme/app_colors.dart lib/shared/utils/extensions.dart
git commit -m "feat: add coral accent color (#EF6B4A light, #C4553B dark)"
```

---

### Task 2: Create animation primitives — FadeIn, SlideUp, ScaleTap

**Files:**
- Create: `lib/shared/widgets/fade_in.dart`
- Create: `lib/shared/widgets/slide_up.dart`
- Create: `lib/shared/widgets/scale_tap.dart`

- [ ] **Step 1: Create FadeIn widget**

Create `lib/shared/widgets/fade_in.dart`:

```dart
import 'package:flutter/material.dart';

class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.delay = Duration.zero,
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.child,
    );
  }
}
```

- [ ] **Step 2: Create SlideUp widget**

Create `lib/shared/widgets/slide_up.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SlideUp extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;

  const SlideUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.delay = Duration.zero,
    this.offset = 16,
  });

  @override
  State<SlideUp> createState() => _SlideUpState();
}

class _SlideUpState extends State<SlideUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _opacity = curve;
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset.r),
      end: Offset.zero,
    ).animate(curve);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slide.value,
          child: Opacity(
            opacity: _opacity.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
```

- [ ] **Step 3: Create ScaleTap widget**

Create `lib/shared/widgets/scale_tap.dart`:

```dart
import 'package:flutter/material.dart';

class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double scaleDown;

  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
    this.scaleDown = 0.97,
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
```

- [ ] **Step 4: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/fade_in.dart lib/shared/widgets/slide_up.dart lib/shared/widgets/scale_tap.dart
git commit -m "feat: add animation primitives — FadeIn, SlideUp, ScaleTap"
```

---

### Task 3: Create animation primitives — StaggeredList, AnimatedProgress

**Files:**
- Create: `lib/shared/widgets/staggered_list.dart`
- Create: `lib/shared/widgets/animated_progress.dart`

- [ ] **Step 1: Create StaggeredList widget**

Create `lib/shared/widgets/staggered_list.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:gymratz/shared/widgets/slide_up.dart';

class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  const StaggeredList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 200),
    this.mainAxisSize = MainAxisSize.min,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++)
          SlideUp(
            duration: itemDuration,
            delay: itemDelay * i,
            child: children[i],
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: Create AnimatedProgress widget**

Create `lib/shared/widgets/animated_progress.dart`:

```dart
import 'package:flutter/material.dart';

class AnimatedProgress extends StatefulWidget {
  final double value;
  final Duration duration;
  final Widget Function(BuildContext context, double animatedValue) builder;

  const AnimatedProgress({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<AnimatedProgress> createState() => _AnimatedProgressState();
}

class _AnimatedProgressState extends State<AnimatedProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => widget.builder(context, _animation.value),
    );
  }
}
```

- [ ] **Step 3: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/staggered_list.dart lib/shared/widgets/animated_progress.dart
git commit -m "feat: add StaggeredList and AnimatedProgress animation widgets"
```

---

### Task 4: Create SkeletonLoader widget

**Files:**
- Create: `lib/shared/widgets/skeleton_loader.dart`

- [ ] **Step 1: Create SkeletonLoader widget with shimmer animation**

Create `lib/shared/widgets/skeleton_loader.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymratz/shared/utils/extensions.dart';
import 'package:gymratz/theme/app_radius.dart';

class SkeletonLoader extends StatefulWidget {
  final Widget child;

  const SkeletonLoader({super.key, required this.child});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                context.mutedColor,
                context.mutedColor.withOpacity(0.5),
                context.mutedColor,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single skeleton line placeholder
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height.r,
      decoration: BoxDecoration(
        color: context.mutedColor,
        borderRadius: borderRadius ?? AppRadius.borderMd,
      ),
    );
  }
}

/// A skeleton circle placeholder (for avatars, icons)
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        color: context.mutedColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A skeleton card placeholder (matches CustomCard shape)
class SkeletonCard extends StatelessWidget {
  final double? height;
  final Widget? child;

  const SkeletonCard({super.key, this.height, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height?.r,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: context.borderColor),
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 2: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/skeleton_loader.dart
git commit -m "feat: add SkeletonLoader with shimmer animation"
```

---

### Task 5: Update GradientHeader with subtle variant

**Files:**
- Modify: `lib/shared/widgets/gradient_header.dart`

- [ ] **Step 1: Read the current GradientHeader implementation**

Read `lib/shared/widgets/gradient_header.dart` to confirm exact line numbers and current structure before editing.

- [ ] **Step 2: Add HeaderVariant enum and update GradientHeader**

Add the `HeaderVariant` enum at the top of the file (before the class):

```dart
enum HeaderVariant { subtle, hero }
```

Update the `GradientHeader` constructor to accept a `variant` parameter with default `HeaderVariant.subtle`.

- [ ] **Step 3: Update the Container decoration**

Replace the current decoration logic to be conditional on variant:
- `HeaderVariant.hero`: Keep the existing gradient, rounded bottom corners (headerBottom), and box shadow
- `HeaderVariant.subtle`: Use `primary.withOpacity(0.08)` for light / `primary.withOpacity(0.12)` for dark as background, a 1px bottom border using `primary.withOpacity(0.12)` for light / `primary.withOpacity(0.15)` for dark, no rounded corners, no shadow

The subtle variant should use a `Container` with `BoxDecoration` that has:
- `color`: the subtle tint color (not a gradient)
- `border`: `Border(bottom: BorderSide(color: borderColor, width: 1))`

The hero variant keeps the existing `BoxDecoration` with gradient, borderRadius, and boxShadow unchanged.

- [ ] **Step 4: Verify build and test both variants visually**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/gradient_header.dart
git commit -m "feat: add HeaderVariant.subtle to GradientHeader — tint bg with border"
```

---

### Task 6: Update CustomCard with card variants

**Files:**
- Modify: `lib/shared/widgets/custom_card.dart`

- [ ] **Step 1: Read the current CustomCard implementation**

Read `lib/shared/widgets/custom_card.dart` to confirm exact structure.

- [ ] **Step 2: Add CardVariant enum**

Add at the top of the file:

```dart
enum CardVariant { standard, workout, program, stat, actionCta }
```

- [ ] **Step 3: Add variant parameter to CustomCard constructor**

Add `this.variant = CardVariant.standard` to the constructor. Keep all existing parameters working — the variant adds additional styling on top.

- [ ] **Step 4: Implement variant-specific decoration**

Update the `BoxDecoration` in the build method to apply variant-specific styles:

- `standard`: Existing behavior unchanged (card bg + border + shadow)
- `workout`: Add a teal left accent bar. Implement by wrapping the existing card content in a `Stack` or `Row` with a 3px wide teal `Container` on the left. Use `primary.withOpacity(0.25)` for the border color.
- `program`: Same as standard (progress bar is added by the screen, not the card)
- `stat`: Same as standard (compact styling is handled by the screen's grid layout)
- `actionCta`: Use `coralColor.withOpacity(0.08)` as background, `coralColor.withOpacity(0.2)` as border color

This approach keeps the card flexible — variants just change colors/accents, not layout.

- [ ] **Step 5: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets/custom_card.dart
git commit -m "feat: add CardVariant to CustomCard — workout, program, stat, actionCta"
```

---

## Phase 2: Apply Unified Screen Template

### Task 7: Update Home screen to unified template

**Files:**
- Modify: `lib/features/home/presentation/home_screen.dart` (454 lines)

- [ ] **Step 1: Read the current Home screen**

Read `lib/features/home/presentation/home_screen.dart` fully.

- [ ] **Step 2: Replace manual gradient header with GradientHeader**

The Home screen currently builds its own header with a manual `Container` and `AppGradients.primary()` (around lines 65-189). Replace this entire manual header block with:

```dart
GradientHeader(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Title row with greeting
      // Streak badge (use coral tint: coralColor.withOpacity(0.12) bg)
      // Week day selector (if kept in header)
    ],
  ),
)
```

Keep the header content (greeting, streak, week selector) but wrap it in the standard `GradientHeader` widget with the default `HeaderVariant.subtle`.

- [ ] **Step 3: Standardize spacing tokens**

Replace all manual spacing values with `AppSpacing` tokens:
- `4.h` → `AppSpacing.sm`
- `6.w` → `AppSpacing.sm` (or remove if unnecessary)
- `8.h` → `AppSpacing.md`
- `12.h` → `AppSpacing.lg` / `AppSpacing.itemGap`
- `16.h` → `AppSpacing.xl`
- Section gaps should consistently use `AppSpacing.sectionGap` (24r)
- Card internal padding should use `AppSpacing.cardPadding` (16r)

- [ ] **Step 4: Apply card variants**

- Today's workout card → `CustomCard(variant: CardVariant.workout, ...)`
- Quick action cards (Progress, Programs) → `CustomCard(variant: CardVariant.standard, ...)`
- "Start Workout" CTA → `CustomCard(variant: CardVariant.actionCta, ...)`
- Recent activity items → `CustomCard(variant: CardVariant.standard, ...)`
- Stats grid → keep using `StatsGrid` widget (no changes needed)

- [ ] **Step 5: Wrap tappable cards in ScaleTap**

Every `CustomCard` that has an `onTap` should be wrapped in `ScaleTap` instead of using `onTap` directly on the card:

```dart
ScaleTap(
  onTap: () => context.push('/route'),
  child: CustomCard(
    // Remove onTap from CustomCard, ScaleTap handles it
    child: ...,
  ),
)
```

- [ ] **Step 6: Add StaggeredList to content sections**

Wrap the main content column's sections in `StaggeredList`:

```dart
StaggeredList(
  children: [
    statsGridSection,
    todayWorkoutSection,
    quickActionsSection,
    recentActivitySection,
  ],
)
```

- [ ] **Step 7: Update streak badge to use coral**

Change the streak/flame badge color from the current teal/white to coral:
- Background: `context.coralColor.withOpacity(0.12)`
- Border: `context.coralColor.withOpacity(0.2)`
- Text/icon: `context.coralColor`

- [ ] **Step 8: Verify build and visual test**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Run the app and verify Home screen looks correct in both light and dark mode.

- [ ] **Step 9: Commit**

```bash
git add lib/features/home/presentation/home_screen.dart
git commit -m "feat: apply unified screen template to Home — subtle header, card variants, animations"
```

---

### Task 8: Update Workout screen to unified template

**Files:**
- Modify: `lib/features/workout/presentation/workout_screen.dart` (322 lines)

- [ ] **Step 1: Read the current Workout screen**

Read `lib/features/workout/presentation/workout_screen.dart` fully.

- [ ] **Step 2: Replace manual header with GradientHeader**

Replace the manual Container header (around lines 51-72) with `GradientHeader` (default subtle variant). Keep the title and date subtitle as the child content.

- [ ] **Step 3: Standardize spacing tokens**

Replace manual values with `AppSpacing` tokens. Ensure section gaps use `sectionGap`, item gaps use `itemGap`, card padding uses `cardPadding`.

- [ ] **Step 4: Apply card variants to workout cards**

- Workout day cards → `CustomCard(variant: CardVariant.workout, ...)`
- Weekly stats → `StatsGrid` (already correct)
- Empty state card → keep as standard

- [ ] **Step 5: Wrap tappable cards in ScaleTap, add StaggeredList**

Same pattern as Home screen — ScaleTap for tappable cards, StaggeredList for the workout day list.

- [ ] **Step 6: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/workout/presentation/workout_screen.dart
git commit -m "feat: apply unified screen template to Workout — subtle header, card variants, animations"
```

---

### Task 9: Update Programs screen to unified template

**Files:**
- Modify: `lib/features/programs/presentation/programs_screen.dart` (307 lines)

- [ ] **Step 1: Read the current Programs screen**

Read `lib/features/programs/presentation/programs_screen.dart` fully.

- [ ] **Step 2: Replace manual header with GradientHeader**

Replace the manual Container header (around lines 53-69) with `GradientHeader` (default subtle variant).

- [ ] **Step 3: Standardize spacing tokens**

Replace manual values with `AppSpacing` tokens consistently.

- [ ] **Step 4: Apply card variants**

- Create program CTA → `CustomCard(variant: CardVariant.actionCta, ...)`
- Program list cards → `CustomCard(variant: CardVariant.program, ...)`
- Explore cards → `CustomCard(variant: CardVariant.standard, ...)`

- [ ] **Step 5: Wrap tappable cards in ScaleTap, add StaggeredList**

- [ ] **Step 6: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/programs/presentation/programs_screen.dart
git commit -m "feat: apply unified screen template to Programs — subtle header, card variants, animations"
```

---

### Task 10: Update Profile screen to unified template

**Files:**
- Modify: `lib/features/profile/presentation/profile_screen.dart` (242 lines)

- [ ] **Step 1: Read the current Profile screen**

Read `lib/features/profile/presentation/profile_screen.dart` fully.

- [ ] **Step 2: Replace manual header with GradientHeader**

Replace the manual Container header (around lines 97-150) with `GradientHeader`. The profile header is more complex (avatar, name, stats grid), so keep all that content as the `child` of `GradientHeader`.

- [ ] **Step 3: Standardize spacing tokens**

Replace `8.h`, `12.h`, `16.w` etc. with `AppSpacing` tokens.

- [ ] **Step 4: Apply card variants and ScaleTap**

- Menu sections → `CustomCard(variant: CardVariant.standard, ...)`
- Subscription upgrade card → `CustomCard(variant: CardVariant.actionCta, ...)`
- All menu items with onTap → wrap in `ScaleTap`

- [ ] **Step 5: Add StaggeredList to content sections**

- [ ] **Step 6: Add loading/error states for profile data**

Currently Profile uses `.valueOrNull` with fallback to sample data (no explicit error/loading). Add proper `.when()` handling with skeleton loader for loading state.

- [ ] **Step 7: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 8: Commit**

```bash
git add lib/features/profile/presentation/profile_screen.dart
git commit -m "feat: apply unified screen template to Profile — subtle header, card variants, animations"
```

---

### Task 11: Update Calendar screen to unified template

**Files:**
- Modify: `lib/features/calendar/presentation/calendar_screen.dart` (640 lines)

- [ ] **Step 1: Read the current Calendar screen**

Read `lib/features/calendar/presentation/calendar_screen.dart` fully.

- [ ] **Step 2: Update GradientHeader to subtle variant**

Calendar already uses `GradientHeader`. It now defaults to subtle since we changed the default. Verify it renders correctly with the subtle treatment. The month navigation and completion ring should remain as header content.

- [ ] **Step 3: Standardize spacing tokens**

Replace manual values: `6` (grid spacing), `80.h`, `8.h`, `16.h`, `20.h` → `AppSpacing` equivalents.

- [ ] **Step 4: Apply status colors to calendar day cells**

Update the calendar day cell colors to use the standardized status colors from the spec:
- Completed: `context.primaryColor.withOpacity(0.15)` (teal tint)
- Active/today: Coral border if it's today and has an active workout
- Missed: Keep existing orange `#F97316`
- Rest: `context.cardColor` with subtle border

- [ ] **Step 5: Add StaggeredList to content below calendar**

Wrap streak stats and weight sections in `StaggeredList`.

- [ ] **Step 6: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/calendar/presentation/calendar_screen.dart
git commit -m "feat: apply unified screen template to Calendar — standardized spacing, status colors, animations"
```

---

### Task 12: Update detail/push screens to unified template

**Files:**
- Modify: `lib/features/programs/presentation/program_detail_screen.dart` (785 lines)
- Modify: `lib/features/profile/presentation/edit_profile_screen.dart` (299 lines)
- Modify: `lib/features/subscription/presentation/paywall_screen.dart` (345 lines)

- [ ] **Step 1: Read all three screens**

Read each file to confirm current state.

- [ ] **Step 2: Update ProgramDetailScreen**

- Already uses `GradientHeader(showBackButton: true)` — will now default to subtle variant. Verify rendering.
- Standardize spacing tokens throughout
- Apply `CardVariant.workout` to day cards
- Wrap tappable items in `ScaleTap`
- Add `StaggeredList` to exercises list

- [ ] **Step 3: Update EditProfileScreen**

- Already uses `GradientHeader(showBackButton: true)` — verify subtle rendering
- Standardize spacing tokens (replace `32.h`, `16.h` with `AppSpacing` tokens)
- No card variants needed (form-based screen)

- [ ] **Step 4: Update PaywallScreen**

- Uses `GradientHeader(showBackButton: true)` — this should use `variant: HeaderVariant.hero` since it's a special/hero screen per the spec
- Pricing cards: convert custom `Container` widgets to `CustomCard` with proper variant
- Best value (yearly) card should use a gradient or coral accent to stand out
- Standardize spacing

- [ ] **Step 5: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/programs/presentation/program_detail_screen.dart lib/features/profile/presentation/edit_profile_screen.dart lib/features/subscription/presentation/paywall_screen.dart
git commit -m "feat: apply unified template to ProgramDetail, EditProfile, Paywall"
```

---

## Phase 3: Bottom Nav, Loading States & Color Standardization

### Task 13: Polish bottom navigation

**Files:**
- Modify: `lib/shared/widgets/custom_scaffold.dart` (207 lines)

- [ ] **Step 1: Read the current CustomScaffold implementation**

Read `lib/shared/widgets/custom_scaffold.dart` fully, focusing on the bottom nav bar area (lines 53-114) and `_NavItem` class (lines 151-207).

- [ ] **Step 2: Add animated active indicator pill**

In the bottom nav bar, add a teal pill indicator (20px wide, 3px tall) positioned above the active tab icon. This should animate its position when tabs change using an `AnimatedPositioned` or `AnimatedAlign` with 200ms easeOut duration.

Implementation approach:
- Convert `_NavItem` or the nav bar row to use a `Stack` with an `AnimatedPositioned` pill widget
- The pill's horizontal position tracks the active tab index
- Color: `context.primaryColor` (teal)

- [ ] **Step 3: Add active icon scale**

In `_NavItem`, when `isActive` is true, wrap the icon in `Transform.scale(scale: 1.1)`. When inactive, scale is 1.0.

- [ ] **Step 4: Update active label weight**

Change the label `FontWeight` from the current active weight to `FontWeight.w600` for active, `FontWeight.w400` for inactive.

- [ ] **Step 5: Add tap pulse animation to nav items**

Add a brief scale pulse (1.0→1.15→1.0, 150ms) on tap in `_NavItem`. Use an `AnimationController` triggered on tap.

- [ ] **Step 6: Add theme toggle rotation**

In the `_ThemeToggle` widget (around lines 119-148), wrap the sun/moon icon in an `AnimatedRotation` with 0.5 turns and 200ms duration, keyed to the current theme mode.

- [ ] **Step 7: Verify build and test tab switching**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Test all 5 tabs, verify pill animates, icon scales, and theme toggle rotates.

- [ ] **Step 8: Commit**

```bash
git add lib/shared/widgets/custom_scaffold.dart
git commit -m "feat: polish bottom nav — animated pill indicator, icon scale, tap pulse, theme rotation"
```

---

### Task 14: Update EmptyStateWidget and error states

**Files:**
- Modify: `lib/shared/widgets/empty_state_widget.dart` (46 lines)
- Modify: `lib/shared/widgets/async_value_widget.dart` (62 lines)

- [ ] **Step 1: Read both files**

Read `empty_state_widget.dart` and `async_value_widget.dart` fully.

- [ ] **Step 2: Update EmptyStateWidget**

Redesign the EmptyStateWidget:

- Icon container: Change from a simple `Icon` to a 64px rounded square container with `borderRadius: AppRadius.borderXl`, background `context.primaryColor.withOpacity(0.1)`, border `context.primaryColor.withOpacity(0.15)`, with the icon centered inside.
- Title: Keep as-is (titleMedium style)
- Subtitle: Keep as-is but with `maxWidth` constraint for readability
- Action button: Change from default button to coral action style — background `context.coralColor.withOpacity(0.08)`, border `context.coralColor.withOpacity(0.2)`, text color `context.coralColor`
- Animation: Wrap the entire widget content in a `Column` where each child uses `SlideUp` or `FadeIn` with staggered delays:
  - Icon: `FadeIn(delay: Duration.zero)`
  - Title: `SlideUp(delay: Duration(milliseconds: 100))`
  - Subtitle: `FadeIn(delay: Duration(milliseconds: 200))`
  - Button: `SlideUp(delay: Duration(milliseconds: 300))`

- [ ] **Step 3: Update AsyncValueWidget loading state**

Replace the `_defaultLoading()` method's `CircularProgressIndicator` with `SkeletonLoader`:

```dart
Widget _defaultLoading() {
  return SkeletonLoader(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          SkeletonCard(height: 80),
          SizedBox(height: AppSpacing.itemGap),
          SkeletonCard(height: 80),
          SizedBox(height: AppSpacing.itemGap),
          SkeletonCard(height: 60),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 4: Update AsyncValueWidget error state**

Update `_defaultError()` to match the new error pattern:

- Icon: 64px rounded square container with destructive tint background
- Message: Specific error text (pass through from AsyncValue error)
- Retry button: Teal styled (not destructive)
- Same staggered animation as empty state

- [ ] **Step 5: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets/empty_state_widget.dart lib/shared/widgets/async_value_widget.dart
git commit -m "feat: redesign empty/loading/error states — skeleton loaders, coral CTAs, staggered animations"
```

---

### Task 15: Standardize color usage across screens

**Files:**
- Modify: All screen files that use status colors, icon backgrounds, or text opacity

This task is a sweep across screens to enforce the three rules from the spec:

- [ ] **Step 1: Audit and fix status colors**

Search all screen files for status-related color usage. Standardize to:
- Completed: `context.primaryColor.withOpacity(0.15)` background + `context.primaryColor` text
- Active/in-progress: `context.coralColor.withOpacity(0.12)` background + `context.coralColor` text
- Scheduled: `context.mutedColor` background + `context.borderColor` border
- Missed: Keep existing orange

Key files to check: `calendar_screen.dart` (day cells), `workout_screen.dart` (status badges), `programs_screen.dart` (active badge), `home_screen.dart` (activity items).

- [ ] **Step 2: Standardize icon backgrounds**

Search for icon container patterns across screens. Replace with consistent pattern:
- Container size varies by context
- `borderRadius: AppRadius.borderLg` (10r)
- Background: `semanticColor.withOpacity(0.1)`
- Border: `semanticColor.withOpacity(0.15)`
- Teal for informational, coral for energy/action, destructive for errors

- [ ] **Step 3: Enforce text hierarchy**

Search for hardcoded opacity values on text. Replace with the three-level system:
- Primary text: `context.foreground` (no opacity)
- Secondary text: `context.mutedForeground` (no opacity)
- Tertiary text: `context.mutedForeground.withOpacity(0.6)`

Remove random opacity values like `.withOpacity(0.5)`, `.withOpacity(0.7)`, etc.

- [ ] **Step 4: Soften dividers**

Search for `Divider` widgets and hardcoded divider `Container`s. Replace with:
- Prefer 8r vertical spacing (no visible divider) where possible
- Where dividers are needed: `color: context.mutedForeground.withOpacity(0.15)`

- [ ] **Step 5: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: standardize status colors, icon backgrounds, text hierarchy, and dividers"
```

---

## Phase 4: Onboarding Overhaul

### Task 16: Consolidate onboarding screens — Goal+Experience, Style+Injury

**Files:**
- Modify: `lib/features/onboarding/presentation/onboarding_goal_screen.dart` (176 lines) — merge Experience into this
- Delete: `lib/features/onboarding/presentation/onboarding_experience_screen.dart` (192 lines)
- Modify: `lib/features/onboarding/presentation/onboarding_style_screen.dart` (192 lines) — merge Injury into this
- Delete: `lib/features/onboarding/presentation/onboarding_injury_screen.dart` (177 lines)

- [ ] **Step 1: Read all four screens**

Read goal, experience, style, and injury screens to understand their data collection, state management, and UI patterns.

- [ ] **Step 2: Merge Experience into Goal screen**

Update `onboarding_goal_screen.dart` to become the "Goal + Experience" screen:

- Title: "Tell us about yourself"
- Top section: Goal selection cards (single-select) — keep existing goal card grid
- Visual divider: `SizedBox(height: AppSpacing.sectionGap)` + a `SectionHeader(title: 'Experience Level')`
- Bottom section: Experience level cards (single-select) — bring the experience options from `onboarding_experience_screen.dart`
- Both selections stored via `onboardingProvider` using existing `setGoal()` and `setExperience()` methods
- Continue button enabled when BOTH goal and experience are selected
- Navigation: go to `/onboarding/style` (same as before, just skips experience)
- Apply new visual patterns: ScaleTap on selection cards, teal border+tint for selected state

- [ ] **Step 3: Merge Injury into Style screen**

Update `onboarding_style_screen.dart` to become the "Style + Injury" screen:

- Title: "Your training"
- Top section: Training style cards (single-select) — keep existing style cards
- Visual divider: `SizedBox(height: AppSpacing.sectionGap)` + `SectionHeader(title: 'Any injuries?')`
- Bottom section: Injury multi-select grid — bring from `onboarding_injury_screen.dart`
- Keep the 'None' exclusivity logic from injury screen
- Continue button enabled when style is selected AND at least one injury option (including 'None') is selected
- Navigation: go to `/onboarding/units-metrics` (new merged route)

- [ ] **Step 4: Add slide transitions and staggered animations**

For both merged screens, wrap content sections in `StaggeredList` and apply the onboarding content entry animation:
- Title slides up (100ms)
- Subtitle fades (100ms delay)
- Options stagger in (50ms each)

- [ ] **Step 5: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/presentation/onboarding_goal_screen.dart lib/features/onboarding/presentation/onboarding_style_screen.dart
git commit -m "feat: merge Goal+Experience and Style+Injury onboarding screens"
```

---

### Task 17: Consolidate onboarding — Body Metrics, Account, fix unit bugs

**Files:**
- Modify: `lib/features/onboarding/presentation/onboarding_height_screen.dart` (197 lines) — merge Units+Weight into this → rename to body metrics
- Delete: `lib/features/onboarding/presentation/onboarding_units_screen.dart` (197 lines)
- Delete: `lib/features/onboarding/presentation/onboarding_weight_screen.dart` (112 lines)
- Modify: `lib/features/onboarding/presentation/onboarding_email_screen.dart` (121 lines) — merge Notifications into this
- Delete: `lib/features/onboarding/presentation/onboarding_notifications_screen.dart` (121 lines)

- [ ] **Step 1: Read all five screens**

Read height, units, weight, email, and notifications screens.

- [ ] **Step 2: Create Body Metrics screen (merge Units+Height+Weight)**

Repurpose `onboarding_height_screen.dart` as the Body Metrics screen:

- Title: "Your body"
- Unit toggle (metric/imperial) positioned as a segmented control near the title. Uses `onboardingProvider.setUnits()`.
- Height picker section: Keep the existing `ListWheelScrollView` from height screen. Already respects units correctly.
- Weight picker section: Add below height. Bring `ListWheelScrollView` from weight screen BUT fix the unit display bug:
  - Current bug (weight_screen.dart line 62): hardcoded `'${_selectedWeight.round()} kg'`
  - Fix: Check `state.selectedUnits` — if imperial, display `'${(_selectedWeight * 2.20462).round()} lbs'`, if metric display `'${_selectedWeight.round()} kg'`
  - Weight range: 40-200 kg for metric, 88-440 lbs for imperial
- Continue button always enabled (height/weight have defaults)
- Navigation: go to `/onboarding/health`

- [ ] **Step 3: Create Account screen (merge Email+Notifications)**

Repurpose `onboarding_email_screen.dart` as the Account screen:

- Title: "Create your account"
- Email input: Keep existing with mail icon prefix
- Password input: Keep existing with lock icon + eye toggle
- Notifications card: Add below password. Bring the toggle card from notifications screen — "Allow notifications" with a `CustomToggle`. Uses `onboardingProvider.setNotificationsEnabled()`.
- Create Account button (enabled when email/password validate)
- Navigation: go to `/onboarding/summary`

- [ ] **Step 4: Fix unit display bug in Summary screen**

In `lib/features/onboarding/presentation/onboarding_summary_screen.dart`, fix line 70:

Current: `'${state.height.round()} cm • ${state.weight.round()} kg'`

Fix:
```dart
final isMetric = state.selectedUnits == 'metric';
final heightDisplay = isMetric
    ? '${state.height.round()} cm'
    : _cmToFeetInches(state.height);
final weightDisplay = isMetric
    ? '${state.weight.round()} kg'
    : '${(state.weight * 2.20462).round()} lbs';
// Then use: '$heightDisplay • $weightDisplay'
```

Add the `_cmToFeetInches` helper:
```dart
String _cmToFeetInches(double cm) {
  final totalInches = (cm / 2.54).round();
  final feet = totalInches ~/ 12;
  final inches = totalInches % 12;
  return "$feet'$inches\"";
}
```

- [ ] **Step 5: Apply visual improvements to all merged screens**

- ScaleTap on selection cards
- Teal border+tint for selected state
- StaggeredList for content sections
- Consistent spacing with AppSpacing tokens

- [ ] **Step 6: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/onboarding/presentation/
git commit -m "feat: merge Units+Height+Weight and Email+Notifications, fix unit display bugs"
```

---

### Task 18: Update onboarding progress bar, router, and cleanup

**Files:**
- Modify: `lib/shared/widgets/onboarding_progress_bar.dart` (77 lines)
- Modify: `lib/app/router.dart` (374 lines)
- Modify: `lib/features/onboarding/presentation/onboarding_welcome_screen.dart`
- Delete: `lib/features/onboarding/presentation/onboarding_experience_screen.dart`
- Delete: `lib/features/onboarding/presentation/onboarding_injury_screen.dart`
- Delete: `lib/features/onboarding/presentation/onboarding_units_screen.dart`
- Delete: `lib/features/onboarding/presentation/onboarding_weight_screen.dart`
- Delete: `lib/features/onboarding/presentation/onboarding_notifications_screen.dart`

- [ ] **Step 1: Update OnboardingProgressBar**

In `lib/shared/widgets/onboarding_progress_bar.dart`:

- Change default `totalSteps` from 14 to 9
- Update segment colors:
  - Completed steps: `context.primaryColor` (teal)
  - Current step: `context.coralColor` (coral — new!)
  - Upcoming steps: `context.mutedColor`
- Add animation: Wrap the segment width in `AnimatedContainer` with `duration: Duration(milliseconds: 250)` and `curve: Curves.easeOut`

- [ ] **Step 2: Update router — consolidate onboarding routes**

In `lib/app/router.dart`, update the onboarding routes section:

Remove routes for: `/onboarding/experience`, `/onboarding/injury`, `/onboarding/units`, `/onboarding/weight`, `/onboarding/notifications`

Update remaining routes to reflect the new 9-step flow:
1. `/onboarding` → Welcome (step 0, no progress bar)
2. `/onboarding/showcase` → Showcase (step 1)
3. `/onboarding/goal` → Goal+Experience (step 2)
4. `/onboarding/style` → Style+Injury (step 3)
5. `/onboarding/body-metrics` → Body Metrics (step 4) — new route path
6. `/onboarding/health` → Health (step 5)
7. `/onboarding/email` → Account (step 6)
8. `/onboarding/summary` → Summary (step 7)
9. `/onboarding/discovery` → Ready/Discovery (step 8)

Update each route's `pageBuilder` to use horizontal slide transition for the onboarding flow.

- [ ] **Step 3: Update Welcome screen hero header**

In `onboarding_welcome_screen.dart`, ensure it uses `GradientHeader(variant: HeaderVariant.hero)` or keeps its current full-gradient treatment (since it's a hero screen per spec). Update navigation from `/onboarding/goal` flow.

- [ ] **Step 4: Delete merged-away screen files**

```bash
git rm lib/features/onboarding/presentation/onboarding_experience_screen.dart
git rm lib/features/onboarding/presentation/onboarding_injury_screen.dart
git rm lib/features/onboarding/presentation/onboarding_units_screen.dart
git rm lib/features/onboarding/presentation/onboarding_weight_screen.dart
git rm lib/features/onboarding/presentation/onboarding_notifications_screen.dart
```

- [ ] **Step 5: Update all onboarding screen step numbers**

Each onboarding screen passes `currentStep` to `OnboardingProgressBar`. Update these to reflect the new 9-step numbering:
- Showcase: step 1
- Goal+Experience: step 2
- Style+Injury: step 3
- Body Metrics: step 4
- Health: step 5
- Account: step 6
- Summary: step 7
- Discovery/Ready: step 8

- [ ] **Step 6: Verify build and test full onboarding flow**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Test the complete onboarding flow from welcome through discovery. Verify:
- Progress bar shows 9 segments with correct colors
- Navigation between all 9 steps works
- Back button works on all steps
- Data persists correctly across steps

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: consolidate onboarding 14→9 steps, update router, progress bar, cleanup"
```

---

## Phase 5: Page Transitions & Final Polish

### Task 19: Add page transitions to GoRouter

**Files:**
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Read the current router transition setup**

Read `lib/app/router.dart` to understand current `pageBuilder` patterns and any existing transition code.

- [ ] **Step 2: Create a shared page transition helper**

Add at the top of `router.dart` (or in a new `lib/app/page_transitions.dart` file):

```dart
CustomTransitionPage<void> fadeTransitionPage({
  required Widget child,
  required GoRouterState state,
  Duration duration = const Duration(milliseconds: 200),
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> slideTransitionPage({
  required Widget child,
  required GoRouterState state,
  Duration duration = const Duration(milliseconds: 250),
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return SlideTransition(position: slide, child: child);
    },
  );
}

CustomTransitionPage<void> horizontalSlideTransitionPage({
  required Widget child,
  required GoRouterState state,
  Duration duration = const Duration(milliseconds: 250),
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return SlideTransition(
        position: slide,
        child: FadeTransition(opacity: fade, child: child),
      );
    },
  );
}
```

- [ ] **Step 3: Apply transitions to routes**

Update the `pageBuilder` for each route category:
- **Tab screens (in StatefulShellRoute):** Use `fadeTransitionPage` for cross-fade between tabs
- **Push screens (program detail, edit profile, settings, etc.):** Use `slideTransitionPage`
- **Onboarding steps:** Use `horizontalSlideTransitionPage`
- **Modals:** Keep default or use `MaterialPage` with standard slide-up

- [ ] **Step 4: Verify all navigation transitions**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Test: tab switching (should cross-fade), push navigation (should slide right), onboarding steps (should slide horizontally), back navigation (should reverse).

- [ ] **Step 5: Commit**

```bash
git add lib/app/router.dart
git commit -m "feat: add page transitions — fade tabs, slide push, horizontal onboarding"
```

---

### Task 20: Add micro-interactions

**Files:**
- Modify: `lib/features/workout/presentation/workout_screen.dart` (set completion highlight)
- Modify: `lib/shared/widgets/stats_grid.dart` (number count-up)
- Modify: `lib/shared/widgets/progress_bar_widget.dart` (animated fill)

- [ ] **Step 1: Add number count-up animation to StatsGrid**

In `lib/shared/widgets/stats_grid.dart`, wrap the value `Text` widget in an `AnimatedProgress` (or a `TweenAnimationBuilder`) that counts from 0 to the displayed value:

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: double.tryParse(item.value) ?? 0),
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeOut,
  builder: (context, value, _) {
    return Text(
      value.toStringAsFixed(0),
      style: AppTextStyles.h2(color: foreground),
    );
  },
)
```

Only apply count-up to numeric values. For non-numeric values (like "N/A"), display as-is.

- [ ] **Step 2: Add animated fill to ProgressBarWidget**

In `lib/shared/widgets/progress_bar_widget.dart`, wrap the inner fill container width in an `AnimatedContainer` or `TweenAnimationBuilder`:

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: value),
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeOut,
  builder: (context, animatedValue, _) {
    return FractionallySizedBox(
      widthFactor: animatedValue.clamp(0.0, 1.0),
      // ... existing gradient fill decoration
    );
  },
)
```

- [ ] **Step 3: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/stats_grid.dart lib/shared/widgets/progress_bar_widget.dart
git commit -m "feat: add micro-interactions — number count-up, animated progress fill"
```

---

### Task 21: Final consistency audit and safe area fixes

**Files:**
- Potentially modify: Any screen with spacing or safe area issues

- [ ] **Step 1: Audit bottom padding on all tab screens**

Check each tab screen (Home, Workout, Calendar, Programs, Profile) for proper bottom padding that accounts for:
- Bottom nav bar height
- Safe area inset
- No content cut-off

Ensure all use `MediaQuery.of(context).padding.bottom` or `SafeArea` at the bottom of scrollable content.

- [ ] **Step 2: Audit section gap consistency**

Scan all screens for section gaps. Every gap between major sections should use `AppSpacing.sectionGap` (24r). Fix any that use other values.

- [ ] **Step 3: Add scroll-aware header fade (if feasible)**

The spec mentions headers should fade from tint to full background on scroll. If the current screen structure allows it, wrap the header in a `SliverAppBar`-style widget or use a `NotificationListener<ScrollNotification>` to adjust the header tint opacity based on scroll offset. If this adds too much complexity to individual screens, skip for v1 — the subtle tint alone is a big improvement.

- [ ] **Step 4: Audit card padding consistency**

Scan all screens for card padding. Default card padding should be `AppSpacing.cardPadding` (16r). Fix any that use non-standard values without a clear reason.

- [ ] **Step 4: Verify build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "fix: final consistency audit — safe areas, section gaps, card padding"
```

---

### Task 22: Visual QA — both themes

- [ ] **Step 1: Test dark mode end-to-end**

Run the app in dark mode. Navigate through every screen:
1. Home — verify subtle header, coral streak badge, card variants, staggered animations
2. Workout — verify workout cards have teal accent bar, proper spacing
3. Calendar — verify status colors on day cells, streak stats
4. Programs — verify create CTA uses coral, program cards show progress
5. Profile — verify avatar header, menu sections, subscription card
6. Program Detail — verify subtle header with back button
7. Edit Profile — verify form spacing
8. Paywall — verify hero gradient header
9. Full onboarding flow (9 steps) — verify transitions, progress bar colors, merged screens, unit display

- [ ] **Step 2: Test light mode end-to-end**

Repeat the same flow in light mode. Verify:
- Subtle header tint is visible but not overpowering
- Coral accent is vibrant enough on light backgrounds
- Card borders are visible
- Text hierarchy (3 levels) is clear

- [ ] **Step 3: Fix any visual issues found**

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "fix: visual QA fixes for light and dark mode"
```

---

## File Structure Summary

### New Files
| File | Purpose |
|------|---------|
| `lib/shared/widgets/fade_in.dart` | FadeIn animation widget |
| `lib/shared/widgets/slide_up.dart` | SlideUp animation widget |
| `lib/shared/widgets/scale_tap.dart` | ScaleTap press feedback widget |
| `lib/shared/widgets/staggered_list.dart` | Staggered list animation widget |
| `lib/shared/widgets/animated_progress.dart` | Animated progress builder widget |
| `lib/shared/widgets/skeleton_loader.dart` | Skeleton loader with shimmer |

### Modified Files
| File | Changes |
|------|---------|
| `lib/theme/app_colors.dart` | Add coral colors |
| `lib/shared/utils/extensions.dart` | Add coral getters |
| `lib/shared/widgets/gradient_header.dart` | Add HeaderVariant (subtle/hero) |
| `lib/shared/widgets/custom_card.dart` | Add CardVariant enum |
| `lib/shared/widgets/custom_scaffold.dart` | Bottom nav polish |
| `lib/shared/widgets/empty_state_widget.dart` | Redesign with animations |
| `lib/shared/widgets/async_value_widget.dart` | Skeleton loaders, better errors |
| `lib/shared/widgets/onboarding_progress_bar.dart` | 9 steps, coral current, animated |
| `lib/shared/widgets/stats_grid.dart` | Number count-up animation |
| `lib/shared/widgets/progress_bar_widget.dart` | Animated fill |
| `lib/app/router.dart` | Page transitions, onboarding route consolidation |
| `lib/features/home/presentation/home_screen.dart` | Unified template |
| `lib/features/workout/presentation/workout_screen.dart` | Unified template |
| `lib/features/calendar/presentation/calendar_screen.dart` | Unified template |
| `lib/features/programs/presentation/programs_screen.dart` | Unified template |
| `lib/features/profile/presentation/profile_screen.dart` | Unified template |
| `lib/features/programs/presentation/program_detail_screen.dart` | Unified template |
| `lib/features/profile/presentation/edit_profile_screen.dart` | Unified template |
| `lib/features/subscription/presentation/paywall_screen.dart` | Hero header variant |
| `lib/features/onboarding/presentation/onboarding_goal_screen.dart` | Merge with Experience |
| `lib/features/onboarding/presentation/onboarding_style_screen.dart` | Merge with Injury |
| `lib/features/onboarding/presentation/onboarding_height_screen.dart` | Merge into Body Metrics |
| `lib/features/onboarding/presentation/onboarding_email_screen.dart` | Merge with Notifications |
| `lib/features/onboarding/presentation/onboarding_summary_screen.dart` | Fix unit display |
| `lib/features/onboarding/presentation/onboarding_welcome_screen.dart` | Hero header |

### Deleted Files
| File | Reason |
|------|--------|
| `lib/features/onboarding/presentation/onboarding_experience_screen.dart` | Merged into Goal |
| `lib/features/onboarding/presentation/onboarding_injury_screen.dart` | Merged into Style |
| `lib/features/onboarding/presentation/onboarding_units_screen.dart` | Merged into Body Metrics |
| `lib/features/onboarding/presentation/onboarding_weight_screen.dart` | Merged into Body Metrics |
| `lib/features/onboarding/presentation/onboarding_notifications_screen.dart` | Merged into Account |
