import 'package:freezed_annotation/freezed_annotation.dart';

part 'env_var.freezed.dart';
part 'env_var.g.dart';

/// A single `KEY=value` environment variable for a launch.
@freezed
abstract class EnvVar with _$EnvVar {
  const factory EnvVar({required String key, required String value}) = _EnvVar;

  factory EnvVar.fromJson(Map<String, dynamic> json) => _$EnvVarFromJson(json);
}
