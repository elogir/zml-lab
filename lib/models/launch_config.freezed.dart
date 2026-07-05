// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'launch_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LaunchConfig {

 String get id; String get name; String? get description; String get machineId; String get command; String? get workingDir; int get port; List<EnvVar> get env;
/// Create a copy of LaunchConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LaunchConfigCopyWith<LaunchConfig> get copyWith => _$LaunchConfigCopyWithImpl<LaunchConfig>(this as LaunchConfig, _$identity);

  /// Serializes this LaunchConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LaunchConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.machineId, machineId) || other.machineId == machineId)&&(identical(other.command, command) || other.command == command)&&(identical(other.workingDir, workingDir) || other.workingDir == workingDir)&&(identical(other.port, port) || other.port == port)&&const DeepCollectionEquality().equals(other.env, env));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,machineId,command,workingDir,port,const DeepCollectionEquality().hash(env));

@override
String toString() {
  return 'LaunchConfig(id: $id, name: $name, description: $description, machineId: $machineId, command: $command, workingDir: $workingDir, port: $port, env: $env)';
}


}

/// @nodoc
abstract mixin class $LaunchConfigCopyWith<$Res>  {
  factory $LaunchConfigCopyWith(LaunchConfig value, $Res Function(LaunchConfig) _then) = _$LaunchConfigCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, String machineId, String command, String? workingDir, int port, List<EnvVar> env
});




}
/// @nodoc
class _$LaunchConfigCopyWithImpl<$Res>
    implements $LaunchConfigCopyWith<$Res> {
  _$LaunchConfigCopyWithImpl(this._self, this._then);

  final LaunchConfig _self;
  final $Res Function(LaunchConfig) _then;

/// Create a copy of LaunchConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? machineId = null,Object? command = null,Object? workingDir = freezed,Object? port = null,Object? env = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,machineId: null == machineId ? _self.machineId : machineId // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,workingDir: freezed == workingDir ? _self.workingDir : workingDir // ignore: cast_nullable_to_non_nullable
as String?,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,env: null == env ? _self.env : env // ignore: cast_nullable_to_non_nullable
as List<EnvVar>,
  ));
}

}


/// Adds pattern-matching-related methods to [LaunchConfig].
extension LaunchConfigPatterns on LaunchConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LaunchConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LaunchConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LaunchConfig value)  $default,){
final _that = this;
switch (_that) {
case _LaunchConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LaunchConfig value)?  $default,){
final _that = this;
switch (_that) {
case _LaunchConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String machineId,  String command,  String? workingDir,  int port,  List<EnvVar> env)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LaunchConfig() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.machineId,_that.command,_that.workingDir,_that.port,_that.env);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String machineId,  String command,  String? workingDir,  int port,  List<EnvVar> env)  $default,) {final _that = this;
switch (_that) {
case _LaunchConfig():
return $default(_that.id,_that.name,_that.description,_that.machineId,_that.command,_that.workingDir,_that.port,_that.env);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  String machineId,  String command,  String? workingDir,  int port,  List<EnvVar> env)?  $default,) {final _that = this;
switch (_that) {
case _LaunchConfig() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.machineId,_that.command,_that.workingDir,_that.port,_that.env);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LaunchConfig implements LaunchConfig {
  const _LaunchConfig({required this.id, required this.name, this.description, required this.machineId, required this.command, this.workingDir, required this.port, final  List<EnvVar> env = const <EnvVar>[]}): _env = env;
  factory _LaunchConfig.fromJson(Map<String, dynamic> json) => _$LaunchConfigFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  String machineId;
@override final  String command;
@override final  String? workingDir;
@override final  int port;
 final  List<EnvVar> _env;
@override@JsonKey() List<EnvVar> get env {
  if (_env is EqualUnmodifiableListView) return _env;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_env);
}


/// Create a copy of LaunchConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LaunchConfigCopyWith<_LaunchConfig> get copyWith => __$LaunchConfigCopyWithImpl<_LaunchConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LaunchConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LaunchConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.machineId, machineId) || other.machineId == machineId)&&(identical(other.command, command) || other.command == command)&&(identical(other.workingDir, workingDir) || other.workingDir == workingDir)&&(identical(other.port, port) || other.port == port)&&const DeepCollectionEquality().equals(other._env, _env));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,machineId,command,workingDir,port,const DeepCollectionEquality().hash(_env));

@override
String toString() {
  return 'LaunchConfig(id: $id, name: $name, description: $description, machineId: $machineId, command: $command, workingDir: $workingDir, port: $port, env: $env)';
}


}

/// @nodoc
abstract mixin class _$LaunchConfigCopyWith<$Res> implements $LaunchConfigCopyWith<$Res> {
  factory _$LaunchConfigCopyWith(_LaunchConfig value, $Res Function(_LaunchConfig) _then) = __$LaunchConfigCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, String machineId, String command, String? workingDir, int port, List<EnvVar> env
});




}
/// @nodoc
class __$LaunchConfigCopyWithImpl<$Res>
    implements _$LaunchConfigCopyWith<$Res> {
  __$LaunchConfigCopyWithImpl(this._self, this._then);

  final _LaunchConfig _self;
  final $Res Function(_LaunchConfig) _then;

/// Create a copy of LaunchConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? machineId = null,Object? command = null,Object? workingDir = freezed,Object? port = null,Object? env = null,}) {
  return _then(_LaunchConfig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,machineId: null == machineId ? _self.machineId : machineId // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,workingDir: freezed == workingDir ? _self.workingDir : workingDir // ignore: cast_nullable_to_non_nullable
as String?,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,env: null == env ? _self._env : env // ignore: cast_nullable_to_non_nullable
as List<EnvVar>,
  ));
}


}

// dart format on
