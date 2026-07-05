// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

 AppThemeMode get themeMode;/// Terminal text size (flterm renders from font data, not app text styles).
 double get terminalFontSize;/// The range `findFreePort` scans when pre-filling a new job's port.
 int get portRangeStart; int get portRangeEnd;/// Seconds between endpoint health checks on running jobs.
 int get healthIntervalSeconds;// Defaults a job's benchmark tab starts with.
 String get benchPrompt; int get benchBatchSize;/// Null = unlimited (the server stops at EOS or its max seqlen).
 int? get benchMaxTokens;/// Null = the server's default temperature.
 double? get benchTemperature;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.terminalFontSize, terminalFontSize) || other.terminalFontSize == terminalFontSize)&&(identical(other.portRangeStart, portRangeStart) || other.portRangeStart == portRangeStart)&&(identical(other.portRangeEnd, portRangeEnd) || other.portRangeEnd == portRangeEnd)&&(identical(other.healthIntervalSeconds, healthIntervalSeconds) || other.healthIntervalSeconds == healthIntervalSeconds)&&(identical(other.benchPrompt, benchPrompt) || other.benchPrompt == benchPrompt)&&(identical(other.benchBatchSize, benchBatchSize) || other.benchBatchSize == benchBatchSize)&&(identical(other.benchMaxTokens, benchMaxTokens) || other.benchMaxTokens == benchMaxTokens)&&(identical(other.benchTemperature, benchTemperature) || other.benchTemperature == benchTemperature));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,terminalFontSize,portRangeStart,portRangeEnd,healthIntervalSeconds,benchPrompt,benchBatchSize,benchMaxTokens,benchTemperature);

@override
String toString() {
  return 'AppSettings(themeMode: $themeMode, terminalFontSize: $terminalFontSize, portRangeStart: $portRangeStart, portRangeEnd: $portRangeEnd, healthIntervalSeconds: $healthIntervalSeconds, benchPrompt: $benchPrompt, benchBatchSize: $benchBatchSize, benchMaxTokens: $benchMaxTokens, benchTemperature: $benchTemperature)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 AppThemeMode themeMode, double terminalFontSize, int portRangeStart, int portRangeEnd, int healthIntervalSeconds, String benchPrompt, int benchBatchSize, int? benchMaxTokens, double? benchTemperature
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? terminalFontSize = null,Object? portRangeStart = null,Object? portRangeEnd = null,Object? healthIntervalSeconds = null,Object? benchPrompt = null,Object? benchBatchSize = null,Object? benchMaxTokens = freezed,Object? benchTemperature = freezed,}) {
  return _then(_self.copyWith(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,terminalFontSize: null == terminalFontSize ? _self.terminalFontSize : terminalFontSize // ignore: cast_nullable_to_non_nullable
as double,portRangeStart: null == portRangeStart ? _self.portRangeStart : portRangeStart // ignore: cast_nullable_to_non_nullable
as int,portRangeEnd: null == portRangeEnd ? _self.portRangeEnd : portRangeEnd // ignore: cast_nullable_to_non_nullable
as int,healthIntervalSeconds: null == healthIntervalSeconds ? _self.healthIntervalSeconds : healthIntervalSeconds // ignore: cast_nullable_to_non_nullable
as int,benchPrompt: null == benchPrompt ? _self.benchPrompt : benchPrompt // ignore: cast_nullable_to_non_nullable
as String,benchBatchSize: null == benchBatchSize ? _self.benchBatchSize : benchBatchSize // ignore: cast_nullable_to_non_nullable
as int,benchMaxTokens: freezed == benchMaxTokens ? _self.benchMaxTokens : benchMaxTokens // ignore: cast_nullable_to_non_nullable
as int?,benchTemperature: freezed == benchTemperature ? _self.benchTemperature : benchTemperature // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  double terminalFontSize,  int portRangeStart,  int portRangeEnd,  int healthIntervalSeconds,  String benchPrompt,  int benchBatchSize,  int? benchMaxTokens,  double? benchTemperature)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.terminalFontSize,_that.portRangeStart,_that.portRangeEnd,_that.healthIntervalSeconds,_that.benchPrompt,_that.benchBatchSize,_that.benchMaxTokens,_that.benchTemperature);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  double terminalFontSize,  int portRangeStart,  int portRangeEnd,  int healthIntervalSeconds,  String benchPrompt,  int benchBatchSize,  int? benchMaxTokens,  double? benchTemperature)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.themeMode,_that.terminalFontSize,_that.portRangeStart,_that.portRangeEnd,_that.healthIntervalSeconds,_that.benchPrompt,_that.benchBatchSize,_that.benchMaxTokens,_that.benchTemperature);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppThemeMode themeMode,  double terminalFontSize,  int portRangeStart,  int portRangeEnd,  int healthIntervalSeconds,  String benchPrompt,  int benchBatchSize,  int? benchMaxTokens,  double? benchTemperature)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.terminalFontSize,_that.portRangeStart,_that.portRangeEnd,_that.healthIntervalSeconds,_that.benchPrompt,_that.benchBatchSize,_that.benchMaxTokens,_that.benchTemperature);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.themeMode = AppThemeMode.system, this.terminalFontSize = 14.0, this.portRangeStart = 8000, this.portRangeEnd = 8100, this.healthIntervalSeconds = 5, this.benchPrompt = defaultBenchmarkPrompt, this.benchBatchSize = 16, this.benchMaxTokens, this.benchTemperature});
  

@override@JsonKey() final  AppThemeMode themeMode;
/// Terminal text size (flterm renders from font data, not app text styles).
@override@JsonKey() final  double terminalFontSize;
/// The range `findFreePort` scans when pre-filling a new job's port.
@override@JsonKey() final  int portRangeStart;
@override@JsonKey() final  int portRangeEnd;
/// Seconds between endpoint health checks on running jobs.
@override@JsonKey() final  int healthIntervalSeconds;
// Defaults a job's benchmark tab starts with.
@override@JsonKey() final  String benchPrompt;
@override@JsonKey() final  int benchBatchSize;
/// Null = unlimited (the server stops at EOS or its max seqlen).
@override final  int? benchMaxTokens;
/// Null = the server's default temperature.
@override final  double? benchTemperature;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.terminalFontSize, terminalFontSize) || other.terminalFontSize == terminalFontSize)&&(identical(other.portRangeStart, portRangeStart) || other.portRangeStart == portRangeStart)&&(identical(other.portRangeEnd, portRangeEnd) || other.portRangeEnd == portRangeEnd)&&(identical(other.healthIntervalSeconds, healthIntervalSeconds) || other.healthIntervalSeconds == healthIntervalSeconds)&&(identical(other.benchPrompt, benchPrompt) || other.benchPrompt == benchPrompt)&&(identical(other.benchBatchSize, benchBatchSize) || other.benchBatchSize == benchBatchSize)&&(identical(other.benchMaxTokens, benchMaxTokens) || other.benchMaxTokens == benchMaxTokens)&&(identical(other.benchTemperature, benchTemperature) || other.benchTemperature == benchTemperature));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,terminalFontSize,portRangeStart,portRangeEnd,healthIntervalSeconds,benchPrompt,benchBatchSize,benchMaxTokens,benchTemperature);

