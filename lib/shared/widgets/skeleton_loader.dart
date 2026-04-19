import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_radius.dart';
import '../utils/extensions.dart';

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
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = context.mutedColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                baseColor.withOpacity(0.5),
                baseColor.withOpacity(1.0),
                baseColor.withOpacity(0.5),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

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
