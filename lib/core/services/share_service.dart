import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../utils/url_utils.dart';

class ShareService {
  static const MethodChannel _nativeChannel =
      MethodChannel('com.msmmovin.tubemate/share_intent');
  static StreamSubscription? _intentSub;

  static void initialize({required Function(String url) onUrlReceived}) {
    // Only Android / iOS support share intent receivers
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    // 1. Native Kotlin MethodChannel check on cold start
    _checkNativeColdStart(onUrlReceived);

    // 2. Stream listener when app is running in background or foreground
    try {
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> value) {
          if (value.isNotEmpty) {
            for (final item in value) {
              final url = UrlUtils.extractUrl(item.path);
              if (url != null) {
                onUrlReceived(url);
                break;
              }
            }
          }
        },
        onError: (err) {
          debugPrint('[ShareService] getMediaStream error: $err');
        },
      );

      // 3. Initial media on app launch
      ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          for (final item in value) {
            final url = UrlUtils.extractUrl(item.path);
            if (url != null) {
              onUrlReceived(url);
              break;
            }
          }
          ReceiveSharingIntent.instance.reset();
        }
      }).catchError((err) {
        debugPrint('[ShareService] getInitialMedia error: $err');
      });
    } catch (e) {
      debugPrint('[ShareService] Exception: $e');
    }
  }

  static Future<void> _checkNativeColdStart(Function(String url) onUrlReceived) async {
    try {
      final String? rawText = await _nativeChannel.invokeMethod<String>('getSharedText');
      if (rawText != null && rawText.isNotEmpty) {
        final url = UrlUtils.extractUrl(rawText);
        if (url != null) {
          onUrlReceived(url);
        }
      }
    } catch (_) {}
  }

  static void dispose() {
    _intentSub?.cancel();
  }
}
