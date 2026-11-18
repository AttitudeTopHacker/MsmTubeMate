class MediaFormat {
  final String id;
  final String label;
  final String extension;
  final String category; // 'music' or 'video'
  final String? quality; // '320K', '1080p', etc.
  final String? note;
  final String sizeApprox;
  final String? directUrl;

  MediaFormat({
    required this.id,
    required this.label,
    required this.extension,
    required this.category,
    this.quality,
    this.note,
    required this.sizeApprox,
    this.directUrl,
  });

  bool get isAudio => category == 'music';

  factory MediaFormat.fromJson(Map<String, dynamic> json) {
    return MediaFormat(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      extension: json['extension'] ?? 'mp4',
      category: json['category'] ?? 'video',
      quality: json['quality'],
      note: json['note'],
      sizeApprox: json['size_approx'] ?? 'Unknown',
      directUrl: json['url'],
    );
  }
}

class PlaylistItemInfo {
  final int index;
  final String id;
  final String title;
  final int duration;
  final String thumbnailUrl;
  final String url;
  bool isSelected;

  PlaylistItemInfo({
    required this.index,
    required this.id,
    required this.title,
    required this.duration,
    required this.thumbnailUrl,
    required this.url,
    this.isSelected = true,
  });

  factory PlaylistItemInfo.fromJson(Map<String, dynamic> json) {
    return PlaylistItemInfo(
      index: json['index'] ?? 0,
      id: json['id'] ?? '',
      title: json['title'] ?? 'Track',
      duration: json['duration'] ?? 0,
      thumbnailUrl: json['thumbnail'] ?? '',
      url: json['url'] ?? '',
      isSelected: true,
    );
  }
}

class MediaInfo {
  final String id;
  final String title;
  final String author;
  final int duration;
  final String thumbnailUrl;
  final String webpageUrl;
  final bool isPlaylist;
  final List<MediaFormat> audioFormats;
  final List<MediaFormat> videoFormats;
  final List<PlaylistItemInfo> playlistEntries;

  MediaInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnailUrl,
    required this.webpageUrl,
    this.isPlaylist = false,
    this.audioFormats = const [],
    this.videoFormats = const [],
    this.playlistEntries = const [],
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    final isPlaylist = json['is_playlist'] == true;
    if (isPlaylist) {
      final entries = (json['entries'] as List<dynamic>? ?? [])
          .map((e) => PlaylistItemInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      return MediaInfo(
        id: json['id'] ?? 'playlist',
        title: json['title'] ?? 'Playlist',
        author: json['author'] ?? 'Unknown Author',
        duration: 0,
        thumbnailUrl: json['thumbnail'] ?? '',
        webpageUrl: json['webpage_url'] ?? '',
        isPlaylist: true,
        playlistEntries: entries,
      );
    }

    final audios = (json['audio_formats'] as List<dynamic>? ?? [])
        .map((e) => MediaFormat.fromJson(e as Map<String, dynamic>))
        .toList();

    final videos = (json['video_formats'] as List<dynamic>? ?? [])
        .map((e) => MediaFormat.fromJson(e as Map<String, dynamic>))
        .toList();

    return MediaInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      author: json['author'] ?? 'Unknown Author',
      duration: json['duration'] ?? 0,
      thumbnailUrl: json['thumbnail'] ?? '',
      webpageUrl: json['webpage_url'] ?? '',
      isPlaylist: false,
      audioFormats: audios,
      videoFormats: videos,
    );
  }
}
