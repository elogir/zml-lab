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
  static const VerificationMeta _programMeta = const VerificationMeta(
    'program',
  );
  @override
  late final GeneratedColumn<String> program = GeneratedColumn<String>(
    'program',
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
    program,
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
    if (data.containsKey('program')) {
      context.handle(
        _programMeta,
        program.isAcceptableOrUnknown(data['program']!, _programMeta),
      );
    } else if (isInserting) {
      context.missing(_programMeta);
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
      program: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program'],
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
  final String program;
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
    required this.program,
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
    map['program'] = Variable<String>(program);
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
      program: Value(program),
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
      program: serializer.fromJson<String>(json['program']),
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
      'program': serializer.toJson<String>(program),
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
    String? program,
    String? command,
    Value<String?> workingDir = const Value.absent(),
    int? port,
    String? envJson,
  }) => LaunchConfigRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    machineId: machineId ?? this.machineId,
    program: program ?? this.program,
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
      program: data.program.present ? data.program.value : this.program,
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
          ..write('program: $program, ')
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
    program,
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
          other.program == this.program &&
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
  final Value<String> program;
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
    this.program = const Value.absent(),
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
    required String program,
    required String command,
    this.workingDir = const Value.absent(),
    required int port,
    this.envJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       machineId = Value(machineId),
       program = Value(program),
       command = Value(command),
       port = Value(port);
  static Insertable<LaunchConfigRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? machineId,
    Expression<String>? program,
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
      if (program != null) 'program': program,
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
    Value<String>? program,
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
      program: program ?? this.program,
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
    if (program.present) {
      map['program'] = Variable<String>(program.value);
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
          ..write('program: $program, ')
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
  static const VerificationMeta _programMeta = const VerificationMeta(
    'program',
  );
  @override
  late final GeneratedColumn<String> program = GeneratedColumn<String>(
    'program',
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
    program,
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
    if (data.containsKey('program')) {
      context.handle(
        _programMeta,
        program.isAcceptableOrUnknown(data['program']!, _programMeta),
      );
    } else if (isInserting) {
      context.missing(_programMeta);
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
      program: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program'],
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
  final String program;
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
    required this.program,
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
    map['program'] = Variable<String>(program);
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
      program: Value(program),
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
      program: serializer.fromJson<String>(json['program']),
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
      'program': serializer.toJson<String>(program),
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
    String? program,
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
    program: program ?? this.program,
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
      program: data.program.present ? data.program.value : this.program,
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
          ..write('program: $program, ')
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
    program,
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
          other.program == this.program &&
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
  final Value<String> program;
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
    this.program = const Value.absent(),
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
    required String program,
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
       program = Value(program),
       command = Value(command),
       port = Value(port),
       status = Value(status);
  static Insertable<JobRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? machineId,
    Expression<String>? program,
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
      if (program != null) 'program': program,
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
    Value<String>? program,
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
      program: program ?? this.program,
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
    if (program.present) {
      map['program'] = Variable<String>(program.value);
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
          ..write('program: $program, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MachinesTable machines = $MachinesTable(this);
  late final $LaunchConfigsTable launchConfigs = $LaunchConfigsTable(this);
  late final $JobsTable jobs = $JobsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    machines,
    launchConfigs,
    jobs,
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
      required String program,
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
      Value<String> program,
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

  ColumnFilters<String> get program => $composableBuilder(
    column: $table.program,
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

  ColumnOrderings<String> get program => $composableBuilder(
    column: $table.program,
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

  GeneratedColumn<String> get program =>
      $composableBuilder(column: $table.program, builder: (column) => column);

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
                Value<String> program = const Value.absent(),
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
                program: program,
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
                required String program,
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
                program: program,
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
      required String program,
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
      Value<String> program,
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

  ColumnFilters<String> get program => $composableBuilder(
    column: $table.program,
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

  ColumnOrderings<String> get program => $composableBuilder(
    column: $table.program,
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

  GeneratedColumn<String> get program =>
      $composableBuilder(column: $table.program, builder: (column) => column);

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
                Value<String> program = const Value.absent(),
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
                program: program,
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
                required String program,
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
                program: program,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MachinesTableTableManager get machines =>
      $$MachinesTableTableManager(_db, _db.machines);
  $$LaunchConfigsTableTableManager get launchConfigs =>
      $$LaunchConfigsTableTableManager(_db, _db.launchConfigs);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
}
