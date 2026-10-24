import 'download_types.dart';

export 'download_types.dart';

/// Bytes of [dest] already fetched by an interrupted download (0 on web).
int partialDownloadBytes(String dest) => 0;

FileDownload startDownload({
  required Uri url,
  required String dest,
  String? sha256,
}) => throw UnsupportedError('downloads need the desktop app');
