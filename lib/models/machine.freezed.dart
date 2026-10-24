// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'machine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Machine {

 String get id; String get name; String get address; Vendor? get vendor; String? get gpus; String? get memory; bool get online;
/// Create a copy of Machine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MachineCopyWith<Machine> get copyWith => _$MachineCopyWithImpl<Machine>(this as Machine, _$identity);

  /// Serializes this Machine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Machine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Machine&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.vendor, _this.vendor) || other.vendor == _this.vendor)&&(identical(other.gpus, _this.gpus) || other.gpus == _this.gpus)&&(identical(other.memory, _this.memory) || other.memory == _this.memory)&&(identical(other.online, _this.online) || other.online == _this.online));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Machine;
  return Object.hash(runtimeType,_this.id,_this.name,_this.address,_this.vendor,_this.gpus,_this.memory,_this.online);
}

@override
String toString() {
  final _this = this as Machine;
  return 'Machine(id: ${_this.id}, name: ${_this.name}, address: ${_this.address}, vendor: ${_this.vendor}, gpus: ${_this.gpus}, memory: ${_this.memory}, online: ${_this.online})';
}


}

/// @nodoc
abstract mixin class $MachineCopyWith<$Res>  {
  factory $MachineCopyWith(Machine value, $Res Function(Machine) _then) = _$MachineCopyWithImpl;
@useResult
$Res call({
 String id, String name, String address, Vendor? vendor, String? gpus, String? memory, bool online
});




}
/// @nodoc
class _$MachineCopyWithImpl<$Res>
    implements $MachineCopyWith<$Res> {
  _$MachineCopyWithImpl(this._self, this._then);

  final Machine _self;
  final $Res Function(Machine) _then;

/// Create a copy of Machine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? address = null,Object? vendor = freezed,Object? gpus = freezed,Object? memory = freezed,Object? online = null,}) {
  return _then(Machine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as Vendor?,gpus: freezed == gpus ? _self.gpus : gpus // ignore: cast_nullable_to_non_nullable
as String?,memory: freezed == memory ? _self.memory : memory // ignore: cast_nullable_to_non_nullable
as String?,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Machine].
extension MachinePatterns on Machine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Machine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Machine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Machine value)  $default,){
final _that = this;
switch (_that) {
case _Machine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Machine value)?  $default,){
final _that = this;
switch (_that) {
case _Machine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String address,  Vendor? vendor,  String? gpus,  String? memory,  bool online)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Machine() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.vendor,_that.gpus,_that.memory,_that.online);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String address,  Vendor? vendor,  String? gpus,  String? memory,  bool online)  $default,) {final _that = this;
switch (_that) {
case _Machine():
return $default(_that.id,_that.name,_that.address,_that.vendor,_that.gpus,_that.memory,_that.online);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String address,  Vendor? vendor,  String? gpus,  String? memory,  bool online)?  $default,) {final _that = this;
switch (_that) {
case _Machine() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.vendor,_that.gpus,_that.memory,_that.online);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Machine extends Machine {
  const _Machine({required this.id, required this.name, required this.address, this.vendor, this.gpus, this.memory, this.online = true}): super._();
  factory _Machine.fromJson(Map<String, dynamic> json) => _$MachineFromJson(json);

@override final  String id;
@override final  String name;
@override final  String address;
@override final  Vendor? vendor;
@override final  String? gpus;
@override final  String? memory;
@override@JsonKey() final  bool online;

/// Create a copy of Machine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MachineCopyWith<_Machine> get copyWith => __$MachineCopyWithImpl<_Machine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MachineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Machine&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.gpus, gpus) || other.gpus == gpus)&&(identical(other.memory, memory) || other.memory == memory)&&(identical(other.online, online) || other.online == online));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,address,vendor,gpus,memory,online);
}

@override
String toString() {
    return 'Machine(id: $id, name: $name, address: $address, vendor: $vendor, gpus: $gpus, memory: $memory, online: $online)';
}


}

/// @nodoc
abstract mixin class _$MachineCopyWith<$Res> implements $MachineCopyWith<$Res> {
  factory _$MachineCopyWith(_Machine value, $Res Function(_Machine) _then) = __$MachineCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String address, Vendor? vendor, String? gpus, String? memory, bool online
});




}
/// @nodoc
class __$MachineCopyWithImpl<$Res>
    implements _$MachineCopyWith<$Res> {
  __$MachineCopyWithImpl(this._self, this._then);

  final _Machine _self;
  final $Res Function(_Machine) _then;

/// Create a copy of Machine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? address = null,Object? vendor = freezed,Object? gpus = freezed,Object? memory = freezed,Object? online = null,}) {
  return _then(_Machine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as Vendor?,gpus: freezed == gpus ? _self.gpus : gpus // ignore: cast_nullable_to_non_nullable
as String?,memory: freezed == memory ? _self.memory : memory // ignore: cast_nullable_to_non_nullable
as String?,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
