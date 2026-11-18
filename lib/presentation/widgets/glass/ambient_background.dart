import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundMidnight,
            AppTheme.backgroundNavy,
            AppTheme.backgroundDeepPurple,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Ambient Radial Orb 1: Electric Cyan (Top-Left)
          Positioned(
            top: -90,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.orbCyan.withValues(alpha: 0.24),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Ambient Radial Orb 2: Neon Violet (Center-Right)
          Positioned(
            top: 260,
            right: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.orbViolet.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Ambient Radial Orb 3: Azure Blue (Bottom-Left)
          Positioned(
            bottom: 60,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.orbBlue.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Blur filter over orbs for seamless organic luminescence
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: const SizedBox.expand(),
            ),
          ),

          // Main child content
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
