import 'package:flutter/material.dart';

/// Generic animated value widget.
///
/// Use [AnimatedProgress] when you need full control over how the animated
/// value is rendered — the [builder] callback receives the interpolated double
/// each frame so the caller can produce any widget (e.g. a text counter, a
/// custom painter, or a sized box).
///
/// Use [ProgressBarWidget] instead when you just want a standard horizontal
/// fill bar with the app gradient and built-in semantics.
class AnimatedProgress extends StatefulWidget {
  final double value;
  final Duration duration;
  final Widget Function(BuildContext context, double animatedValue) builder;

  const AnimatedProgress({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 250),
    required this.builder,
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
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final currentValue = _animation.value;
      _animation = Tween<double>(begin: currentValue, end: widget.value)
          .animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
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
