// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'launch_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LaunchConfig _$LaunchConfigFromJson(Map<String, dynamic> json) =>
    _LaunchConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      machineId: json['machineId'] as String,
      program: json['program'] as String,
      command: json['command'] as String,
      workingDir: json['workingDir'] as String?,
      port: (json['port'] as num).toInt(),
      env:
          (json['env'] as List<dynamic>?)
              ?.map((e) => EnvVar.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <EnvVar>[],
    );

Map<String, dynamic> _$LaunchConfigToJson(_LaunchConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'machineId': instance.machineId,
      'program': instance.program,
      'command': instance.command,
      'workingDir': instance.workingDir,
      'port': instance.port,
      'env': instance.env,
    };
