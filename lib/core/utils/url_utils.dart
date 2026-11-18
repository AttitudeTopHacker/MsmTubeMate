import 'package:flutter/material.dart';

enum PlatformType {
  youtube('YouTube', Color(0xFFFF0000), Icons.play_arrow_rounded),
  instagram('Instagram', Color(0xFFE1306C), Icons.camera_alt_outlined),
  twitter('X / Twitter', Color(0xFF1DA1F2), Icons.tag_rounded),
  whatsapp('WhatsApp', Color(0xFF25D366), Icons.chat_bubble_rounded),
  facebook('Facebook', Color(0xFF1877F2), Icons.facebook_rounded),
  tiktok('TikTok', Color(0xFF00F2FE), Icons.music_note_rounded),
  generic('Web Media', Color(0xFF3A86FF), Icons.public_rounded);

  final String displayName;
  final Color brandColor;
  final IconData icon;

  const PlatformType(this.displayName, this.brandColor, this.icon);
}

class UrlUtils {
  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/[^\s]+)',
    caseSensitive: false,
  );

  static String? extractUrl(String text) {
    final match = _urlRegex.firstMatch(text);
    return match?.group(0);
  }

  static bool isYouTubePlaylist(String url) {
    final lower = url.toLowerCase();
    return (lower.contains('youtube.com') || lower.contains('youtu.be')) &&
        (lower.contains('list=') || lower.contains('&list='));
  }

  static PlatformType detectPlatform(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return PlatformType.youtube;
    } else if (lower.contains('instagram.com')) {
      return PlatformType.instagram;
    } else if (lower.contains('twitter.com') || lower.contains('x.com')) {
      return PlatformType.twitter;
    } else if (lower.contains('facebook.com') || lower.contains('fb.watch')) {
      return PlatformType.facebook;
    } else if (lower.contains('tiktok.com')) {
      return PlatformType.tiktok;
    } else if (lower.contains('whatsapp')) {
      return PlatformType.whatsapp;
    }
    return PlatformType.generic;
  }
}
