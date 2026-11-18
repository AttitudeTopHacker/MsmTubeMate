enum TaskStatus { pending, downloading, paused, completed, failed }

class DownloadTask {
  final String id;
  final String title;
  final String sourceUrl;
  final String destinationPath;
  final String formatLabel;
  final String platform;
  final String thumbnailUrl;
  final bool isAudio;
  int downloadedBytes;
  int totalBytes;
  double speedBytesPerSec;
  TaskStatus status;
  final DateTime createdAt;

  DownloadTask({
    required this.id,
    required this.title,
    required this.sourceUrl,
    required this.destinationPath,
    required this.formatLabel,
    required this.platform,
    required this.thumbnailUrl,
    required this.isAudio,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0.0,
    this.status = TaskStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress {
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  String get statusLabel {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.downloading:
        return 'Downloading';
      case TaskStatus.paused:
        return 'Paused';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.failed:
        return 'Failed';
    }
  }
}
