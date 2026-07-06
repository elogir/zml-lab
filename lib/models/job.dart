import 'package:freezed_annotation/freezed_annotation.dart';

import 'env_var.dart';
import 'enums.dart';

part 'job.freezed.dart';
part 'job.g.dart';

/// A launched (or once-launched) inference process on a remote machine.
@freezed
abstract class Job with _$Job {
  const Job._();

  const factory Job({
    required String id,
    required String name,
    String? description,
    required String machineId,
    required String command,
    String? workingDir,
    required int port,
    required JobStatus status,
    @Default(<EnvVar>[]) List<EnvVar> env,

    /// The saved config this job was launched from, if any — so editing the
    /// job can offer to push the change back to that config.
    String? configId,
    int? pid,
    DateTime? startedAt,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);

  bool get isStopped => status == JobStatus.exited || status == JobStatus.failed;

  /// How long the process has been up as of [now], or null if not running.
  Duration? uptimeAt(DateTime now) {
    final started = startedAt;
    if (started == null || isStopped) return null;
    return now.difference(started);
  }
}
