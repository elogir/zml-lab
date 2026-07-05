import 'package:freezed_annotation/freezed_annotation.dart';

import 'env_var.dart';

part 'launch_config.freezed.dart';
part 'launch_config.g.dart';

/// A reusable, saved launch preset. Picking one pre-fills the job form.
@freezed
abstract class LaunchConfig with _$LaunchConfig {
  const factory LaunchConfig({
    required String id,
    required String name,
    String? description,
    required String machineId,
    required String command,
    String? workingDir,
    required int port,
    @Default(<EnvVar>[]) List<EnvVar> env,
  }) = _LaunchConfig;

  factory LaunchConfig.fromJson(Map<String, dynamic> json) =>
      _$LaunchConfigFromJson(json);
}
