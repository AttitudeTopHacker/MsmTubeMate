class WhatsAppStatus {
  final String path;
  final bool isVideo;
  final int sizeInBytes;
  final DateTime modifiedTime;

  WhatsAppStatus({
    required this.path,
    required this.isVideo,
    required this.sizeInBytes,
    required this.modifiedTime,
  });

  String get fileName => path.split('/').last;
}
