import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double borderRadius;
  final Gradient? backgroundGradient;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double height;
  final bool isPrimary;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 16,
    this.backgroundGradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.width,
    this.height = 50,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppTheme.accentCyan.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(borderRadius),
              splashColor: AppTheme.accentCyan.withValues(alpha: 0.25),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: backgroundGradient ??
                      (isPrimary
                          ? AppTheme.primaryGradient
                          : LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.12),
                                Colors.white.withValues(alpha: 0.04),
                              ],
                            )),
                  border: Border.all(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.18),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
