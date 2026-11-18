import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../../config/app_constants.dart';
import '../../data/models/media_item.dart';
import '../utils/file_utils.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.defaultBackendUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 25),
    ),
  );

  final yt.YoutubeExplode _ytExplode = yt.YoutubeExplode();

  /// Search media via Python backend, with local YouTube fallback
  Future<List<Map<String, dynamic>>> search(String query) async {
    try {
      final res = await _dio.get('/api/search', queryParameters: {'q': query});
      if (res.statusCode == 200 && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['results']);
      }
    } catch (e) {
      debugPrint('[ApiService] Python backend search failed, using Dart fallback: $e');
    }

    // Fallback: search YouTube directly via Dart
    try {
      final searchList = await _ytExplode.search.search(query);
      return searchList.map((video) {
        return {
          'id': video.id.value,
          'title': video.title,
          'channel': video.author,
          'duration': video.duration?.inSeconds ?? 0,
          'view_count': 0,
          'thumbnail': video.thumbnails.highResUrl,
          'webpage_url': video.url,
        };
      }).toList();
    } catch (e) {
      debugPrint('[ApiService] Dart search fallback error: $e');
      return [];
    }
  }

  /// Extracts media formats (Audio + Video) and Playlist information
  Future<MediaInfo> extract(String url) async {
    // 1. Try Python FastAPI backend
    try {
      final res = await _dio.post('/api/extract', data: jsonEncode({'url': url}));
      if (res.statusCode == 200 && res.data['success'] == true) {
        return MediaInfo.fromJson(res.data);
      }
    } catch (e) {
      debugPrint('[ApiService] Python extract error, falling back to internal Dart engine: $e');
    }

    // 2. Direct Dart fallback for YouTube and Playlists
    try {
      // Check if Playlist
      if (url.contains('list=')) {
        final playlist = await _ytExplode.playlists.get(url);
        final videos = <PlaylistItemInfo>[];
        var idx = 1;
        await for (final v in _ytExplode.playlists.getVideos(playlist.id)) {
          videos.add(
            PlaylistItemInfo(
              index: idx++,
              id: v.id.value,
              title: v.title,
              duration: v.duration?.inSeconds ?? 0,
              thumbnailUrl: v.thumbnails.highResUrl,
              url: v.url,
            ),
          );
        }

        return MediaInfo(
          id: playlist.id.value,
          title: playlist.title,
          author: playlist.author,
          duration: 0,
          thumbnailUrl: playlist.thumbnails.highResUrl,
          webpageUrl: url,
          isPlaylist: true,
          playlistEntries: videos,
        );
      }

      // Single Video
      final video = await _ytExplode.videos.get(url);
      final manifest = await _ytExplode.videos.streamsClient.getManifest(video.id);

      final audioFormats = <MediaFormat>[
        MediaFormat(
          id: 'audio_m4a_128k',
          label: 'Fast M4A (128K)',
          extension: 'm4a',
          category: 'music',
          quality: '128K',
          note: 'Best for mobile play',
          sizeApprox: FileUtils.formatBytes(
              (video.duration?.inSeconds ?? 180) * 128 * 1024 ~/ 8),
          directUrl: manifest.audioOnly.isNotEmpty
              ? manifest.audioOnly.withHighestBitrate().url.toString()
              : null,
        ),
        MediaFormat(
          id: 'audio_mp3_128k',
          label: 'Classic MP3 (128K)',
          extension: 'mp3',
          category: 'music',
          quality: '128K',
          note: 'Standard compatibility',
          sizeApprox: FileUtils.formatBytes(
              (video.duration?.inSeconds ?? 180) * 128 * 1024 ~/ 8),
          directUrl: manifest.audioOnly.isNotEmpty
              ? manifest.audioOnly.withHighestBitrate().url.toString()
              : null,
        ),
        MediaFormat(
          id: 'audio_mp3_320k',
          label: 'Classic MP3 (320K)',
          extension: 'mp3',
          category: 'music',
          quality: '320K',
          note: 'High fidelity audio',
          sizeApprox: FileUtils.formatBytes(
              (video.duration?.inSeconds ?? 180) * 320 * 1024 ~/ 8),
          directUrl: manifest.audioOnly.isNotEmpty
              ? manifest.audioOnly.withHighestBitrate().url.toString()
              : null,
        ),
      ];

      final videoFormats = <MediaFormat>[];
      final seenLabels = <String>{};

      for (final s in manifest.muxed) {
        final label = s.videoQuality.name;
        if (!seenLabels.contains(label)) {
          seenLabels.add(label);
          videoFormats.add(
            MediaFormat(
              id: s.tag.toString(),
              label: label.toUpperCase(),
              extension: s.container.name,
              category: 'video',
              quality: label,
              sizeApprox: FileUtils.formatBytes(s.size.totalBytes),
              directUrl: s.url.toString(),
            ),
          );
        }
      }

      for (final s in manifest.videoOnly) {
        final label = s.videoQuality.name;
        if (!seenLabels.contains(label)) {
          seenLabels.add(label);
          videoFormats.add(
            MediaFormat(
              id: s.tag.toString(),
              label: label.toUpperCase(),
              extension: s.container.name,
              category: 'video',
              quality: label,
              sizeApprox: FileUtils.formatBytes(s.size.totalBytes),
              directUrl: s.url.toString(),
            ),
          );
        }
      }

      return MediaInfo(
        id: video.id.value,
        title: video.title,
        author: video.author,
        duration: video.duration?.inSeconds ?? 0,
        thumbnailUrl: video.thumbnails.highResUrl,
        webpageUrl: video.url,
        isPlaylist: false,
        audioFormats: audioFormats,
        videoFormats: videoFormats,
      );
    } catch (e) {
      throw Exception('Could not extract media: $e');
    }
  }

  void dispose() {
    _ytExplode.close();
  }
}
