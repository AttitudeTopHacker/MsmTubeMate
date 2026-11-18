import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/file_utils.dart';

class VaultService extends ChangeNotifier {
  static const String _pinKey = 'msm_vault_pin_code';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isUnlocked = false;
  List<File> _vaultFiles = [];

  bool get isUnlocked => _isUnlocked;
  List<File> get vaultFiles => List.unmodifiable(_vaultFiles);

  Future<bool> hasPinSetup() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setupPin(String pin) async {
    if (pin.length < 4) return false;
    await _storage.write(key: _pinKey, value: pin);
    _isUnlocked = true;
    await loadVaultFiles();
    notifyListeners();
    return true;
  }

  Future<bool> unlockWithPin(String pin) async {
    final saved = await _storage.read(key: _pinKey);
    if (saved == pin) {
      _isUnlocked = true;
      await loadVaultFiles();
      notifyListeners();
      return true;
    }
    return false;
  }

  void lock() {
    _isUnlocked = false;
    _vaultFiles.clear();
    notifyListeners();
  }

  Future<void> loadVaultFiles() async {
    if (!_isUnlocked) return;
    try {
      final vaultDir = await FileUtils.getVaultDirectory();
      if (await vaultDir.exists()) {
        final list = vaultDir
            .listSync()
            .whereType<File>()
            .toList();
        _vaultFiles = list;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[VaultService] Load files error: $e');
    }
  }

  Future<bool> moveToVault(String filePath) async {
    try {
      final source = File(filePath);
      if (!await source.exists()) return false;

      final vaultDir = await FileUtils.getVaultDirectory();
      final fileName = source.path.split('/').last;
      final destPath = '${vaultDir.path}/$fileName';

      await source.rename(destPath);
      await loadVaultFiles();
      return true;
    } catch (e) {
      debugPrint('[VaultService] Move to vault error: $e');
      return false;
    }
  }

  Future<bool> restoreFromVault(String vaultFilePath) async {
    try {
      final source = File(vaultFilePath);
      if (!await source.exists()) return false;

      final downloadDir = await FileUtils.getDownloadDirectory();
      final fileName = source.path.split('/').last;
      final destPath = '${downloadDir.path}/$fileName';

      await source.rename(destPath);
      await loadVaultFiles();
      return true;
    } catch (e) {
      debugPrint('[VaultService] Restore error: $e');
      return false;
    }
  }
}
