import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SlideUp extends StatefulWidget {
  final Duration duration;
  final Duration delay;
  final double offset;
  final Widget child;

  const SlideUp({
    super.key,
    this.duration = const Duration(milliseconds: 200),
    this.delay = Duration.zero,
    this.offset = 16,
    required this.child,
  });

  @override
  State<SlideUp> createState() => _SlideUpState();
}

class _SlideUpState extends State<SlideUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _opacity = curved;
    _translation = Tween<double>(begin: 1.0, end: 0.0).animate(curved);

    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
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
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translation.value * widget.offset.r),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
