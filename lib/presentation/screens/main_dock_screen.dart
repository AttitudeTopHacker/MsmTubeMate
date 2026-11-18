import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../core/services/download_service.dart';
import '../../core/services/share_service.dart';
import '../widgets/format_bottom_sheet.dart';
import '../widgets/glass/ambient_background.dart';
import 'downloads/downloads_screen.dart';
import 'explore/explore_screen.dart';
import 'tools/tools_screen.dart';

class MainDockScreen extends StatefulWidget {
  const MainDockScreen({super.key});

  @override
  State<MainDockScreen> createState() => _MainDockScreenState();
}

class _MainDockScreenState extends State<MainDockScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShareService.initialize(
        onUrlReceived: (sharedUrl) {
          debugPrint('[MainDock] Received Shared URL: $sharedUrl');
          FormatBottomSheet.show(context, sharedUrl);
        },
      );
    });
  }

  @override
  void dispose() {
    ShareService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeDownloadsCount =
        context.watch<DownloadService>().activeTasks.length;

    final List<Widget> screens = [
      ExploreScreen(onNavigateTab: (idx) => setState(() => _selectedTabIndex = idx)),
      const DownloadsScreen(),
      const ToolsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundMidnight,
      extendBody: true,
      body: AmbientBackground(
        child: IndexedStack(
          index: _selectedTabIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  color: const Color(0xFF101625).withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: -4,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDockItem(
                      index: 0,
                      label: 'Explore',
                      icon: Icons.explore_rounded,
                    ),
                    _buildDockItem(
                      index: 1,
                      label: 'Downloads',
                      icon: Icons.download_rounded,
                      badgeCount: activeDownloadsCount,
                    ),
                    _buildDockItem(
                      index: 2,
                      label: 'Tools',
                      icon: Icons.grid_view_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required int index,
    required String label,
    required IconData icon,
    int badgeCount = 0,
  }) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? AppTheme.accentCyan.withValues(alpha: 0.16)
              : Colors.transparent,
          border: isSelected
              ? Border.all(
                  color: AppTheme.accentCyan.withValues(alpha: 0.45),
                  width: 1.0,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.accentBlue,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
