import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../utils/extensions.dart';

enum CardVariant { standard, workout, program, stat, actionCta }

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final CardVariant variant;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.borderRadius,
    this.boxShadow,
    this.border,
    this.variant = CardVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.borderXl;
    final effectivePadding = padding ?? EdgeInsets.all(16.r);

    // Resolve background color based on variant (explicit backgroundColor wins)
    Color? resolvedBgColor;
    if (gradient == null) {
      if (backgroundColor != null) {
        resolvedBgColor = backgroundColor;
      } else if (variant == CardVariant.actionCta) {
        resolvedBgColor = context.coralColor.withOpacity(0.08);
      } else {
        resolvedBgColor = context.cardColor;
      }
    }

    // Resolve border based on variant (explicit border wins)
    Border resolvedBorder;
    if (border != null) {
      resolvedBorder = border!;
    } else if (variant == CardVariant.workout) {
      resolvedBorder = Border.all(
        color: context.primaryColor.withOpacity(0.25),
      );
    } else if (variant == CardVariant.actionCta) {
      resolvedBorder = Border.all(
        color: context.coralColor.withOpacity(0.2),
      );
    } else {
      resolvedBorder = Border.all(
        color: context.borderColor,
      );
    }

    // For workout variant, add extra left padding for accent bar
    final contentPadding = variant == CardVariant.workout
        ? effectivePadding.add(EdgeInsets.only(left: 8.r))
        : effectivePadding;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: resolvedBgColor,
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: resolvedBorder,
        boxShadow: boxShadow ?? AppShadows.md,
      ),
      child: Semantics(
        button: onTap != null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: effectiveRadius,
            child: variant == CardVariant.workout
                ? ClipRRect(
                    borderRadius: effectiveRadius,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            color: context.primaryColor,
                          ),
                        ),
                        Padding(
                          padding: contentPadding,
                          child: child,
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: contentPadding,
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }
}
