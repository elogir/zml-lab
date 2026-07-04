// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Machine _$MachineFromJson(Map<String, dynamic> json) => _Machine(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  sshPort: (json['sshPort'] as num?)?.toInt() ?? 22,
  user: json['user'] as String?,
  sshKey: json['sshKey'] as String?,
  vendor: $enumDecodeNullable(_$VendorEnumMap, json['vendor']),
  gpus: json['gpus'] as String?,
  memory: json['memory'] as String?,
  online: json['online'] as bool? ?? true,
);

Map<String, dynamic> _$MachineToJson(_Machine instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'sshPort': instance.sshPort,
  'user': instance.user,
  'sshKey': instance.sshKey,
  'vendor': _$VendorEnumMap[instance.vendor],
  'gpus': instance.gpus,
  'memory': instance.memory,
  'online': instance.online,
};

const _$VendorEnumMap = {Vendor.nvidia: 'nvidia', Vendor.amd: 'amd'};
