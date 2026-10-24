/// How far a download is: [received] of [total] bytes (null while unknown).
typedef DownloadProgress = ({int received, int? total});

/// A download in progress.
abstract interface class FileDownload {
  /// Throttled (~10 Hz) progress, starting with what a resumed download
  /// already had.
  Stream<DownloadProgress> get progress;

  /// Completes once the file is at its destination (checksum verified), or
  /// fails with a readable message. Never completes after [cancel].
  Future<void> get done;

  /// Stops now. What was fetched is kept, so the next download of the same
  /// file resumes from there.
  void cancel();
}
