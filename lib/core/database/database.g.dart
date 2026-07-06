// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MachinesTable extends Machines
    with TableInfo<$MachinesTable, MachineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MachinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sshPortMeta = const VerificationMeta(
    'sshPort',
  );
  @override
  late final GeneratedColumn<int> sshPort = GeneratedColumn<int>(
    'ssh_port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(22),
  );
  static const VerificationMeta _userMeta = const VerificationMeta('user');
  @override
  late final GeneratedColumn<String> user = GeneratedColumn<String>(
    'user',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sshKeyMeta = const VerificationMeta('sshKey');
  @override
  late final GeneratedColumn<String> sshKey = GeneratedColumn<String>(
    'ssh_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
    'vendor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpusMeta = const VerificationMeta('gpus');
  @override
  late final GeneratedColumn<String> gpus = GeneratedColumn<String>(
    'gpus',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoryMeta = const VerificationMeta('memory');
  @override
  late final GeneratedColumn<String> memory = GeneratedColumn<String>(
    'memory',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onlineMeta = const VerificationMeta('online');
  @override
  late final GeneratedColumn<bool> online = GeneratedColumn<bool>(
    'online',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("online" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    address,
    sshPort,
    user,
    sshKey,
    vendor,
    gpus,
    memory,
    online,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'machines';
  @override
  VerificationContext validateIntegrity(
    Insertable<MachineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('ssh_port')) {
      context.handle(
        _sshPortMeta,
        sshPort.isAcceptableOrUnknown(data['ssh_port']!, _sshPortMeta),
      );
    }
    if (data.containsKey('user')) {
      context.handle(
        _userMeta,
        user.isAcceptableOrUnknown(data['user']!, _userMeta),
      );
    }
    if (data.containsKey('ssh_key')) {
      context.handle(
        _sshKeyMeta,
        sshKey.isAcceptableOrUnknown(data['ssh_key']!, _sshKeyMeta),
      );
    }
    if (data.containsKey('vendor')) {
      context.handle(
        _vendorMeta,
        vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta),
      );
    }
    if (data.containsKey('gpus')) {
      context.handle(
        _gpusMeta,
        gpus.isAcceptableOrUnknown(data['gpus']!, _gpusMeta),
      );
    }
    if (data.containsKey('memory')) {
      context.handle(
        _memoryMeta,
        memory.isAcceptableOrUnknown(data['memory']!, _memoryMeta),
      );
    }
    if (data.containsKey('online')) {
      context.handle(
        _onlineMeta,
        online.isAcceptableOrUnknown(data['online']!, _onlineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MachineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MachineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      sshPort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ssh_port'],
      )!,
      user: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user'],
      ),
      sshKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ssh_key'],
      ),
      vendor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor'],
      ),
      gpus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gpus'],
      ),
      memory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memory'],
      ),
      online: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}online'],
      )!,
    );
  }

  @override
  $MachinesTable createAlias(String alias) {
    return $MachinesTable(attachedDatabase, alias);
  }
}

class MachineRow extends DataClass implements Insertable<MachineRow> {
  final String id;
  final String name;
  final String address;
  final int sshPort;
  final String? user;
  final String? sshKey;

  /// [Vendor.name], or null if unknown.
  final String? vendor;
  final String? gpus;
  final String? memory;
  final bool online;
  const MachineRow({
    required this.id,
    required this.name,
    required this.address,
    required this.sshPort,
    this.user,
    this.sshKey,
    this.vendor,
    this.gpus,
    this.memory,
    required this.online,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['ssh_port'] = Variable<int>(sshPort);
    if (!nullToAbsent || user != null) {
      map['user'] = Variable<String>(user);
    }
    if (!nullToAbsent || sshKey != null) {
      map['ssh_key'] = Variable<String>(sshKey);
    }
    if (!nullToAbsent || vendor != null) {
      map['vendor'] = Variable<String>(vendor);
    }
    if (!nullToAbsent || gpus != null) {
      map['gpus'] = Variable<String>(gpus);
    }
    if (!nullToAbsent || memory != null) {
      map['memory'] = Variable<String>(memory);
    }
    map['online'] = Variable<bool>(online);
    return map;
  }

  MachinesCompanion toCompanion(bool nullToAbsent) {
    return MachinesCompanion(
      id: Value(id),
      name: Value(name),
      address: Value(address),
      sshPort: Value(sshPort),
      user: user == null && nullToAbsent ? const Value.absent() : Value(user),
      sshKey: sshKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sshKey),
      vendor: vendor == null && nullToAbsent
          ? const Value.absent()
          : Value(vendor),
      gpus: gpus == null && nullToAbsent ? const Value.absent() : Value(gpus),
      memory: memory == null && nullToAbsent
          ? const Value.absent()
          : Value(memory),
      online: Value(online),
    );
  }

  factory MachineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MachineRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      sshPort: serializer.fromJson<int>(json['sshPort']),
      user: serializer.fromJson<String?>(json['user']),
      sshKey: serializer.fromJson<String?>(json['sshKey']),
      vendor: serializer.fromJson<String?>(json['vendor']),
      gpus: serializer.fromJson<String?>(json['gpus']),
      memory: serializer.fromJson<String?>(json['memory']),
      online: serializer.fromJson<bool>(json['online']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'sshPort': serializer.toJson<int>(sshPort),
      'user': serializer.toJson<String?>(user),
      'sshKey': serializer.toJson<String?>(sshKey),
      'vendor': serializer.toJson<String?>(vendor),
      'gpus': serializer.toJson<String?>(gpus),
      'memory': serializer.toJson<String?>(memory),
      'online': serializer.toJson<bool>(online),
    };
  }

  MachineRow copyWith({
    String? id,
    String? name,
    String? address,
    int? sshPort,
    Value<String?> user = const Value.absent(),
    Value<String?> sshKey = const Value.absent(),
    Value<String?> vendor = const Value.absent(),
    Value<String?> gpus = const Value.absent(),
    Value<String?> memory = const Value.absent(),
    bool? online,
  }) => MachineRow(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    sshPort: sshPort ?? this.sshPort,
    user: user.present ? user.value : this.user,
    sshKey: sshKey.present ? sshKey.value : this.sshKey,
    vendor: vendor.present ? vendor.value : this.vendor,
    gpus: gpus.present ? gpus.value : this.gpus,
    memory: memory.present ? memory.value : this.memory,
    online: online ?? this.online,
  );
  MachineRow copyWithCompanion(MachinesCompanion data) {
    return MachineRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      sshPort: data.sshPort.present ? data.sshPort.value : this.sshPort,
      user: data.user.present ? data.user.value : this.user,
      sshKey: data.sshKey.present ? data.sshKey.value : this.sshKey,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      gpus: data.gpus.present ? data.gpus.value : this.gpus,
      memory: data.memory.present ? data.memory.value : this.memory,
      online: data.online.present ? data.online.value : this.online,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MachineRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('sshPort: $sshPort, ')
          ..write('user: $user, ')
          ..write('sshKey: $sshKey, ')
          ..write('vendor: $vendor, ')
          ..write('gpus: $gpus, ')
          ..write('memory: $memory, ')
          ..write('online: $online')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    sshPort,
    user,
    sshKey,
    vendor,
    gpus,
    memory,
    online,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MachineRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.sshPort == this.sshPort &&
          other.user == this.user &&
          other.sshKey == this.sshKey &&
          other.vendor == this.vendor &&
          other.gpus == this.gpus &&
          other.memory == this.memory &&
          other.online == this.online);
}

