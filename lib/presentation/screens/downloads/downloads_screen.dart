import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme.dart';
import '../../../core/services/download_service.dart';
import '../../../core/services/vault_service.dart';
import '../../../core/utils/file_utils.dart';
import '../../../data/models/download_task.dart';
import '../../widgets/glass/glass_container.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _offlineFilter = 'all'; // all, video, music

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = context.watch<DownloadService>();
    final active = downloadService.activeTasks;
    final completed = downloadService.completedTasks;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Glass Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Downloads',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (active.isNotEmpty)
                    GlassContainer(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${active.length} Downloading',
                            style: const TextStyle(
                              color: AppTheme.accentCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Segmented Glass Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: const Color(0xFF090D16),
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: [
                    Tab(
                      child: Text(
                        'Downloading (${active.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Downloaded (${completed.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Active Downloads Queue
                  active.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.download_done_rounded,
                          title: 'No Active Downloads',
                          subtitle: 'Download videos or audio from YouTube, Insta, or X.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                          itemCount: active.length,
                          itemBuilder: (context, index) {
                            return _buildActiveTaskCard(active[index]);
                          },
                        ),

                  // 2. Downloaded Completed Media
                  Column(
                    children: [
                      // Filter row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            _buildFilterChip('All', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Videos', 'video'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Music', 'music'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: completed.isEmpty
                            ? _buildEmptyState(
                                icon: Icons.video_library_outlined,
                                title: 'No Completed Files Yet',
                                subtitle: 'Your downloaded 4K/HD videos and MP3s will show up here.',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                                itemCount: _getFilteredCompleted(completed).length,
                                itemBuilder: (context, index) {
                                  final task = _getFilteredCompleted(completed)[index];
                                  return _buildCompletedCard(task);
                                },
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DownloadTask> _getFilteredCompleted(List<DownloadTask> list) {
    if (_offlineFilter == 'video') {
      return list.where((t) => !t.isAudio).toList();
    } else if (_offlineFilter == 'music') {
      return list.where((t) => t.isAudio).toList();
    }
    return list;
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _offlineFilter == value;
    return GlassContainer(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      opacity: isSelected ? 0.22 : 0.08,
      customBorder: Border.all(
        color: isSelected ? AppTheme.accentCyan : Colors.white12,
      ),
      onTap: () => setState(() => _offlineFilter = value),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActiveTaskCard(DownloadTask task) {
    final manager = context.read<DownloadService>();
    final isPaused = task.status == TaskStatus.paused;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 74,
                  height: 54,
                  child: task.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: task.thumbnailUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.black26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${task.platform} • ${task.formatLabel}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isPaused
                      ? Icons.play_circle_fill_rounded
                      : Icons.pause_circle_filled_rounded,
                  color: AppTheme.accentCyan,
                  size: 30,
                ),
                onPressed: () {
                  if (isPaused) {
                    manager.resume(task.id);
                  } else {
                    manager.pause(task.id);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: task.progress,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${FileUtils.formatBytes(task.downloadedBytes)} / ${task.totalBytes > 0 ? FileUtils.formatBytes(task.totalBytes) : 'Unknown'}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              Text(
                task.speedBytesPerSec > 0
                    ? '${FileUtils.formatBytes(task.speedBytesPerSec.toInt())}/s'
                    : task.statusLabel,
                style: const TextStyle(
                  color: AppTheme.accentCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(DownloadTask task) {
    final manager = context.read<DownloadService>();
    final vault = context.read<VaultService>();

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      onTap: () {
        if (task.destinationPath.isNotEmpty) {
          OpenFilex.open(task.destinationPath);
        }
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isAudio
                  ? AppTheme.accentCyan.withValues(alpha: 0.18)
                  : AppTheme.accentBlue.withValues(alpha: 0.18),
            ),
            child: Icon(
              task.isAudio ? Icons.music_note_rounded : Icons.videocam_rounded,
              color: task.isAudio ? AppTheme.accentCyan : AppTheme.accentBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${task.platform} • ${task.formatLabel}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
            color: const Color(0xFF131A2B),
            onSelected: (val) async {
              if (val == 'play') {
                if (task.destinationPath.isNotEmpty) {
                  OpenFilex.open(task.destinationPath);
                }
              } else if (val == 'share') {
                if (task.destinationPath.isNotEmpty) {
                  Share.shareXFiles([XFile(task.destinationPath)], text: task.title);
                }
              } else if (val == 'vault') {
                if (task.destinationPath.isNotEmpty) {
                  final moved = await vault.moveToVault(task.destinationPath);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(moved
                          ? 'Moved to Private Vault'
                          : 'Set up PIN in Tools tab first'),
                    ),
                  );
                }
              } else if (val == 'delete') {
                manager.remove(task.id, deleteFile: true);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'play',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow_rounded, color: AppTheme.accentCyan),
                    SizedBox(width: 8),
                    Text('Play Media'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'vault',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: AppTheme.orbViolet),
                    SizedBox(width: 8),
                    Text('Move to Vault'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassContainer(
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(22),
              borderRadius: 999,
              child: Icon(icon, size: 48, color: AppTheme.accentCyan),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
