import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../config/supabase_config.dart';
import '../../data/models/download_task.dart';
import '../../data/models/media_item.dart';
import '../utils/file_utils.dart';
import '../utils/url_utils.dart';

class DownloadService extends ChangeNotifier {
  final List<DownloadTask> _tasks = [];
  final Map<String, CancelToken> _cancelTokens = {};
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(hours: 2),
    ),
  );

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  List<DownloadTask> get activeTasks => _tasks
      .where((t) =>
          t.status == TaskStatus.downloading || t.status == TaskStatus.pending)
      .toList();

  List<DownloadTask> get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.completed).toList();

  DownloadService() {
    _loadCloudHistory();
  }

  Future<void> _loadCloudHistory() async {
    try {
      final client = SupabaseConfig.client;
      if (client != null && client.auth.currentUser != null) {
        final data = await client
            .from('download_history')
            .select()
            .order('created_at', ascending: false);

        for (final item in data) {
          _tasks.add(
            DownloadTask(
              id: item['id'],
              title: item['title'],
              sourceUrl: item['source_url'],
              destinationPath: '',
              formatLabel: item['format_label'],
              platform: item['platform'],
              thumbnailUrl: item['thumbnail_url'] ?? '',
              isAudio: item['media_type'] == 'audio',
              status: TaskStatus.completed,
            ),
          );
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[DownloadService] Cloud history sync note: $e');
    }
  }

  Future<DownloadTask> startDownload({
    required MediaInfo media,
    required MediaFormat format,
  }) async {
    final downloadDir = await FileUtils.getDownloadDirectory();
    final sanitizedTitle = FileUtils.sanitizeFileName(media.title);
    final ext = format.extension.toLowerCase();
    final destinationPath =
        '${downloadDir.path}/${sanitizedTitle}_${format.label.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.$ext';

    final task = DownloadTask(
      id: const Uuid().v4(),
      title: media.title,
      sourceUrl: media.webpageUrl,
      destinationPath: destinationPath,
      formatLabel: format.label,
      platform: UrlUtils.detectPlatform(media.webpageUrl).displayName,
      thumbnailUrl: media.thumbnailUrl,
      isAudio: format.isAudio,
      status: TaskStatus.downloading,
    );

    _tasks.insert(0, task);
    notifyListeners();

    _executeDownload(task, format.directUrl ?? media.webpageUrl);
    return task;
  }

  Future<void> _executeDownload(DownloadTask task, String downloadUrl) async {
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    var lastTime = DateTime.now();
    var lastBytes = 0;

    try {
      final response = await _dio.download(
        downloadUrl,
        task.destinationPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            task.totalBytes = total;
          }
          task.downloadedBytes = received;

          final now = DateTime.now();
          final elapsed = now.difference(lastTime).inMilliseconds;
          if (elapsed >= 500) {
            final bytesSince = received - lastBytes;
            task.speedBytesPerSec = (bytesSince / elapsed) * 1000;
            lastTime = now;
            lastBytes = received;
            notifyListeners();
          }
        },
      );

      if (response.statusCode == 200) {
        task.status = TaskStatus.completed;
        task.speedBytesPerSec = 0.0;
        notifyListeners();

        _syncCompletedToSupabase(task);
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        task.status = TaskStatus.paused;
      } else {
        task.status = TaskStatus.failed;
      }
      task.speedBytesPerSec = 0.0;
      notifyListeners();
    } catch (_) {
      task.status = TaskStatus.failed;
      notifyListeners();
    } finally {
      _cancelTokens.remove(task.id);
    }
  }

  void pause(String taskId) {
    if (_cancelTokens.containsKey(taskId)) {
      _cancelTokens[taskId]?.cancel();
    }
  }

  void resume(String taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = TaskStatus.downloading;
    notifyListeners();
    _executeDownload(task, task.sourceUrl);
  }

  void remove(String taskId, {bool deleteFile = false}) {
    pause(taskId);
    final task = _tasks.firstWhere((t) => t.id == taskId);
    if (deleteFile && task.destinationPath.isNotEmpty) {
      final file = File(task.destinationPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  Future<void> _syncCompletedToSupabase(DownloadTask task) async {
    try {
      final client = SupabaseConfig.client;
      if (client != null && client.auth.currentUser != null) {
        await client.from('download_history').insert({
          'user_id': client.auth.currentUser!.id,
          'title': task.title,
          'platform': task.platform,
          'media_type': task.isAudio ? 'audio' : 'video',
          'format_label': task.formatLabel,
          'file_size': FileUtils.formatBytes(task.totalBytes),
          'thumbnail_url': task.thumbnailUrl,
          'source_url': task.sourceUrl,
        });
      }
    } catch (e) {
      debugPrint('[DownloadService] Supabase history insert notice: $e');
    }
  }
}
