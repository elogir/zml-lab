// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Job {

 String get id; String get name; String? get description; String get machineId; String get command; String? get workingDir; int get port; JobStatus get status; List<EnvVar> get env;/// The saved config this job was launched from, if any — so editing the
/// job can offer to push the change back to that config.
 String? get configId; int? get pid; DateTime? get startedAt;
/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobCopyWith<Job> get copyWith => _$JobCopyWithImpl<Job>(this as Job, _$identity);

  /// Serializes this Job to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Job&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.machineId, machineId) || other.machineId == machineId)&&(identical(other.command, command) || other.command == command)&&(identical(other.workingDir, workingDir) || other.workingDir == workingDir)&&(identical(other.port, port) || other.port == port)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.env, env)&&(identical(other.configId, configId) || other.configId == configId)&&(identical(other.pid, pid) || other.pid == pid)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,machineId,command,workingDir,port,status,const DeepCollectionEquality().hash(env),configId,pid,startedAt);

@override
String toString() {
  return 'Job(id: $id, name: $name, description: $description, machineId: $machineId, command: $command, workingDir: $workingDir, port: $port, status: $status, env: $env, configId: $configId, pid: $pid, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class $JobCopyWith<$Res>  {
  factory $JobCopyWith(Job value, $Res Function(Job) _then) = _$JobCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, String machineId, String command, String? workingDir, int port, JobStatus status, List<EnvVar> env, String? configId, int? pid, DateTime? startedAt
});




}
/// @nodoc
class _$JobCopyWithImpl<$Res>
    implements $JobCopyWith<$Res> {
  _$JobCopyWithImpl(this._self, this._then);

  final Job _self;
  final $Res Function(Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? machineId = null,Object? command = null,Object? workingDir = freezed,Object? port = null,Object? status = null,Object? env = null,Object? configId = freezed,Object? pid = freezed,Object? startedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,machineId: null == machineId ? _self.machineId : machineId // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,workingDir: freezed == workingDir ? _self.workingDir : workingDir // ignore: cast_nullable_to_non_nullable
as String?,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,env: null == env ? _self.env : env // ignore: cast_nullable_to_non_nullable
as List<EnvVar>,configId: freezed == configId ? _self.configId : configId // ignore: cast_nullable_to_non_nullable
as String?,pid: freezed == pid ? _self.pid : pid // ignore: cast_nullable_to_non_nullable
as int?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Job].
extension JobPatterns on Job {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Job value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Job value)  $default,){
final _that = this;
switch (_that) {
case _Job():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Job value)?  $default,){
final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String machineId,  String command,  String? workingDir,  int port,  JobStatus status,  List<EnvVar> env,  String? configId,  int? pid,  DateTime? startedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.machineId,_that.command,_that.workingDir,_that.port,_that.status,_that.env,_that.configId,_that.pid,_that.startedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String machineId,  String command,  String? workingDir,  int port,  JobStatus status,  List<EnvVar> env,  String? configId,  int? pid,  DateTime? startedAt)  $default,) {final _that = this;
switch (_that) {
case _Job():
return $default(_that.id,_that.name,_that.description,_that.machineId,_that.command,_that.workingDir,_that.port,_that.status,_that.env,_that.configId,_that.pid,_that.startedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  String machineId,  String command,  String? workingDir,  int port,  JobStatus status,  List<EnvVar> env,  String? configId,  int? pid,  DateTime? startedAt)?  $default,) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.machineId,_that.command,_that.workingDir,_that.port,_that.status,_that.env,_that.configId,_that.pid,_that.startedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Job extends Job {
  const _Job({required this.id, required this.name, this.description, required this.machineId, required this.command, this.workingDir, required this.port, required this.status, final  List<EnvVar> env = const <EnvVar>[], this.configId, this.pid, this.startedAt}): _env = env,super._();
  factory _Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  String machineId;
@override final  String command;
@override final  String? workingDir;
@override final  int port;
@override final  JobStatus status;
 final  List<EnvVar> _env;
@override@JsonKey() List<EnvVar> get env {
  if (_env is EqualUnmodifiableListView) return _env;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_env);
}

/// The saved config this job was launched from, if any — so editing the
/// job can offer to push the change back to that config.
@override final  String? configId;
@override final  int? pid;
@override final  DateTime? startedAt;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobCopyWith<_Job> get copyWith => __$JobCopyWithImpl<_Job>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Job&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.machineId, machineId) || other.machineId == machineId)&&(identical(other.command, command) || other.command == command)&&(identical(other.workingDir, workingDir) || other.workingDir == workingDir)&&(identical(other.port, port) || other.port == port)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._env, _env)&&(identical(other.configId, configId) || other.configId == configId)&&(identical(other.pid, pid) || other.pid == pid)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,machineId,command,workingDir,port,status,const DeepCollectionEquality().hash(_env),configId,pid,startedAt);

@override
String toString() {
  return 'Job(id: $id, name: $name, description: $description, machineId: $machineId, command: $command, workingDir: $workingDir, port: $port, status: $status, env: $env, configId: $configId, pid: $pid, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class _$JobCopyWith<$Res> implements $JobCopyWith<$Res> {
  factory _$JobCopyWith(_Job value, $Res Function(_Job) _then) = __$JobCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, String machineId, String command, String? workingDir, int port, JobStatus status, List<EnvVar> env, String? configId, int? pid, DateTime? startedAt
});




}
/// @nodoc
class __$JobCopyWithImpl<$Res>
    implements _$JobCopyWith<$Res> {
  __$JobCopyWithImpl(this._self, this._then);

  final _Job _self;
  final $Res Function(_Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? machineId = null,Object? command = null,Object? workingDir = freezed,Object? port = null,Object? status = null,Object? env = null,Object? configId = freezed,Object? pid = freezed,Object? startedAt = freezed,}) {
  return _then(_Job(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,machineId: null == machineId ? _self.machineId : machineId // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,workingDir: freezed == workingDir ? _self.workingDir : workingDir // ignore: cast_nullable_to_non_nullable
as String?,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,env: null == env ? _self._env : env // ignore: cast_nullable_to_non_nullable
as List<EnvVar>,configId: freezed == configId ? _self.configId : configId // ignore: cast_nullable_to_non_nullable
as String?,pid: freezed == pid ? _self.pid : pid // ignore: cast_nullable_to_non_nullable
as int?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
