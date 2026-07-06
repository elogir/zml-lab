// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Job _$JobFromJson(Map<String, dynamic> json) => _Job(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  machineId: json['machineId'] as String,
  command: json['command'] as String,
  workingDir: json['workingDir'] as String?,
  port: (json['port'] as num).toInt(),
  status: $enumDecode(_$JobStatusEnumMap, json['status']),
  env:
      (json['env'] as List<dynamic>?)
          ?.map((e) => EnvVar.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <EnvVar>[],
  configId: json['configId'] as String?,
  pid: (json['pid'] as num?)?.toInt(),
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
);

Map<String, dynamic> _$JobToJson(_Job instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'machineId': instance.machineId,
  'command': instance.command,
  'workingDir': instance.workingDir,
  'port': instance.port,
  'status': _$JobStatusEnumMap[instance.status]!,
  'env': instance.env,
  'configId': instance.configId,
  'pid': instance.pid,
  'startedAt': instance.startedAt?.toIso8601String(),
};

const _$JobStatusEnumMap = {
  JobStatus.running: 'running',
  JobStatus.starting: 'starting',
  JobStatus.failed: 'failed',
  JobStatus.exited: 'exited',
};
