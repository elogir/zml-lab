/// Lifecycle state of a job. Drives the one place color is allowed to shout.
enum JobStatus {
  running,
  starting,
  failed,
  exited;

  String get label => switch (this) {
    JobStatus.running => 'running',
    JobStatus.starting => 'starting',
    JobStatus.failed => 'failed',
    JobStatus.exited => 'exited',
  };

  /// Whether the process is (or is becoming) live.
  bool get isActive => this == JobStatus.running || this == JobStatus.starting;

  bool get isRunning => this == JobStatus.running;
}

/// Hardware vendor of a remote host — labels the machine, nothing more.
enum Vendor {
  nvidia,
  amd;

  String get label => switch (this) {
    Vendor.nvidia => 'NVIDIA',
    Vendor.amd => 'AMD',
  };
}
