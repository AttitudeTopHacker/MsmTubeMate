import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$secs';
    }
    return '$minutes:$secs';
  }

  static String sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final publicDir = Directory('/storage/emulated/0/Download/MsmTubeMate');
      if (await publicDir.exists()) {
        return publicDir;
      }
      try {
        return await publicDir.create(recursive: true);
      } catch (_) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final target = Directory('${extDir.path}/MsmTubeMate');
          if (!await target.exists()) {
            await target.create(recursive: true);
          }
          return target;
        }
      }
    }

    final appDocs = await getApplicationDocumentsDirectory();
    final target = Directory('${appDocs.path}/MsmTubeMate');
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target;
  }

  static Future<Directory> getVaultDirectory() async {
    final appDocs = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDocs.path}/.msm_vault');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }
}
