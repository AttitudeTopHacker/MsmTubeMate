import 'dart:io';
import '../../data/models/status_item.dart';
import '../utils/file_utils.dart';

class StatusService {
  static const List<String> _possibleStatusDirs = [
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    '/storage/emulated/0/WhatsApp/Media/.Statuses',
    '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
    '/storage/emulated/0/WhatsApp Business/Media/.Statuses',
  ];

  static Future<List<WhatsAppStatus>> loadStatuses() async {
    final list = <WhatsAppStatus>[];

    for (final path in _possibleStatusDirs) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          final entities = dir.listSync();
          for (final entity in entities) {
            if (entity is File) {
              final lower = entity.path.toLowerCase();
              final isVideo = lower.endsWith('.mp4');
              final isImage = lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');

              if (isVideo || isImage) {
                final stat = entity.statSync();
                list.add(
                  WhatsAppStatus(
                    path: entity.path,
                    isVideo: isVideo,
                    sizeInBytes: stat.size,
                    modifiedTime: stat.modified,
                  ),
                );
              }
            }
          }
        } catch (_) {}
      }
    }

    list.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
    return list;
  }

  static Future<String?> saveStatus(WhatsAppStatus status) async {
    try {
      final downloadDir = await FileUtils.getDownloadDirectory();
      final statusDir = Directory('${downloadDir.path}/WhatsAppStatus');
      if (!await statusDir.exists()) {
        await statusDir.create(recursive: true);
      }

      final source = File(status.path);
      final destPath = '${statusDir.path}/${status.fileName}';
      await source.copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }
}
