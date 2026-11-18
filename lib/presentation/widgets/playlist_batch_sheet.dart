import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../core/services/download_service.dart';
import '../../core/utils/file_utils.dart';
import '../../data/models/media_item.dart';
import 'glass/glass_button.dart';
import 'glass/glass_container.dart';

class PlaylistBatchSheet extends StatefulWidget {
  final MediaInfo playlist;

  const PlaylistBatchSheet({super.key, required this.playlist});

  static Future<void> show(BuildContext context, MediaInfo playlist) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaylistBatchSheet(playlist: playlist),
    );
  }

  @override
  State<PlaylistBatchSheet> createState() => _PlaylistBatchSheetState();
}

class _PlaylistBatchSheetState extends State<PlaylistBatchSheet> {
  bool _downloadAsAudio = false;

  void _toggleSelectAll(bool select) {
    setState(() {
      for (final item in widget.playlist.playlistEntries) {
        item.isSelected = select;
      }
    });
  }

  void _startBatchDownload() {
    final selected = widget.playlist.playlistEntries.where((e) => e.isSelected).toList();
    if (selected.isEmpty) return;

    final downloadService = context.read<DownloadService>();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Queued ${selected.length} items for download'),
        backgroundColor: AppTheme.accentBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );

    for (final item in selected) {
      final dummyMedia = MediaInfo(
        id: item.id,
        title: item.title,
        author: widget.playlist.author,
        duration: item.duration,
        thumbnailUrl: item.thumbnailUrl,
        webpageUrl: item.url,
      );

      final format = _downloadAsAudio
          ? MediaFormat(
              id: 'audio_mp3_128k',
              label: 'Classic MP3 (128K)',
              extension: 'mp3',
              category: 'music',
              sizeApprox: '~5 MB',
            )
          : MediaFormat(
              id: 'video_720p',
              label: '720p HD',
              extension: 'mp4',
              category: 'video',
              sizeApprox: '~30 MB',
            );

      downloadService.startDownload(media: dummyMedia, format: format);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.playlist.playlistEntries;
    final selectedCount = entries.where((e) => e.isSelected).length;
    final allSelected = selectedCount == entries.length && entries.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: GlassContainer(
        borderRadius: 28,
        blur: 24,
        padding: const EdgeInsets.all(18),
        tintColor: const Color(0xFF131A2B),
        opacity: 0.85,
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.playlist.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.playlist.author} • ${entries.length} Tracks',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Select All & Format Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _toggleSelectAll(!allSelected),
                  icon: Icon(
                    allSelected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: AppTheme.accentCyan,
                    size: 20,
                  ),
                  label: Text(
                    'Select All ($selectedCount/${entries.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Video HD'),
                      selected: !_downloadAsAudio,
                      selectedColor: AppTheme.accentBlue,
                      onSelected: (_) => setState(() => _downloadAsAudio = false),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Audio MP3'),
                      selected: _downloadAsAudio,
                      selectedColor: AppTheme.accentCyan,
                      onSelected: (_) => setState(() => _downloadAsAudio = true),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(color: Colors.white10),

            // Track list
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final item = entries[index];
                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    borderRadius: 14,
                    onTap: () {
                      setState(() => item.isSelected = !item.isSelected);
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.isSelected,
                          activeColor: AppTheme.accentCyan,
                          onChanged: (val) {
                            setState(() => item.isSelected = val ?? false);
                          },
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 58,
                            height: 42,
                            child: item.thumbnailUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: item.thumbnailUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: Colors.black26),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                FileUtils.formatDuration(item.duration),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom CTA
            if (selectedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GlassButton(
                  isPrimary: true,
                  height: 52,
                  onPressed: _startBatchDownload,
                  child: Text(
                    'Download ($selectedCount)',
                    style: const TextStyle(
                      color: Color(0xFF090D16),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
