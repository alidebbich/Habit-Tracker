import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.opacity = 0.05,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultRadius = BorderRadius.circular(20);
    
    final inner = ClipRRect(
      borderRadius: borderRadius ?? defaultRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: borderRadius ?? defaultRadius,
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Padding(
        padding: margin,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius as BorderRadius? ?? defaultRadius,
          child: inner,
        ),
      );
    }

    return Padding(
      padding: margin,
      child: inner,
    );
  }
}
