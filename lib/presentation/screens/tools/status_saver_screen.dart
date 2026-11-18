import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../../config/theme.dart';
import '../../../core/services/status_service.dart';
import '../../../core/utils/file_utils.dart';
import '../../../data/models/status_item.dart';
import '../../widgets/glass/ambient_background.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';

class StatusSaverScreen extends StatefulWidget {
  const StatusSaverScreen({super.key});

  @override
  State<StatusSaverScreen> createState() => _StatusSaverScreenState();
}

class _StatusSaverScreenState extends State<StatusSaverScreen> {
  bool _isLoading = true;
  List<WhatsAppStatus> _allStatuses = [];
  String _filter = 'All'; // All, Images, Videos

  @override
  void initState() {
    super.initState();
    _fetchStatuses();
  }

  Future<void> _fetchStatuses() async {
    setState(() => _isLoading = true);
    final results = await StatusService.loadStatuses();
    if (mounted) {
      setState(() {
        _allStatuses = results;
        _isLoading = false;
      });
    }
  }

  List<WhatsAppStatus> get _filteredStatuses {
    if (_filter == 'Images') {
      return _allStatuses.where((s) => !s.isVideo).toList();
    } else if (_filter == 'Videos') {
      return _allStatuses.where((s) => s.isVideo).toList();
    }
    return _allStatuses;
  }

  Future<void> _save(WhatsAppStatus status) async {
    final dest = await StatusService.saveStatus(status);
    if (!mounted) return;
    if (dest != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.9),
          content: Text(
            'Saved to gallery: ${status.fileName}',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Failed to save status file'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMidnight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'WhatsApp Status Saver',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.accentCyan),
            onPressed: _fetchStatuses,
          ),
        ],
      ),
      body: AmbientBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Images'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Videos'),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppTheme.accentCyan),
                      ),
                    )
                  : _filteredStatuses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 56,
                                color: AppTheme.textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No WhatsApp statuses detected',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Open WhatsApp, view recent statuses,\nthen return here to save them.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _filteredStatuses.length,
                          itemBuilder: (context, index) {
                            final item = _filteredStatuses[index];
                            return _buildStatusCard(item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 20,
        opacity: isSelected ? 0.25 : 0.08,
        customBorder: isSelected
            ? Border.all(color: AppTheme.accentCyan, width: 1.2)
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(WhatsAppStatus item) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      opacity: 0.12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Preview Image or Icon
            if (!item.isVideo && File(item.path).existsSync())
              Image.file(
                File(item.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.white24),
                ),
              )
            else
              Container(
                color: Colors.black26,
                child: Center(
                  child: Icon(
                    item.isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                    size: 48,
                    color: AppTheme.accentCyan.withValues(alpha: 0.6),
                  ),
                ),
              ),

            // Top Badges
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  FileUtils.formatBytes(item.sizeInBytes),
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ),

            if (item.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white70,
                  size: 40,
                ),
              ),

            // Bottom Actions Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_rounded, color: Colors.white70, size: 20),
                      onPressed: () => OpenFilex.open(item.path),
                    ),
                    GlassButton(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      onPressed: () => _save(item),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Save',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
