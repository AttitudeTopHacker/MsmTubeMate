import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/app_constants.dart';
import '../../../config/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/file_utils.dart';
import '../../widgets/glass/ambient_background.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';
import '../splash/splash_screen.dart';
import 'status_saver_screen.dart';
import 'vault_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  int _cacheSizeInBytes = 0;
  bool _isCleaningCache = false;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      if (await tempDir.exists()) {
        final entities = tempDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        }
      }
      if (mounted) {
        setState(() => _cacheSizeInBytes = totalSize);
      }
    } catch (_) {}
  }

  Future<void> _cleanCache() async {
    setState(() => _isCleaningCache = true);
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final entities = tempDir.listSync(recursive: false);
        for (final entity in entities) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (_) {}
        }
      }
      await _calculateCacheSize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.accentCyan,
            content: Text(
              'App cache cleared successfully!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isCleaningCache = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              // Header
              const Text(
                'Tools & Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Optimize device storage, WhatsApp statuses and private vault',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Storage & Cache Overview Card
              GlassContainer(
                padding: const EdgeInsets.all(18),
                borderRadius: 20,
                opacity: 0.12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cleaning_services_rounded, color: AppTheme.accentCyan, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Cache Cleaner',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        GlassButton(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          onPressed: _isCleaningCache ? null : _cleanCache,
                          child: _isCleaningCache
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Clean Cache',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'Temporary Cache',
                            FileUtils.formatBytes(_cacheSizeInBytes),
                            Icons.memory_rounded,
                            AppTheme.accentCyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            'Engine Status',
                            'FastAPI + Dart',
                            Icons.speed_rounded,
                            AppTheme.accentViolet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tools Grid: WhatsApp Status Saver & Private Vault
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Status Saver',
                      subtitle: 'WhatsApp & Business',
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: const Color(0xFF25D366),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StatusSaverScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Private Vault',
                      subtitle: '4-Digit PIN Lock',
                      icon: Icons.lock_outline_rounded,
                      iconColor: Colors.amberAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VaultScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // User Account Card
              GlassContainer(
                padding: const EdgeInsets.all(18),
                borderRadius: 20,
                opacity: 0.12,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.2),
                      child: Icon(
                        user != null ? Icons.person_rounded : Icons.person_outline_rounded,
                        color: AppTheme.accentCyan,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email ?? 'Guest User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user != null ? 'Synced with Supabase Cloud' : 'Local only mode',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (user != null) {
                          await authService.signOut();
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SplashScreen()),
                          );
                        }
                      },
                      child: Text(
                        user != null ? 'Sign Out' : 'Sign In',
                        style: const TextStyle(
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Settings Options
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 8),
                borderRadius: 20,
                opacity: 0.12,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.share_rounded, color: AppTheme.accentCyan),
                      title: const Text('Share App', style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text('Share Msm TubeMate with friends', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      onTap: () {
                        Share.share('Check out Msm TubeMate - Next-gen 4K media downloader & audio extractor! ORG: msm.movin 2022');
                      },
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    ListTile(
                      leading: const Icon(Icons.folder_outlined, color: AppTheme.accentBlue),
                      title: const Text('Download Location', style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text('Internal Storage / Download / MsmTubeMate', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // MANDATORY Legal & About Section
              const GlassContainer(
                padding: EdgeInsets.all(18),
                borderRadius: 20,
                opacity: 0.12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.accentCyan, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'About Msm TubeMate',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Application Name', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text(AppConstants.appName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Version', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text('2.0.0 (Release Build)', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Organization & License', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        // MANDATORY EXACT PRD COPYRIGHT STRING: ORG: msm.movin 2022
                        Text(
                          AppConstants.copyright,
                          style: TextStyle(
                            color: AppTheme.accentCyan,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Footer Copyright String
              const Center(
                child: Text(
                  AppConstants.copyright,
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        opacity: 0.12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
