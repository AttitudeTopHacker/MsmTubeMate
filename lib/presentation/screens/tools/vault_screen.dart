import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/services/vault_service.dart';
import '../../../core/utils/file_utils.dart';
import '../../widgets/glass/ambient_background.dart';
import '../../widgets/glass/glass_container.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  bool _checkingPin = true;
  bool _hasPin = false;
  String _enteredPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final vault = context.read<VaultService>();
    final hasPin = await vault.hasPinSetup();
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
        _checkingPin = false;
      });
      if (vault.isUnlocked) {
        vault.loadVaultFiles();
      }
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });
      if (_enteredPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _handlePinComplete() async {
    final vault = context.read<VaultService>();

    if (!_hasPin) {
      // First time setup
      if (!_isConfirming) {
        setState(() {
          _confirmPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        if (_enteredPin == _confirmPin) {
          final ok = await vault.setupPin(_enteredPin);
          if (ok && mounted) {
            setState(() {
              _hasPin = true;
              _enteredPin = '';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'PINs do not match. Try again.';
            _enteredPin = '';
            _confirmPin = '';
            _isConfirming = false;
          });
        }
      }
    } else {
      // Unlock existing PIN
      final ok = await vault.unlockWithPin(_enteredPin);
      if (!ok && mounted) {
        setState(() {
          _errorMessage = 'Incorrect PIN code';
          _enteredPin = '';
        });
      } else {
        setState(() => _enteredPin = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vault = context.watch<VaultService>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundMidnight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Private PIN Vault',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (vault.isUnlocked)
            IconButton(
              icon: const Icon(Icons.lock_outline_rounded, color: Colors.amberAccent),
              tooltip: 'Lock Vault',
              onPressed: () {
                vault.lock();
                setState(() => _enteredPin = '');
              },
            ),
        ],
      ),
      body: AmbientBackground(
        child: _checkingPin
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.accentCyan),
                ),
              )
            : vault.isUnlocked
                ? _buildVaultContents(vault)
                : _buildPinPad(),
      ),
    );
  }

  Widget _buildPinPad() {
    final title = !_hasPin
        ? (_isConfirming ? 'Confirm your 4-digit PIN' : 'Create a 4-digit Vault PIN')
        : 'Enter your 4-digit PIN to Unlock';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield_rounded,
              size: 64,
              color: AppTheme.accentCyan,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Files in your private vault are hidden from galleries and media apps.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 28),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppTheme.accentCyan : Colors.white24,
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: AppTheme.accentCyan.withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],

            const SizedBox(height: 36),

            // Keypad 1-9, 0, Backspace
            Column(
              children: [
                _buildKeyRow(['1', '2', '3']),
                const SizedBox(height: 16),
                _buildKeyRow(['4', '5', '6']),
                const SizedBox(height: 16),
                _buildKeyRow(['7', '8', '9']),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 72, height: 72),
                    const SizedBox(width: 16),
                    _buildKeyButton('0'),
                    const SizedBox(width: 16),
                    _buildBackspaceButton(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildKeyButton(key),
        );
      }).toList(),
    );
  }

  Widget _buildKeyButton(String label) {
    return GestureDetector(
      onTap: () => _onDigitPressed(label),
      child: GlassContainer(
        width: 72,
        height: 72,
        shape: BoxShape.circle,
        borderRadius: 36,
        padding: EdgeInsets.zero,
        opacity: 0.15,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return GestureDetector(
      onTap: _onBackspacePressed,
      child: const GlassContainer(
        width: 72,
        height: 72,
        shape: BoxShape.circle,
        borderRadius: 36,
        padding: EdgeInsets.zero,
        opacity: 0.15,
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Colors.white70,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildVaultContents(VaultService vault) {
    final files = vault.vaultFiles;

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_open_rounded,
              size: 64,
              color: AppTheme.accentCyan.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Vault is Empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Move sensitive downloaded audio or video files into this vault from the Downloads tab.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final fileName = file.path.split('/').last;
        final stat = file.statSync();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            opacity: 0.12,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppTheme.accentCyan,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FileUtils.formatBytes(stat.size),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70),
                  tooltip: 'Open',
                  onPressed: () => OpenFilex.open(file.path),
                ),
                IconButton(
                  icon: const Icon(Icons.restore_from_trash_rounded, color: AppTheme.accentCyan),
                  tooltip: 'Restore to Downloads',
                  onPressed: () async {
                    final ok = await vault.restoreFromVault(file.path);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File restored to Downloads directory')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