class MachinesCompanion extends UpdateCompanion<MachineRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> address;
  final Value<int> sshPort;
  final Value<String?> user;
  final Value<String?> sshKey;
  final Value<String?> vendor;
  final Value<String?> gpus;
  final Value<String?> memory;
  final Value<bool> online;
  final Value<int> rowid;
  const MachinesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.sshPort = const Value.absent(),
    this.user = const Value.absent(),
    this.sshKey = const Value.absent(),
    this.vendor = const Value.absent(),
    this.gpus = const Value.absent(),
    this.memory = const Value.absent(),
    this.online = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MachinesCompanion.insert({
    required String id,
    required String name,
    required String address,
    this.sshPort = const Value.absent(),
    this.user = const Value.absent(),
    this.sshKey = const Value.absent(),
    this.vendor = const Value.absent(),
    this.gpus = const Value.absent(),
    this.memory = const Value.absent(),
    this.online = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       address = Value(address);
  static Insertable<MachineRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<int>? sshPort,
    Expression<String>? user,
    Expression<String>? sshKey,
    Expression<String>? vendor,
    Expression<String>? gpus,
    Expression<String>? memory,
    Expression<bool>? online,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (sshPort != null) 'ssh_port': sshPort,
      if (user != null) 'user': user,
      if (sshKey != null) 'ssh_key': sshKey,
      if (vendor != null) 'vendor': vendor,
      if (gpus != null) 'gpus': gpus,
      if (memory != null) 'memory': memory,
      if (online != null) 'online': online,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MachinesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? address,
    Value<int>? sshPort,
    Value<String?>? user,
    Value<String?>? sshKey,
    Value<String?>? vendor,
    Value<String?>? gpus,
    Value<String?>? memory,
    Value<bool>? online,
    Value<int>? rowid,
  }) {
    return MachinesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      sshPort: sshPort ?? this.sshPort,
      user: user ?? this.user,
      sshKey: sshKey ?? this.sshKey,
      vendor: vendor ?? this.vendor,
      gpus: gpus ?? this.gpus,
      memory: memory ?? this.memory,
      online: online ?? this.online,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (sshPort.present) {
      map['ssh_port'] = Variable<int>(sshPort.value);
    }
    if (user.present) {
      map['user'] = Variable<String>(user.value);
    }
    if (sshKey.present) {
      map['ssh_key'] = Variable<String>(sshKey.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (gpus.present) {
      map['gpus'] = Variable<String>(gpus.value);
    }
    if (memory.present) {
      map['memory'] = Variable<String>(memory.value);
    }
    if (online.present) {
      map['online'] = Variable<bool>(online.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MachinesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('sshPort: $sshPort, ')
          ..write('user: $user, ')
          ..write('sshKey: $sshKey, ')
          ..write('vendor: $vendor, ')
          ..write('gpus: $gpus, ')
          ..write('memory: $memory, ')
          ..write('online: $online, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LaunchConfigsTable extends LaunchConfigs
    with TableInfo<$LaunchConfigsTable, LaunchConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LaunchConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _machineIdMeta = const VerificationMeta(
    'machineId',
  );
  @override
  late final GeneratedColumn<String> machineId = GeneratedColumn<String>(
    'machine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commandMeta = const VerificationMeta(
    'command',
  );
  @override
  late final GeneratedColumn<String> command = GeneratedColumn<String>(
    'command',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workingDirMeta = const VerificationMeta(
    'workingDir',
  );
  @override
  late final GeneratedColumn<String> workingDir = GeneratedColumn<String>(
    'working_dir',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _envJsonMeta = const VerificationMeta(
    'envJson',
  );
  @override
  late final GeneratedColumn<String> envJson = GeneratedColumn<String>(
    'env_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    machineId,
    command,
    workingDir,
    port,
    envJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'launch_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LaunchConfigRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('machine_id')) {
      context.handle(
        _machineIdMeta,
        machineId.isAcceptableOrUnknown(data['machine_id']!, _machineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_machineIdMeta);
    }
    if (data.containsKey('command')) {
      context.handle(
        _commandMeta,
        command.isAcceptableOrUnknown(data['command']!, _commandMeta),
      );
    } else if (isInserting) {
      context.missing(_commandMeta);
    }
    if (data.containsKey('working_dir')) {
      context.handle(
        _workingDirMeta,
        workingDir.isAcceptableOrUnknown(data['working_dir']!, _workingDirMeta),
      );
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('env_json')) {
      context.handle(
        _envJsonMeta,
        envJson.isAcceptableOrUnknown(data['env_json']!, _envJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LaunchConfigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LaunchConfigRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      machineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_id'],
      )!,
      command: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command'],
      )!,
      workingDir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}working_dir'],
      ),
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      envJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}env_json'],
      )!,
    );
  }

  @override
  $LaunchConfigsTable createAlias(String alias) {
    return $LaunchConfigsTable(attachedDatabase, alias);
  }
}

class LaunchConfigRow extends DataClass implements Insertable<LaunchConfigRow> {
  final String id;
  final String name;
  final String? description;
  final String machineId;
  final String command;
  final String? workingDir;
  final int port;

  /// JSON-encoded `List<EnvVar>`.
  final String envJson;
  const LaunchConfigRow({
    required this.id,
    required this.name,
    this.description,
    required this.machineId,
    required this.command,
    this.workingDir,
    required this.port,
    required this.envJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['machine_id'] = Variable<String>(machineId);
    map['command'] = Variable<String>(command);
    if (!nullToAbsent || workingDir != null) {
      map['working_dir'] = Variable<String>(workingDir);
    }
    map['port'] = Variable<int>(port);
    map['env_json'] = Variable<String>(envJson);
    return map;
  }

  LaunchConfigsCompanion toCompanion(bool nullToAbsent) {
    return LaunchConfigsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      machineId: Value(machineId),
      command: Value(command),
      workingDir: workingDir == null && nullToAbsent
          ? const Value.absent()
          : Value(workingDir),
      port: Value(port),
      envJson: Value(envJson),
    );
  }

  factory LaunchConfigRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LaunchConfigRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      machineId: serializer.fromJson<String>(json['machineId']),
      command: serializer.fromJson<String>(json['command']),
      workingDir: serializer.fromJson<String?>(json['workingDir']),
      port: serializer.fromJson<int>(json['port']),
      envJson: serializer.fromJson<String>(json['envJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'machineId': serializer.toJson<String>(machineId),
      'command': serializer.toJson<String>(command),
      'workingDir': serializer.toJson<String?>(workingDir),
      'port': serializer.toJson<int>(port),
      'envJson': serializer.toJson<String>(envJson),
    };
  }

  LaunchConfigRow copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    String? machineId,
    String? command,
    Value<String?> workingDir = const Value.absent(),
    int? port,
    String? envJson,
  }) => LaunchConfigRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    machineId: machineId ?? this.machineId,
    command: command ?? this.command,
    workingDir: workingDir.present ? workingDir.value : this.workingDir,
    port: port ?? this.port,
    envJson: envJson ?? this.envJson,
  );
  LaunchConfigRow copyWithCompanion(LaunchConfigsCompanion data) {
    return LaunchConfigRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      machineId: data.machineId.present ? data.machineId.value : this.machineId,
      command: data.command.present ? data.command.value : this.command,
      workingDir: data.workingDir.present
          ? data.workingDir.value
          : this.workingDir,
      port: data.port.present ? data.port.value : this.port,
      envJson: data.envJson.present ? data.envJson.value : this.envJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LaunchConfigRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('machineId: $machineId, ')
          ..write('command: $command, ')
          ..write('workingDir: $workingDir, ')
          ..write('port: $port, ')
          ..write('envJson: $envJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    machineId,
    command,
    workingDir,
    port,
    envJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LaunchConfigRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.machineId == this.machineId &&
          other.command == this.command &&
          other.workingDir == this.workingDir &&
          other.port == this.port &&
          other.envJson == this.envJson);
}

class LaunchConfigsCompanion extends UpdateCompanion<LaunchConfigRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> machineId;
  final Value<String> command;
  final Value<String?> workingDir;
  final Value<int> port;
  final Value<String> envJson;
  final Value<int> rowid;
  const LaunchConfigsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.machineId = const Value.absent(),
    this.command = const Value.absent(),
    this.workingDir = const Value.absent(),
    this.port = const Value.absent(),
    this.envJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LaunchConfigsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required String machineId,
    required String command,
    this.workingDir = const Value.absent(),
    required int port,
    this.envJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       machineId = Value(machineId),
       command = Value(command),
       port = Value(port);
  static Insertable<LaunchConfigRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? machineId,
    Expression<String>? command,
    Expression<String>? workingDir,
    Expression<int>? port,
    Expression<String>? envJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (machineId != null) 'machine_id': machineId,
      if (command != null) 'command': command,
      if (workingDir != null) 'working_dir': workingDir,
      if (port != null) 'port': port,
      if (envJson != null) 'env_json': envJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LaunchConfigsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? machineId,
    Value<String>? command,
    Value<String?>? workingDir,
    Value<int>? port,
    Value<String>? envJson,
    Value<int>? rowid,
  }) {
    return LaunchConfigsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      machineId: machineId ?? this.machineId,
      command: command ?? this.command,
      workingDir: workingDir ?? this.workingDir,
      port: port ?? this.port,
      envJson: envJson ?? this.envJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (machineId.present) {
      map['machine_id'] = Variable<String>(machineId.value);
    }
    if (command.present) {
      map['command'] = Variable<String>(command.value);
    }
    if (workingDir.present) {
      map['working_dir'] = Variable<String>(workingDir.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (envJson.present) {
      map['env_json'] = Variable<String>(envJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LaunchConfigsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('machineId: $machineId, ')
          ..write('command: $command, ')
          ..write('workingDir: $workingDir, ')
          ..write('port: $port, ')
          ..write('envJson: $envJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JobsTable extends Jobs with TableInfo<$JobsTable, JobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _machineIdMeta = const VerificationMeta(
    'machineId',
  );
  @override
  late final GeneratedColumn<String> machineId = GeneratedColumn<String>(
    'machine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commandMeta = const VerificationMeta(
    'command',
  );
  @override
  late final GeneratedColumn<String> command = GeneratedColumn<String>(
    'command',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workingDirMeta = const VerificationMeta(
    'workingDir',
  );
  @override
  late final GeneratedColumn<String> workingDir = GeneratedColumn<String>(
    'working_dir',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _envJsonMeta = const VerificationMeta(
    'envJson',
  );
  @override
  late final GeneratedColumn<String> envJson = GeneratedColumn<String>(
    'env_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _pidMeta = const VerificationMeta('pid');
  @override
  late final GeneratedColumn<int> pid = GeneratedColumn<int>(
    'pid',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    machineId,
    command,
    workingDir,
    port,
    status,
    envJson,
    pid,
    startedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('machine_id')) {
      context.handle(
        _machineIdMeta,
        machineId.isAcceptableOrUnknown(data['machine_id']!, _machineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_machineIdMeta);
    }
    if (data.containsKey('command')) {
      context.handle(
        _commandMeta,
        command.isAcceptableOrUnknown(data['command']!, _commandMeta),
      );
    } else if (isInserting) {
      context.missing(_commandMeta);
    }
    if (data.containsKey('working_dir')) {
      context.handle(
        _workingDirMeta,
        workingDir.isAcceptableOrUnknown(data['working_dir']!, _workingDirMeta),
      );
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('env_json')) {
      context.handle(
        _envJsonMeta,
        envJson.isAcceptableOrUnknown(data['env_json']!, _envJsonMeta),
      );
    }
    if (data.containsKey('pid')) {
      context.handle(
        _pidMeta,
        pid.isAcceptableOrUnknown(data['pid']!, _pidMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      machineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_id'],
      )!,
      command: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command'],
      )!,
      workingDir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}working_dir'],
      ),
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      envJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}env_json'],
      )!,
      pid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pid'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
    );
  }

  @override
  $JobsTable createAlias(String alias) {
    return $JobsTable(attachedDatabase, alias);
  }
}

class JobRow extends DataClass implements Insertable<JobRow> {
  final String id;
  final String name;
  final String? description;
  final String machineId;
  final String command;
  final String? workingDir;
  final int port;

  /// [JobStatus.name].
  final String status;
  final String envJson;
  final int? pid;
  final DateTime? startedAt;
  const JobRow({
    required this.id,
    required this.name,
    this.description,
    required this.machineId,
    required this.command,
    this.workingDir,
    required this.port,
    required this.status,
    required this.envJson,
    this.pid,
    this.startedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['machine_id'] = Variable<String>(machineId);
    map['command'] = Variable<String>(command);
    if (!nullToAbsent || workingDir != null) {
      map['working_dir'] = Variable<String>(workingDir);
    }
    map['port'] = Variable<int>(port);
    map['status'] = Variable<String>(status);
    map['env_json'] = Variable<String>(envJson);
    if (!nullToAbsent || pid != null) {
      map['pid'] = Variable<int>(pid);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      machineId: Value(machineId),
      command: Value(command),
      workingDir: workingDir == null && nullToAbsent
          ? const Value.absent()
          : Value(workingDir),
      port: Value(port),
      status: Value(status),
      envJson: Value(envJson),
      pid: pid == null && nullToAbsent ? const Value.absent() : Value(pid),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
    );
  }

  factory JobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      machineId: serializer.fromJson<String>(json['machineId']),
      command: serializer.fromJson<String>(json['command']),
      workingDir: serializer.fromJson<String?>(json['workingDir']),
      port: serializer.fromJson<int>(json['port']),
      status: serializer.fromJson<String>(json['status']),
      envJson: serializer.fromJson<String>(json['envJson']),
      pid: serializer.fromJson<int?>(json['pid']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'machineId': serializer.toJson<String>(machineId),
      'command': serializer.toJson<String>(command),
      'workingDir': serializer.toJson<String?>(workingDir),
      'port': serializer.toJson<int>(port),
      'status': serializer.toJson<String>(status),
      'envJson': serializer.toJson<String>(envJson),
      'pid': serializer.toJson<int?>(pid),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
    };
  }

  JobRow copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    String? machineId,
    String? command,
    Value<String?> workingDir = const Value.absent(),
    int? port,
    String? status,
    String? envJson,
    Value<int?> pid = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
  }) => JobRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    machineId: machineId ?? this.machineId,
    command: command ?? this.command,
    workingDir: workingDir.present ? workingDir.value : this.workingDir,
    port: port ?? this.port,
    status: status ?? this.status,
    envJson: envJson ?? this.envJson,
    pid: pid.present ? pid.value : this.pid,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
  );
  JobRow copyWithCompanion(JobsCompanion data) {
    return JobRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      machineId: data.machineId.present ? data.machineId.value : this.machineId,
      command: data.command.present ? data.command.value : this.command,
      workingDir: data.workingDir.present
          ? data.workingDir.value
          : this.workingDir,
      port: data.port.present ? data.port.value : this.port,
      status: data.status.present ? data.status.value : this.status,
      envJson: data.envJson.present ? data.envJson.value : this.envJson,
      pid: data.pid.present ? data.pid.value : this.pid,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('machineId: $machineId, ')
          ..write('command: $command, ')
          ..write('workingDir: $workingDir, ')
          ..write('port: $port, ')
          ..write('status: $status, ')
          ..write('envJson: $envJson, ')
          ..write('pid: $pid, ')
          ..write('startedAt: $startedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    machineId,
    command,
    workingDir,
    port,
    status,
    envJson,
    pid,
    startedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.machineId == this.machineId &&
          other.command == this.command &&
          other.workingDir == this.workingDir &&
          other.port == this.port &&
          other.status == this.status &&
          other.envJson == this.envJson &&
          other.pid == this.pid &&
          other.startedAt == this.startedAt);
}

class JobsCompanion extends UpdateCompanion<JobRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> machineId;
  final Value<String> command;
  final Value<String?> workingDir;
  final Value<int> port;
  final Value<String> status;
  final Value<String> envJson;
  final Value<int?> pid;
  final Value<DateTime?> startedAt;
  final Value<int> rowid;
  const JobsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.machineId = const Value.absent(),
    this.command = const Value.absent(),
    this.workingDir = const Value.absent(),
    this.port = const Value.absent(),
    this.status = const Value.absent(),
    this.envJson = const Value.absent(),
    this.pid = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required String machineId,
    required String command,
    this.workingDir = const Value.absent(),
    required int port,
    required String status,
    this.envJson = const Value.absent(),
    this.pid = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       machineId = Value(machineId),
       command = Value(command),
       port = Value(port),
       status = Value(status);
  static Insertable<JobRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? machineId,
    Expression<String>? command,
    Expression<String>? workingDir,
    Expression<int>? port,
    Expression<String>? status,
    Expression<String>? envJson,
    Expression<int>? pid,
    Expression<DateTime>? startedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (machineId != null) 'machine_id': machineId,
      if (command != null) 'command': command,
      if (workingDir != null) 'working_dir': workingDir,
      if (port != null) 'port': port,
      if (status != null) 'status': status,
      if (envJson != null) 'env_json': envJson,
      if (pid != null) 'pid': pid,
      if (startedAt != null) 'started_at': startedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? machineId,
    Value<String>? command,
    Value<String?>? workingDir,
    Value<int>? port,
    Value<String>? status,
    Value<String>? envJson,
    Value<int?>? pid,
    Value<DateTime?>? startedAt,
    Value<int>? rowid,
  }) {
    return JobsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      machineId: machineId ?? this.machineId,
      command: command ?? this.command,
      workingDir: workingDir ?? this.workingDir,
      port: port ?? this.port,
      status: status ?? this.status,
      envJson: envJson ?? this.envJson,
      pid: pid ?? this.pid,
      startedAt: startedAt ?? this.startedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (machineId.present) {
      map['machine_id'] = Variable<String>(machineId.value);
    }
    if (command.present) {
      map['command'] = Variable<String>(command.value);
    }
    if (workingDir.present) {
      map['working_dir'] = Variable<String>(workingDir.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (envJson.present) {
      map['env_json'] = Variable<String>(envJson.value);
    }
    if (pid.present) {
      map['pid'] = Variable<int>(pid.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('machineId: $machineId, ')
          ..write('command: $command, ')
          ..write('workingDir: $workingDir, ')
          ..write('port: $port, ')
          ..write('status: $status, ')
          ..write('envJson: $envJson, ')
          ..write('pid: $pid, ')
          ..write('startedAt: $startedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BrowserHistoryEntriesTable extends BrowserHistoryEntries
    with TableInfo<$BrowserHistoryEntriesTable, BrowserHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrowserHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitedAtMeta = const VerificationMeta(
    'visitedAt',
  );
  @override
  late final GeneratedColumn<DateTime> visitedAt = GeneratedColumn<DateTime>(
    'visited_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [url, visitedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'browser_history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BrowserHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('visited_at')) {
      context.handle(
        _visitedAtMeta,
        visitedAt.isAcceptableOrUnknown(data['visited_at']!, _visitedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_visitedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {url};
  @override
  BrowserHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BrowserHistoryRow(
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      visitedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visited_at'],
      )!,
    );
  }

  @override
  $BrowserHistoryEntriesTable createAlias(String alias) {
    return $BrowserHistoryEntriesTable(attachedDatabase, alias);
  }
}

class BrowserHistoryRow extends DataClass
    implements Insertable<BrowserHistoryRow> {
  final String url;
  final DateTime visitedAt;
  const BrowserHistoryRow({required this.url, required this.visitedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['url'] = Variable<String>(url);
    map['visited_at'] = Variable<DateTime>(visitedAt);
    return map;
  }

  BrowserHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return BrowserHistoryEntriesCompanion(
      url: Value(url),
      visitedAt: Value(visitedAt),
    );
  }

  factory BrowserHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BrowserHistoryRow(
      url: serializer.fromJson<String>(json['url']),
      visitedAt: serializer.fromJson<DateTime>(json['visitedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'url': serializer.toJson<String>(url),
      'visitedAt': serializer.toJson<DateTime>(visitedAt),
    };
  }

  BrowserHistoryRow copyWith({String? url, DateTime? visitedAt}) =>
      BrowserHistoryRow(
        url: url ?? this.url,
        visitedAt: visitedAt ?? this.visitedAt,
      );
  BrowserHistoryRow copyWithCompanion(BrowserHistoryEntriesCompanion data) {
    return BrowserHistoryRow(
      url: data.url.present ? data.url.value : this.url,
      visitedAt: data.visitedAt.present ? data.visitedAt.value : this.visitedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BrowserHistoryRow(')
          ..write('url: $url, ')
          ..write('visitedAt: $visitedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(url, visitedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrowserHistoryRow &&
          other.url == this.url &&
          other.visitedAt == this.visitedAt);
}

class BrowserHistoryEntriesCompanion
    extends UpdateCompanion<BrowserHistoryRow> {
  final Value<String> url;
  final Value<DateTime> visitedAt;
  final Value<int> rowid;
  const BrowserHistoryEntriesCompanion({
    this.url = const Value.absent(),
    this.visitedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BrowserHistoryEntriesCompanion.insert({
    required String url,
    required DateTime visitedAt,
    this.rowid = const Value.absent(),
  }) : url = Value(url),
       visitedAt = Value(visitedAt);
  static Insertable<BrowserHistoryRow> custom({
    Expression<String>? url,
    Expression<DateTime>? visitedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (url != null) 'url': url,
      if (visitedAt != null) 'visited_at': visitedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BrowserHistoryEntriesCompanion copyWith({
    Value<String>? url,
    Value<DateTime>? visitedAt,
    Value<int>? rowid,
  }) {
    return BrowserHistoryEntriesCompanion(
      url: url ?? this.url,
      visitedAt: visitedAt ?? this.visitedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (visitedAt.present) {
      map['visited_at'] = Variable<DateTime>(visitedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrowserHistoryEntriesCompanion(')
          ..write('url: $url, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedBenchmarksTable extends SavedBenchmarks
    with TableInfo<$SavedBenchmarksTable, SavedBenchmarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedBenchmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _machineNameMeta = const VerificationMeta(
    'machineName',
  );
  @override
  late final GeneratedColumn<String> machineName = GeneratedColumn<String>(
    'machine_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commandMeta = const VerificationMeta(
    'command',
  );
  @override
  late final GeneratedColumn<String> command = GeneratedColumn<String>(
    'command',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchSizeMeta = const VerificationMeta(
    'batchSize',
  );
  @override
  late final GeneratedColumn<int> batchSize = GeneratedColumn<int>(
    'batch_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggregateTokensPerSecondMeta =
      const VerificationMeta('aggregateTokensPerSecond');
  @override
  late final GeneratedColumn<double> aggregateTokensPerSecond =
      GeneratedColumn<double>(
        'aggregate_tokens_per_second',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<int> completed = GeneratedColumn<int>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medianTtftMsMeta = const VerificationMeta(
    'medianTtftMs',
  );
  @override
  late final GeneratedColumn<int> medianTtftMs = GeneratedColumn<int>(
    'median_ttft_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestsJsonMeta = const VerificationMeta(
    'requestsJson',
  );
  @override
  late final GeneratedColumn<String> requestsJson = GeneratedColumn<String>(
    'requests_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _samplesJsonMeta = const VerificationMeta(
    'samplesJson',
  );
  @override
  late final GeneratedColumn<String> samplesJson = GeneratedColumn<String>(
    'samples_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    endpoint,
    machineName,
    command,
    prompt,
    batchSize,
    aggregateTokensPerSecond,
    completed,
    medianTtftMs,
    elapsedMs,
    createdAt,
    requestsJson,
    samplesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_benchmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedBenchmarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('machine_name')) {
      context.handle(
        _machineNameMeta,
        machineName.isAcceptableOrUnknown(
          data['machine_name']!,
          _machineNameMeta,
        ),
      );
    }
    if (data.containsKey('command')) {
      context.handle(
        _commandMeta,
        command.isAcceptableOrUnknown(data['command']!, _commandMeta),
      );
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('batch_size')) {
      context.handle(
        _batchSizeMeta,
        batchSize.isAcceptableOrUnknown(data['batch_size']!, _batchSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_batchSizeMeta);
    }
    if (data.containsKey('aggregate_tokens_per_second')) {
      context.handle(
        _aggregateTokensPerSecondMeta,
        aggregateTokensPerSecond.isAcceptableOrUnknown(
          data['aggregate_tokens_per_second']!,
          _aggregateTokensPerSecondMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggregateTokensPerSecondMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('median_ttft_ms')) {
      context.handle(
        _medianTtftMsMeta,
        medianTtftMs.isAcceptableOrUnknown(
          data['median_ttft_ms']!,
          _medianTtftMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medianTtftMsMeta);
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_elapsedMsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('requests_json')) {
      context.handle(
        _requestsJsonMeta,
        requestsJson.isAcceptableOrUnknown(
          data['requests_json']!,
          _requestsJsonMeta,
        ),
      );
    }
    if (data.containsKey('samples_json')) {
      context.handle(
        _samplesJsonMeta,
        samplesJson.isAcceptableOrUnknown(
          data['samples_json']!,
          _samplesJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedBenchmarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedBenchmarkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      machineName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_name'],
      ),
      command: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      batchSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batch_size'],
      )!,
      aggregateTokensPerSecond: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}aggregate_tokens_per_second'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed'],
      )!,
      medianTtftMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}median_ttft_ms'],
      )!,
      elapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_ms'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      requestsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requests_json'],
      )!,
      samplesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}samples_json'],
      )!,
    );
  }

  @override
  $SavedBenchmarksTable createAlias(String alias) {
    return $SavedBenchmarksTable(attachedDatabase, alias);
  }
}

class SavedBenchmarkRow extends DataClass
    implements Insertable<SavedBenchmarkRow> {
  final String id;
  final String name;
  final String endpoint;

  /// The machine it ran on, for display. Nullable: rows saved before this
  /// column existed fall back to the endpoint's host part.
  final String? machineName;

  /// The job's launch command at save time.
  final String command;
  final String prompt;
  final int batchSize;
  final double aggregateTokensPerSecond;
  final int completed;
  final int medianTtftMs;
  final int elapsedMs;
  final DateTime createdAt;

  /// JSON-encoded `List<BenchmarkRequest>` — the saved per-request responses.
  final String requestsJson;

  /// JSON-encoded `List<BenchmarkSample>` — the throughput time-series.
  final String samplesJson;
  const SavedBenchmarkRow({
    required this.id,
    required this.name,
    required this.endpoint,
    this.machineName,
    required this.command,
    required this.prompt,
    required this.batchSize,
    required this.aggregateTokensPerSecond,
    required this.completed,
    required this.medianTtftMs,
    required this.elapsedMs,
    required this.createdAt,
    required this.requestsJson,
    required this.samplesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['endpoint'] = Variable<String>(endpoint);
    if (!nullToAbsent || machineName != null) {
      map['machine_name'] = Variable<String>(machineName);
    }
    map['command'] = Variable<String>(command);
    map['prompt'] = Variable<String>(prompt);
    map['batch_size'] = Variable<int>(batchSize);
    map['aggregate_tokens_per_second'] = Variable<double>(
      aggregateTokensPerSecond,
    );
    map['completed'] = Variable<int>(completed);
    map['median_ttft_ms'] = Variable<int>(medianTtftMs);
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['requests_json'] = Variable<String>(requestsJson);
    map['samples_json'] = Variable<String>(samplesJson);
    return map;
  }

  SavedBenchmarksCompanion toCompanion(bool nullToAbsent) {
    return SavedBenchmarksCompanion(
      id: Value(id),
      name: Value(name),
      endpoint: Value(endpoint),
      machineName: machineName == null && nullToAbsent
          ? const Value.absent()
          : Value(machineName),
      command: Value(command),
      prompt: Value(prompt),
      batchSize: Value(batchSize),
      aggregateTokensPerSecond: Value(aggregateTokensPerSecond),
      completed: Value(completed),
      medianTtftMs: Value(medianTtftMs),
      elapsedMs: Value(elapsedMs),
      createdAt: Value(createdAt),
      requestsJson: Value(requestsJson),
      samplesJson: Value(samplesJson),
    );
  }

  factory SavedBenchmarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedBenchmarkRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      machineName: serializer.fromJson<String?>(json['machineName']),
      command: serializer.fromJson<String>(json['command']),
      prompt: serializer.fromJson<String>(json['prompt']),
      batchSize: serializer.fromJson<int>(json['batchSize']),
      aggregateTokensPerSecond: serializer.fromJson<double>(
        json['aggregateTokensPerSecond'],
      ),
      completed: serializer.fromJson<int>(json['completed']),
      medianTtftMs: serializer.fromJson<int>(json['medianTtftMs']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      requestsJson: serializer.fromJson<String>(json['requestsJson']),
      samplesJson: serializer.fromJson<String>(json['samplesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'endpoint': serializer.toJson<String>(endpoint),
      'machineName': serializer.toJson<String?>(machineName),
      'command': serializer.toJson<String>(command),
      'prompt': serializer.toJson<String>(prompt),
      'batchSize': serializer.toJson<int>(batchSize),
      'aggregateTokensPerSecond': serializer.toJson<double>(
        aggregateTokensPerSecond,
      ),
      'completed': serializer.toJson<int>(completed),
      'medianTtftMs': serializer.toJson<int>(medianTtftMs),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'requestsJson': serializer.toJson<String>(requestsJson),
      'samplesJson': serializer.toJson<String>(samplesJson),
    };
  }

  SavedBenchmarkRow copyWith({
    String? id,
    String? name,
    String? endpoint,
    Value<String?> machineName = const Value.absent(),
    String? command,
    String? prompt,
    int? batchSize,
    double? aggregateTokensPerSecond,
    int? completed,
    int? medianTtftMs,
    int? elapsedMs,
    DateTime? createdAt,
    String? requestsJson,
    String? samplesJson,
  }) => SavedBenchmarkRow(
    id: id ?? this.id,
    name: name ?? this.name,
    endpoint: endpoint ?? this.endpoint,
    machineName: machineName.present ? machineName.value : this.machineName,
    command: command ?? this.command,
    prompt: prompt ?? this.prompt,
    batchSize: batchSize ?? this.batchSize,
    aggregateTokensPerSecond:
        aggregateTokensPerSecond ?? this.aggregateTokensPerSecond,
    completed: completed ?? this.completed,
    medianTtftMs: medianTtftMs ?? this.medianTtftMs,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    createdAt: createdAt ?? this.createdAt,
    requestsJson: requestsJson ?? this.requestsJson,
    samplesJson: samplesJson ?? this.samplesJson,
  );
  SavedBenchmarkRow copyWithCompanion(SavedBenchmarksCompanion data) {
    return SavedBenchmarkRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      machineName: data.machineName.present
          ? data.machineName.value
          : this.machineName,
      command: data.command.present ? data.command.value : this.command,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      batchSize: data.batchSize.present ? data.batchSize.value : this.batchSize,
      aggregateTokensPerSecond: data.aggregateTokensPerSecond.present
          ? data.aggregateTokensPerSecond.value
          : this.aggregateTokensPerSecond,
      completed: data.completed.present ? data.completed.value : this.completed,
      medianTtftMs: data.medianTtftMs.present
          ? data.medianTtftMs.value
          : this.medianTtftMs,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      requestsJson: data.requestsJson.present
          ? data.requestsJson.value
          : this.requestsJson,
      samplesJson: data.samplesJson.present
          ? data.samplesJson.value
          : this.samplesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedBenchmarkRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('endpoint: $endpoint, ')
          ..write('machineName: $machineName, ')
          ..write('command: $command, ')
          ..write('prompt: $prompt, ')
          ..write('batchSize: $batchSize, ')
          ..write('aggregateTokensPerSecond: $aggregateTokensPerSecond, ')
          ..write('completed: $completed, ')
          ..write('medianTtftMs: $medianTtftMs, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('requestsJson: $requestsJson, ')
          ..write('samplesJson: $samplesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    endpoint,
    machineName,
    command,
    prompt,
    batchSize,
    aggregateTokensPerSecond,
    completed,
    medianTtftMs,
    elapsedMs,
    createdAt,
    requestsJson,
    samplesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedBenchmarkRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.endpoint == this.endpoint &&
          other.machineName == this.machineName &&
          other.command == this.command &&
          other.prompt == this.prompt &&
          other.batchSize == this.batchSize &&
          other.aggregateTokensPerSecond == this.aggregateTokensPerSecond &&
          other.completed == this.completed &&
          other.medianTtftMs == this.medianTtftMs &&
          other.elapsedMs == this.elapsedMs &&
          other.createdAt == this.createdAt &&
          other.requestsJson == this.requestsJson &&
          other.samplesJson == this.samplesJson);
}

class SavedBenchmarksCompanion extends UpdateCompanion<SavedBenchmarkRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> endpoint;
  final Value<String?> machineName;
  final Value<String> command;
  final Value<String> prompt;
  final Value<int> batchSize;
  final Value<double> aggregateTokensPerSecond;
  final Value<int> completed;
  final Value<int> medianTtftMs;
  final Value<int> elapsedMs;
  final Value<DateTime> createdAt;
  final Value<String> requestsJson;
  final Value<String> samplesJson;
  final Value<int> rowid;
  const SavedBenchmarksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.machineName = const Value.absent(),
    this.command = const Value.absent(),
    this.prompt = const Value.absent(),
    this.batchSize = const Value.absent(),
    this.aggregateTokensPerSecond = const Value.absent(),
    this.completed = const Value.absent(),
    this.medianTtftMs = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.requestsJson = const Value.absent(),
    this.samplesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedBenchmarksCompanion.insert({
    required String id,
    required String name,
    required String endpoint,
    this.machineName = const Value.absent(),
    this.command = const Value.absent(),
    required String prompt,
    required int batchSize,
    required double aggregateTokensPerSecond,
    required int completed,
    required int medianTtftMs,
    required int elapsedMs,
    required DateTime createdAt,
    this.requestsJson = const Value.absent(),
    this.samplesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       endpoint = Value(endpoint),
       prompt = Value(prompt),
       batchSize = Value(batchSize),
       aggregateTokensPerSecond = Value(aggregateTokensPerSecond),
       completed = Value(completed),
       medianTtftMs = Value(medianTtftMs),
       elapsedMs = Value(elapsedMs),
       createdAt = Value(createdAt);
  static Insertable<SavedBenchmarkRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? endpoint,
    Expression<String>? machineName,
    Expression<String>? command,
    Expression<String>? prompt,
    Expression<int>? batchSize,
    Expression<double>? aggregateTokensPerSecond,
    Expression<int>? completed,
    Expression<int>? medianTtftMs,
    Expression<int>? elapsedMs,
    Expression<DateTime>? createdAt,
    Expression<String>? requestsJson,
    Expression<String>? samplesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (endpoint != null) 'endpoint': endpoint,
      if (machineName != null) 'machine_name': machineName,
      if (command != null) 'command': command,
      if (prompt != null) 'prompt': prompt,
      if (batchSize != null) 'batch_size': batchSize,
      if (aggregateTokensPerSecond != null)
        'aggregate_tokens_per_second': aggregateTokensPerSecond,
      if (completed != null) 'completed': completed,
      if (medianTtftMs != null) 'median_ttft_ms': medianTtftMs,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (createdAt != null) 'created_at': createdAt,
      if (requestsJson != null) 'requests_json': requestsJson,
      if (samplesJson != null) 'samples_json': samplesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedBenchmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? endpoint,
    Value<String?>? machineName,
    Value<String>? command,
    Value<String>? prompt,
    Value<int>? batchSize,
    Value<double>? aggregateTokensPerSecond,
    Value<int>? completed,
    Value<int>? medianTtftMs,
    Value<int>? elapsedMs,
    Value<DateTime>? createdAt,
    Value<String>? requestsJson,
    Value<String>? samplesJson,
    Value<int>? rowid,
  }) {
    return SavedBenchmarksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      machineName: machineName ?? this.machineName,
      command: command ?? this.command,
      prompt: prompt ?? this.prompt,
      batchSize: batchSize ?? this.batchSize,
      aggregateTokensPerSecond:
          aggregateTokensPerSecond ?? this.aggregateTokensPerSecond,
      completed: completed ?? this.completed,
      medianTtftMs: medianTtftMs ?? this.medianTtftMs,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      createdAt: createdAt ?? this.createdAt,
      requestsJson: requestsJson ?? this.requestsJson,
      samplesJson: samplesJson ?? this.samplesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (machineName.present) {
      map['machine_name'] = Variable<String>(machineName.value);
    }
    if (command.present) {
      map['command'] = Variable<String>(command.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (batchSize.present) {
      map['batch_size'] = Variable<int>(batchSize.value);
    }
    if (aggregateTokensPerSecond.present) {
      map['aggregate_tokens_per_second'] = Variable<double>(
        aggregateTokensPerSecond.value,
      );
    }
    if (completed.present) {
      map['completed'] = Variable<int>(completed.value);
    }
    if (medianTtftMs.present) {
      map['median_ttft_ms'] = Variable<int>(medianTtftMs.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (requestsJson.present) {
      map['requests_json'] = Variable<String>(requestsJson.value);
    }
    if (samplesJson.present) {
      map['samples_json'] = Variable<String>(samplesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedBenchmarksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('endpoint: $endpoint, ')
          ..write('machineName: $machineName, ')
          ..write('command: $command, ')
          ..write('prompt: $prompt, ')
          ..write('batchSize: $batchSize, ')
          ..write('aggregateTokensPerSecond: $aggregateTokensPerSecond, ')
          ..write('completed: $completed, ')
          ..write('medianTtftMs: $medianTtftMs, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('requestsJson: $requestsJson, ')
          ..write('samplesJson: $samplesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MachinesTable machines = $MachinesTable(this);
  late final $LaunchConfigsTable launchConfigs = $LaunchConfigsTable(this);
  late final $JobsTable jobs = $JobsTable(this);
  late final $BrowserHistoryEntriesTable browserHistoryEntries =
      $BrowserHistoryEntriesTable(this);
  late final $SavedBenchmarksTable savedBenchmarks = $SavedBenchmarksTable(
    this,
  );
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    machines,
    launchConfigs,
    jobs,
    browserHistoryEntries,
    savedBenchmarks,
    settings,
  ];
}

typedef $$MachinesTableCreateCompanionBuilder =
    MachinesCompanion Function({
      required String id,
      required String name,
      required String address,
      Value<int> sshPort,
      Value<String?> user,
      Value<String?> sshKey,
      Value<String?> vendor,
      Value<String?> gpus,
      Value<String?> memory,
      Value<bool> online,
      Value<int> rowid,
    });
typedef $$MachinesTableUpdateCompanionBuilder =
    MachinesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> address,
      Value<int> sshPort,
      Value<String?> user,
      Value<String?> sshKey,
      Value<String?> vendor,
      Value<String?> gpus,
      Value<String?> memory,
      Value<bool> online,
      Value<int> rowid,
    });

class $$MachinesTableFilterComposer
    extends Composer<_$AppDatabase, $MachinesTable> {
  $$MachinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sshPort => $composableBuilder(
    column: $table.sshPort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get user => $composableBuilder(
    column: $table.user,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sshKey => $composableBuilder(
    column: $table.sshKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gpus => $composableBuilder(
    column: $table.gpus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memory => $composableBuilder(
    column: $table.memory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get online => $composableBuilder(
    column: $table.online,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MachinesTableOrderingComposer
    extends Composer<_$AppDatabase, $MachinesTable> {
  $$MachinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sshPort => $composableBuilder(
    column: $table.sshPort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get user => $composableBuilder(
    column: $table.user,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sshKey => $composableBuilder(
    column: $table.sshKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gpus => $composableBuilder(
    column: $table.gpus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memory => $composableBuilder(
    column: $table.memory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get online => $composableBuilder(
    column: $table.online,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MachinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MachinesTable> {
  $$MachinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get sshPort =>
      $composableBuilder(column: $table.sshPort, builder: (column) => column);

  GeneratedColumn<String> get user =>
      $composableBuilder(column: $table.user, builder: (column) => column);

  GeneratedColumn<String> get sshKey =>
      $composableBuilder(column: $table.sshKey, builder: (column) => column);

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get gpus =>
      $composableBuilder(column: $table.gpus, builder: (column) => column);

  GeneratedColumn<String> get memory =>
      $composableBuilder(column: $table.memory, builder: (column) => column);

  GeneratedColumn<bool> get online =>
      $composableBuilder(column: $table.online, builder: (column) => column);
}

class $$MachinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MachinesTable,
          MachineRow,
          $$MachinesTableFilterComposer,
          $$MachinesTableOrderingComposer,
          $$MachinesTableAnnotationComposer,
          $$MachinesTableCreateCompanionBuilder,
          $$MachinesTableUpdateCompanionBuilder,
          (
            MachineRow,
            BaseReferences<_$AppDatabase, $MachinesTable, MachineRow>,
          ),
          MachineRow,
          PrefetchHooks Function()
        > {
  $$MachinesTableTableManager(_$AppDatabase db, $MachinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MachinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MachinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MachinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<int> sshPort = const Value.absent(),
                Value<String?> user = const Value.absent(),
                Value<String?> sshKey = const Value.absent(),
                Value<String?> vendor = const Value.absent(),
                Value<String?> gpus = const Value.absent(),
                Value<String?> memory = const Value.absent(),
                Value<bool> online = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MachinesCompanion(
                id: id,
                name: name,
                address: address,
                sshPort: sshPort,
                user: user,
                sshKey: sshKey,
                vendor: vendor,
                gpus: gpus,
                memory: memory,
                online: online,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String address,
                Value<int> sshPort = const Value.absent(),
                Value<String?> user = const Value.absent(),
                Value<String?> sshKey = const Value.absent(),
                Value<String?> vendor = const Value.absent(),
                Value<String?> gpus = const Value.absent(),
                Value<String?> memory = const Value.absent(),
                Value<bool> online = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MachinesCompanion.insert(
                id: id,
                name: name,
                address: address,
                sshPort: sshPort,
                user: user,
                sshKey: sshKey,
                vendor: vendor,
                gpus: gpus,
                memory: memory,
                online: online,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MachinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MachinesTable,
      MachineRow,
      $$MachinesTableFilterComposer,
      $$MachinesTableOrderingComposer,
      $$MachinesTableAnnotationComposer,
      $$MachinesTableCreateCompanionBuilder,
      $$MachinesTableUpdateCompanionBuilder,
      (MachineRow, BaseReferences<_$AppDatabase, $MachinesTable, MachineRow>),
      MachineRow,
      PrefetchHooks Function()
    >;
typedef $$LaunchConfigsTableCreateCompanionBuilder =
    LaunchConfigsCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required String machineId,
      required String command,
      Value<String?> workingDir,
      required int port,
      Value<String> envJson,
      Value<int> rowid,
    });
typedef $$LaunchConfigsTableUpdateCompanionBuilder =
    LaunchConfigsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String> machineId,
      Value<String> command,
      Value<String?> workingDir,
      Value<int> port,
      Value<String> envJson,
      Value<int> rowid,
    });

class $$LaunchConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $LaunchConfigsTable> {
  $$LaunchConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machineId => $composableBuilder(
    column: $table.machineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workingDir => $composableBuilder(
    column: $table.workingDir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get envJson => $composableBuilder(
    column: $table.envJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LaunchConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $LaunchConfigsTable> {
  $$LaunchConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineId => $composableBuilder(
    column: $table.machineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workingDir => $composableBuilder(
    column: $table.workingDir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get envJson => $composableBuilder(
    column: $table.envJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LaunchConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LaunchConfigsTable> {
  $$LaunchConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get machineId =>
      $composableBuilder(column: $table.machineId, builder: (column) => column);

  GeneratedColumn<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => column);

  GeneratedColumn<String> get workingDir => $composableBuilder(
    column: $table.workingDir,
    builder: (column) => column,
  );

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get envJson =>
      $composableBuilder(column: $table.envJson, builder: (column) => column);
}

class $$LaunchConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LaunchConfigsTable,
          LaunchConfigRow,
          $$LaunchConfigsTableFilterComposer,
          $$LaunchConfigsTableOrderingComposer,
          $$LaunchConfigsTableAnnotationComposer,
          $$LaunchConfigsTableCreateCompanionBuilder,
          $$LaunchConfigsTableUpdateCompanionBuilder,
          (
            LaunchConfigRow,
            BaseReferences<_$AppDatabase, $LaunchConfigsTable, LaunchConfigRow>,
          ),
          LaunchConfigRow,
          PrefetchHooks Function()
        > {
  $$LaunchConfigsTableTableManager(_$AppDatabase db, $LaunchConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LaunchConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LaunchConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LaunchConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> machineId = const Value.absent(),
                Value<String> command = const Value.absent(),
                Value<String?> workingDir = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String> envJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LaunchConfigsCompanion(
                id: id,
                name: name,
                description: description,
                machineId: machineId,
                command: command,
                workingDir: workingDir,
                port: port,
                envJson: envJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required String machineId,
                required String command,
                Value<String?> workingDir = const Value.absent(),
                required int port,
                Value<String> envJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LaunchConfigsCompanion.insert(
                id: id,
                name: name,
                description: description,
                machineId: machineId,
                command: command,
                workingDir: workingDir,
                port: port,
                envJson: envJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LaunchConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LaunchConfigsTable,
      LaunchConfigRow,
      $$LaunchConfigsTableFilterComposer,
      $$LaunchConfigsTableOrderingComposer,
      $$LaunchConfigsTableAnnotationComposer,
      $$LaunchConfigsTableCreateCompanionBuilder,
      $$LaunchConfigsTableUpdateCompanionBuilder,
      (
        LaunchConfigRow,
        BaseReferences<_$AppDatabase, $LaunchConfigsTable, LaunchConfigRow>,
      ),
      LaunchConfigRow,
      PrefetchHooks Function()
    >;
typedef $$JobsTableCreateCompanionBuilder =
    JobsCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required String machineId,
      required String command,
      Value<String?> workingDir,
      required int port,
      required String status,
      Value<String> envJson,
      Value<int?> pid,
      Value<DateTime?> startedAt,
      Value<int> rowid,
    });
typedef $$JobsTableUpdateCompanionBuilder =
    JobsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String> machineId,
      Value<String> command,
      Value<String?> workingDir,
      Value<int> port,
      Value<String> status,
      Value<String> envJson,
      Value<int?> pid,
      Value<DateTime?> startedAt,
      Value<int> rowid,
    });

class $$JobsTableFilterComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machineId => $composableBuilder(
    column: $table.machineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workingDir => $composableBuilder(
    column: $table.workingDir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get envJson => $composableBuilder(
    column: $table.envJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pid => $composableBuilder(
    column: $table.pid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JobsTableOrderingComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineId => $composableBuilder(
    column: $table.machineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workingDir => $composableBuilder(
    column: $table.workingDir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get envJson => $composableBuilder(
    column: $table.envJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pid => $composableBuilder(
    column: $table.pid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get machineId =>
      $composableBuilder(column: $table.machineId, builder: (column) => column);

  GeneratedColumn<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => column);

  GeneratedColumn<String> get workingDir => $composableBuilder(
    column: $table.workingDir,
    builder: (column) => column,
  );

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get envJson =>
      $composableBuilder(column: $table.envJson, builder: (column) => column);

  GeneratedColumn<int> get pid =>
      $composableBuilder(column: $table.pid, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);
}

class $$JobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobsTable,
          JobRow,
          $$JobsTableFilterComposer,
          $$JobsTableOrderingComposer,
          $$JobsTableAnnotationComposer,
          $$JobsTableCreateCompanionBuilder,
          $$JobsTableUpdateCompanionBuilder,
          (JobRow, BaseReferences<_$AppDatabase, $JobsTable, JobRow>),
          JobRow,
          PrefetchHooks Function()
        > {
  $$JobsTableTableManager(_$AppDatabase db, $JobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> machineId = const Value.absent(),
                Value<String> command = const Value.absent(),
                Value<String?> workingDir = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> envJson = const Value.absent(),
                Value<int?> pid = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobsCompanion(
                id: id,
                name: name,
                description: description,
                machineId: machineId,
                command: command,
                workingDir: workingDir,
                port: port,
                status: status,
                envJson: envJson,
                pid: pid,
                startedAt: startedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required String machineId,
                required String command,
                Value<String?> workingDir = const Value.absent(),
                required int port,
                required String status,
                Value<String> envJson = const Value.absent(),
                Value<int?> pid = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobsCompanion.insert(
                id: id,
                name: name,
                description: description,
                machineId: machineId,
                command: command,
                workingDir: workingDir,
                port: port,
                status: status,
                envJson: envJson,
                pid: pid,
                startedAt: startedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobsTable,
      JobRow,
      $$JobsTableFilterComposer,
      $$JobsTableOrderingComposer,
      $$JobsTableAnnotationComposer,
      $$JobsTableCreateCompanionBuilder,
      $$JobsTableUpdateCompanionBuilder,
      (JobRow, BaseReferences<_$AppDatabase, $JobsTable, JobRow>),
      JobRow,
      PrefetchHooks Function()
    >;
typedef $$BrowserHistoryEntriesTableCreateCompanionBuilder =
    BrowserHistoryEntriesCompanion Function({
      required String url,
      required DateTime visitedAt,
      Value<int> rowid,
    });
typedef $$BrowserHistoryEntriesTableUpdateCompanionBuilder =
    BrowserHistoryEntriesCompanion Function({
      Value<String> url,
      Value<DateTime> visitedAt,
      Value<int> rowid,
    });

class $$BrowserHistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BrowserHistoryEntriesTable> {
  $$BrowserHistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BrowserHistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BrowserHistoryEntriesTable> {
  $$BrowserHistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BrowserHistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrowserHistoryEntriesTable> {
  $$BrowserHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<DateTime> get visitedAt =>
      $composableBuilder(column: $table.visitedAt, builder: (column) => column);
}

class $$BrowserHistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrowserHistoryEntriesTable,
          BrowserHistoryRow,
          $$BrowserHistoryEntriesTableFilterComposer,
          $$BrowserHistoryEntriesTableOrderingComposer,
          $$BrowserHistoryEntriesTableAnnotationComposer,
          $$BrowserHistoryEntriesTableCreateCompanionBuilder,
          $$BrowserHistoryEntriesTableUpdateCompanionBuilder,
          (
            BrowserHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $BrowserHistoryEntriesTable,
              BrowserHistoryRow
            >,
          ),
          BrowserHistoryRow,
          PrefetchHooks Function()
        > {
  $$BrowserHistoryEntriesTableTableManager(
    _$AppDatabase db,
    $BrowserHistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrowserHistoryEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BrowserHistoryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BrowserHistoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> url = const Value.absent(),
                Value<DateTime> visitedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BrowserHistoryEntriesCompanion(
                url: url,
                visitedAt: visitedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String url,
                required DateTime visitedAt,
                Value<int> rowid = const Value.absent(),
              }) => BrowserHistoryEntriesCompanion.insert(
                url: url,
                visitedAt: visitedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BrowserHistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrowserHistoryEntriesTable,
      BrowserHistoryRow,
      $$BrowserHistoryEntriesTableFilterComposer,
      $$BrowserHistoryEntriesTableOrderingComposer,
      $$BrowserHistoryEntriesTableAnnotationComposer,
      $$BrowserHistoryEntriesTableCreateCompanionBuilder,
      $$BrowserHistoryEntriesTableUpdateCompanionBuilder,
      (
        BrowserHistoryRow,
        BaseReferences<
          _$AppDatabase,
          $BrowserHistoryEntriesTable,
          BrowserHistoryRow
        >,
      ),
      BrowserHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$SavedBenchmarksTableCreateCompanionBuilder =
    SavedBenchmarksCompanion Function({
      required String id,
      required String name,
      required String endpoint,
      Value<String?> machineName,
      Value<String> command,
      required String prompt,
      required int batchSize,
      required double aggregateTokensPerSecond,
      required int completed,
      required int medianTtftMs,
      required int elapsedMs,
      required DateTime createdAt,
      Value<String> requestsJson,
      Value<String> samplesJson,
      Value<int> rowid,
    });
typedef $$SavedBenchmarksTableUpdateCompanionBuilder =
    SavedBenchmarksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> endpoint,
      Value<String?> machineName,
      Value<String> command,
      Value<String> prompt,
      Value<int> batchSize,
      Value<double> aggregateTokensPerSecond,
      Value<int> completed,
      Value<int> medianTtftMs,
      Value<int> elapsedMs,
      Value<DateTime> createdAt,
      Value<String> requestsJson,
      Value<String> samplesJson,
      Value<int> rowid,
    });

class $$SavedBenchmarksTableFilterComposer
    extends Composer<_$AppDatabase, $SavedBenchmarksTable> {
  $$SavedBenchmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machineName => $composableBuilder(
    column: $table.machineName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batchSize => $composableBuilder(
    column: $table.batchSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get aggregateTokensPerSecond => $composableBuilder(
    column: $table.aggregateTokensPerSecond,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get medianTtftMs => $composableBuilder(
    column: $table.medianTtftMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestsJson => $composableBuilder(
    column: $table.requestsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get samplesJson => $composableBuilder(
    column: $table.samplesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedBenchmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedBenchmarksTable> {
  $$SavedBenchmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineName => $composableBuilder(
    column: $table.machineName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batchSize => $composableBuilder(
    column: $table.batchSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get aggregateTokensPerSecond => $composableBuilder(
    column: $table.aggregateTokensPerSecond,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get medianTtftMs => $composableBuilder(
    column: $table.medianTtftMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestsJson => $composableBuilder(
    column: $table.requestsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get samplesJson => $composableBuilder(
    column: $table.samplesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedBenchmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedBenchmarksTable> {
  $$SavedBenchmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get machineName => $composableBuilder(
    column: $table.machineName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<int> get batchSize =>
      $composableBuilder(column: $table.batchSize, builder: (column) => column);

  GeneratedColumn<double> get aggregateTokensPerSecond => $composableBuilder(
    column: $table.aggregateTokensPerSecond,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get medianTtftMs => $composableBuilder(
    column: $table.medianTtftMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get requestsJson => $composableBuilder(
    column: $table.requestsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get samplesJson => $composableBuilder(
    column: $table.samplesJson,
    builder: (column) => column,
  );
}

class $$SavedBenchmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedBenchmarksTable,
          SavedBenchmarkRow,
          $$SavedBenchmarksTableFilterComposer,
          $$SavedBenchmarksTableOrderingComposer,
          $$SavedBenchmarksTableAnnotationComposer,
          $$SavedBenchmarksTableCreateCompanionBuilder,
          $$SavedBenchmarksTableUpdateCompanionBuilder,
          (
            SavedBenchmarkRow,
            BaseReferences<
              _$AppDatabase,
              $SavedBenchmarksTable,
              SavedBenchmarkRow
            >,
          ),
          SavedBenchmarkRow,
          PrefetchHooks Function()
        > {
  $$SavedBenchmarksTableTableManager(
    _$AppDatabase db,
    $SavedBenchmarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedBenchmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedBenchmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedBenchmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String?> machineName = const Value.absent(),
                Value<String> command = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<int> batchSize = const Value.absent(),
                Value<double> aggregateTokensPerSecond = const Value.absent(),
                Value<int> completed = const Value.absent(),
                Value<int> medianTtftMs = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> requestsJson = const Value.absent(),
                Value<String> samplesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedBenchmarksCompanion(
                id: id,
                name: name,
                endpoint: endpoint,
                machineName: machineName,
                command: command,
                prompt: prompt,
                batchSize: batchSize,
                aggregateTokensPerSecond: aggregateTokensPerSecond,
                completed: completed,
                medianTtftMs: medianTtftMs,
                elapsedMs: elapsedMs,
                createdAt: createdAt,
                requestsJson: requestsJson,
                samplesJson: samplesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String endpoint,
                Value<String?> machineName = const Value.absent(),
                Value<String> command = const Value.absent(),
                required String prompt,
                required int batchSize,
                required double aggregateTokensPerSecond,
                required int completed,
                required int medianTtftMs,
                required int elapsedMs,
                required DateTime createdAt,
                Value<String> requestsJson = const Value.absent(),
                Value<String> samplesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedBenchmarksCompanion.insert(
                id: id,
                name: name,
                endpoint: endpoint,
                machineName: machineName,
                command: command,
                prompt: prompt,
                batchSize: batchSize,
                aggregateTokensPerSecond: aggregateTokensPerSecond,
                completed: completed,
                medianTtftMs: medianTtftMs,
                elapsedMs: elapsedMs,
                createdAt: createdAt,
                requestsJson: requestsJson,
                samplesJson: samplesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedBenchmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedBenchmarksTable,
      SavedBenchmarkRow,
      $$SavedBenchmarksTableFilterComposer,
      $$SavedBenchmarksTableOrderingComposer,
      $$SavedBenchmarksTableAnnotationComposer,
      $$SavedBenchmarksTableCreateCompanionBuilder,
      $$SavedBenchmarksTableUpdateCompanionBuilder,
      (
        SavedBenchmarkRow,
        BaseReferences<_$AppDatabase, $SavedBenchmarksTable, SavedBenchmarkRow>,
      ),
      SavedBenchmarkRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MachinesTableTableManager get machines =>
      $$MachinesTableTableManager(_db, _db.machines);
  $$LaunchConfigsTableTableManager get launchConfigs =>
      $$LaunchConfigsTableTableManager(_db, _db.launchConfigs);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
  $$BrowserHistoryEntriesTableTableManager get browserHistoryEntries =>
      $$BrowserHistoryEntriesTableTableManager(_db, _db.browserHistoryEntries);
  $$SavedBenchmarksTableTableManager get savedBenchmarks =>
      $$SavedBenchmarksTableTableManager(_db, _db.savedBenchmarks);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
