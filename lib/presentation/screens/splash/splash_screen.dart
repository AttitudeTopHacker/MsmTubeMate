import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_constants.dart';
import '../../../config/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../widgets/glass/ambient_background.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';
import '../main_dock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isSigningIn = false;

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainDockScreen()),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isSigningIn = true);
    final auth = context.read<AuthService>();
    final success = await auth.signInWithGoogle();
    setState(() => _isSigningIn = false);

    if (success) {
      _navigateToMain();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In canceled or failed')),
      );
    }
  }

  void _handleContinueAsGuest() {
    final auth = context.read<AuthService>();
    auth.continueAsGuest();
    _navigateToMain();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMidnight,
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 20),

                // Center Emblem & Title
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassContainer(
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(28),
                      borderRadius: 999,
                      blur: 24,
                      opacity: 0.16,
                      customBorder: Border.all(
                        color: AppTheme.accentCyan.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentCyan.withValues(alpha: 0.45),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 54,
                          color: Color(0xFF090D16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Smart Multi-Platform Discovery & Downloader',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),

                // Auth Action Controls
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassButton(
                      isPrimary: true,
                      height: 52,
                      width: double.infinity,
                      onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                      child: _isSigningIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF090D16)),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_circle_rounded,
                                    color: Color(0xFF090D16)),
                                SizedBox(width: 10),
                                Text(
                                  'Sign in with Google',
                                  style: TextStyle(
                                    color: Color(0xFF090D16),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _handleContinueAsGuest,
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: AppTheme.accentCyan,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // MANDATORY PRD Copyright Notice (Case-sensitive & exact)
                    const Text(
                      AppConstants.copyright,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