@override
String toString() {
  return 'AppSettings(themeMode: $themeMode, terminalFontSize: $terminalFontSize, portRangeStart: $portRangeStart, portRangeEnd: $portRangeEnd, healthIntervalSeconds: $healthIntervalSeconds, benchPrompt: $benchPrompt, benchBatchSize: $benchBatchSize, benchMaxTokens: $benchMaxTokens, benchTemperature: $benchTemperature)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 AppThemeMode themeMode, double terminalFontSize, int portRangeStart, int portRangeEnd, int healthIntervalSeconds, String benchPrompt, int benchBatchSize, int? benchMaxTokens, double? benchTemperature
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? terminalFontSize = null,Object? portRangeStart = null,Object? portRangeEnd = null,Object? healthIntervalSeconds = null,Object? benchPrompt = null,Object? benchBatchSize = null,Object? benchMaxTokens = freezed,Object? benchTemperature = freezed,}) {
  return _then(_AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,terminalFontSize: null == terminalFontSize ? _self.terminalFontSize : terminalFontSize // ignore: cast_nullable_to_non_nullable
as double,portRangeStart: null == portRangeStart ? _self.portRangeStart : portRangeStart // ignore: cast_nullable_to_non_nullable
as int,portRangeEnd: null == portRangeEnd ? _self.portRangeEnd : portRangeEnd // ignore: cast_nullable_to_non_nullable
as int,healthIntervalSeconds: null == healthIntervalSeconds ? _self.healthIntervalSeconds : healthIntervalSeconds // ignore: cast_nullable_to_non_nullable
as int,benchPrompt: null == benchPrompt ? _self.benchPrompt : benchPrompt // ignore: cast_nullable_to_non_nullable
as String,benchBatchSize: null == benchBatchSize ? _self.benchBatchSize : benchBatchSize // ignore: cast_nullable_to_non_nullable
as int,benchMaxTokens: freezed == benchMaxTokens ? _self.benchMaxTokens : benchMaxTokens // ignore: cast_nullable_to_non_nullable
as int?,benchTemperature: freezed == benchTemperature ? _self.benchTemperature : benchTemperature // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
