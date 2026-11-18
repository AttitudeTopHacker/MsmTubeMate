import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/download_service.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/url_utils.dart';
import '../../data/models/media_item.dart';
import 'glass/glass_button.dart';
import 'glass/glass_container.dart';
import 'playlist_batch_sheet.dart';

class FormatBottomSheet extends StatefulWidget {
  final String url;

  const FormatBottomSheet({super.key, required this.url});

  static Future<void> show(BuildContext context, String url) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FormatBottomSheet(url: url),
    );
  }

  @override
  State<FormatBottomSheet> createState() => _FormatBottomSheetState();
}

class _FormatBottomSheetState extends State<FormatBottomSheet> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  MediaInfo? _media;
  MediaFormat? _selectedFormat;

  bool _expandMoreMusic = false;
  bool _expandMoreVideo = false;

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _fetchMedia() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final info = await _api.extract(widget.url);
      if (!mounted) return;

      if (info.isPlaylist) {
        Navigator.pop(context);
        PlaylistBatchSheet.show(context, info);
        return;
      }

      setState(() {
        _media = info;
        _isLoading = false;
        // Default select best quality video or first audio
        if (info.videoFormats.isNotEmpty) {
          _selectedFormat = info.videoFormats.first;
        } else if (info.audioFormats.isNotEmpty) {
          _selectedFormat = info.audioFormats.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onDownloadPressed() {
    if (_media == null || _selectedFormat == null) return;

    final downloadService = context.read<DownloadService>();
    downloadService.startDownload(
      media: _media!,
      format: _selectedFormat!,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.downloading_rounded, color: AppTheme.accentCyan),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Downloading: ${_media!.title} (${_selectedFormat!.label})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF131A2B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = UrlUtils.detectPlatform(widget.url);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: GlassContainer(
        borderRadius: 28,
        blur: 24,
        padding: const EdgeInsets.all(18),
        tintColor: const Color(0xFF131A2B),
        opacity: 0.88,
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

            // Platform Badge & Close Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: platform.brandColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: platform.brandColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(platform.icon, color: platform.brandColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        platform.displayName,
                        style: TextStyle(
                          color: platform.brandColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const Divider(color: Colors.white10),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildFormatList(),
            ),

            // Download Trigger CTA
            if (!_isLoading && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GlassButton(
                  isPrimary: true,
                  height: 52,
                  onPressed: _selectedFormat != null ? _onDownloadPressed : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.download_rounded,
                          color: Color(0xFF090D16), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _selectedFormat != null
                            ? 'Download ${_selectedFormat!.label}'
                            : 'Select a Format',
                        style: const TextStyle(
                          color: Color(0xFF090D16),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
            strokeWidth: 3,
          ),
          SizedBox(height: 18),
          Text(
            'Extracting formats & stream links...',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 44),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Failed to retrieve media.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 16),
            GlassButton(
              onPressed: _fetchMedia,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatList() {
    final media = _media!;
    final audioList = media.audioFormats;
    final videoList = media.videoFormats;

    // Split for "More formats >" expandable drawer
    final primaryMusic = audioList.take(2).toList();
    final moreMusic = audioList.skip(2).toList();

    final primaryVideo = videoList.take(2).toList();
    final moreVideo = videoList.skip(2).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Thumbnail Preview
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 100,
                    height: 68,
                    child: media.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: media.thumbnailUrl,
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
                        media.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${media.author} • ${FileUtils.formatDuration(media.duration)}',
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
          ),

          const SizedBox(height: 16),

          // 1. Music Section
          _buildSectionHeader('Music (Audio)', Icons.music_note_rounded, AppTheme.accentCyan),
          const SizedBox(height: 8),
          ...primaryMusic.map((f) => _buildFormatTile(f)),

          if (moreMusic.isNotEmpty) ...[
            if (_expandMoreMusic)
              ...moreMusic.map((f) => _buildFormatTile(f)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _expandMoreMusic = !_expandMoreMusic),
                child: Text(
                  _expandMoreMusic ? 'Fewer formats <' : 'More formats >',
                  style: const TextStyle(color: AppTheme.accentCyan, fontSize: 12),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 2. Video Section
          _buildSectionHeader('Video', Icons.videocam_rounded, AppTheme.accentBlue),
          const SizedBox(height: 8),
          ...primaryVideo.map((f) => _buildFormatTile(f)),

          if (moreVideo.isNotEmpty) ...[
            if (_expandMoreVideo)
              ...moreVideo.map((f) => _buildFormatTile(f)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _expandMoreVideo = !_expandMoreVideo),
                child: Text(
                  _expandMoreVideo ? 'Fewer formats <' : 'More formats >',
                  style: const TextStyle(color: AppTheme.accentBlue, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFormatTile(MediaFormat format) {
    final isSelected = _selectedFormat?.id == format.id;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 14,
      opacity: isSelected ? 0.22 : 0.08,
      customBorder: Border.all(
        color: isSelected
            ? AppTheme.accentCyan
            : Colors.white.withValues(alpha: 0.12),
        width: isSelected ? 1.6 : 1.0,
      ),
      onTap: () => setState(() => _selectedFormat = format),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                format.isAudio ? Icons.audiotrack_rounded : Icons.videocam_rounded,
                color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (format.note != null)
                    Text(
                      format.note!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                format.sizeApprox,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? AppTheme.accentCyan : Colors.white24,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
