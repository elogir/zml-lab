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
 double get terminalFontSize;/// Treat Option as Meta in terminals: Option+letter sends `ESC`+letter (so
/// Option+F/B jump words in zsh) instead of macOS composing a glyph (ƒ, ∫).
 bool get terminalOptionAsMeta;/// The range `findFreePort` scans when pre-filling a new job's port.
 int get portRangeStart; int get portRangeEnd;/// Seconds between endpoint health checks on running jobs.
 int get healthIntervalSeconds;// Defaults a job's benchmark tab starts with.
 String get benchPrompt; int get benchBatchSize;/// Null = unlimited (the server stops at EOS or its max seqlen).
 int? get benchMaxTokens;/// Null = the server's default temperature.
 double? get benchTemperature;/// Model name sent in benchmark requests (vLLM requires the real one;
/// llmd ignores it). Empty = send `zml_model`.
 String get benchModel;/// Environment variables injected into every job launch (local and remote).
/// A job's own env vars override these on a key clash.
 List<EnvVar> get globalEnv;// Perf benchmark (monorepo tools/benchmark) integration.
 String get perfToolDir; String get perfDatasetPath;/// A duckdb command the "Copy results" button pipes the run's raw event
/// CSV through (run in the tool dir). Empty = copy the app's own render.
 String get perfDuckdbCommand;/// Last-used perf run parameters — the form remembers them so nothing has
/// to be re-entered between runs.
 PerfParams get perfParams;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.terminalFontSize, terminalFontSize) || other.terminalFontSize == terminalFontSize)&&(identical(other.terminalOptionAsMeta, terminalOptionAsMeta) || other.terminalOptionAsMeta == terminalOptionAsMeta)&&(identical(other.portRangeStart, portRangeStart) || other.portRangeStart == portRangeStart)&&(identical(other.portRangeEnd, portRangeEnd) || other.portRangeEnd == portRangeEnd)&&(identical(other.healthIntervalSeconds, healthIntervalSeconds) || other.healthIntervalSeconds == healthIntervalSeconds)&&(identical(other.benchPrompt, benchPrompt) || other.benchPrompt == benchPrompt)&&(identical(other.benchBatchSize, benchBatchSize) || other.benchBatchSize == benchBatchSize)&&(identical(other.benchMaxTokens, benchMaxTokens) || other.benchMaxTokens == benchMaxTokens)&&(identical(other.benchTemperature, benchTemperature) || other.benchTemperature == benchTemperature)&&(identical(other.benchModel, benchModel) || other.benchModel == benchModel)&&const DeepCollectionEquality().equals(other.globalEnv, globalEnv)&&(identical(other.perfToolDir, perfToolDir) || other.perfToolDir == perfToolDir)&&(identical(other.perfDatasetPath, perfDatasetPath) || other.perfDatasetPath == perfDatasetPath)&&(identical(other.perfDuckdbCommand, perfDuckdbCommand) || other.perfDuckdbCommand == perfDuckdbCommand)&&(identical(other.perfParams, perfParams) || other.perfParams == perfParams));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,terminalFontSize,terminalOptionAsMeta,portRangeStart,portRangeEnd,healthIntervalSeconds,benchPrompt,benchBatchSize,benchMaxTokens,benchTemperature,benchModel,const DeepCollectionEquality().hash(globalEnv),perfToolDir,perfDatasetPath,perfDuckdbCommand,perfParams);

@override
String toString() {
  return 'AppSettings(themeMode: $themeMode, terminalFontSize: $terminalFontSize, terminalOptionAsMeta: $terminalOptionAsMeta, portRangeStart: $portRangeStart, portRangeEnd: $portRangeEnd, healthIntervalSeconds: $healthIntervalSeconds, benchPrompt: $benchPrompt, benchBatchSize: $benchBatchSize, benchMaxTokens: $benchMaxTokens, benchTemperature: $benchTemperature, benchModel: $benchModel, globalEnv: $globalEnv, perfToolDir: $perfToolDir, perfDatasetPath: $perfDatasetPath, perfDuckdbCommand: $perfDuckdbCommand, perfParams: $perfParams)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 AppThemeMode themeMode, double terminalFontSize, bool terminalOptionAsMeta, int portRangeStart, int portRangeEnd, int healthIntervalSeconds, String benchPrompt, int benchBatchSize, int? benchMaxTokens, double? benchTemperature, String benchModel, List<EnvVar> globalEnv, String perfToolDir, String perfDatasetPath, String perfDuckdbCommand, PerfParams perfParams
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
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? terminalFontSize = null,Object? terminalOptionAsMeta = null,Object? portRangeStart = null,Object? portRangeEnd = null,Object? healthIntervalSeconds = null,Object? benchPrompt = null,Object? benchBatchSize = null,Object? benchMaxTokens = freezed,Object? benchTemperature = freezed,Object? benchModel = null,Object? globalEnv = null,Object? perfToolDir = null,Object? perfDatasetPath = null,Object? perfDuckdbCommand = null,Object? perfParams = null,}) {
  return _then(_self.copyWith(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,terminalFontSize: null == terminalFontSize ? _self.terminalFontSize : terminalFontSize // ignore: cast_nullable_to_non_nullable
as double,terminalOptionAsMeta: null == terminalOptionAsMeta ? _self.terminalOptionAsMeta : terminalOptionAsMeta // ignore: cast_nullable_to_non_nullable
as bool,portRangeStart: null == portRangeStart ? _self.portRangeStart : portRangeStart // ignore: cast_nullable_to_non_nullable
as int,portRangeEnd: null == portRangeEnd ? _self.portRangeEnd : portRangeEnd // ignore: cast_nullable_to_non_nullable
as int,healthIntervalSeconds: null == healthIntervalSeconds ? _self.healthIntervalSeconds : healthIntervalSeconds // ignore: cast_nullable_to_non_nullable
as int,benchPrompt: null == benchPrompt ? _self.benchPrompt : benchPrompt // ignore: cast_nullable_to_non_nullable
as String,benchBatchSize: null == benchBatchSize ? _self.benchBatchSize : benchBatchSize // ignore: cast_nullable_to_non_nullable
as int,benchMaxTokens: freezed == benchMaxTokens ? _self.benchMaxTokens : benchMaxTokens // ignore: cast_nullable_to_non_nullable
as int?,benchTemperature: freezed == benchTemperature ? _self.benchTemperature : benchTemperature // ignore: cast_nullable_to_non_nullable
as double?,benchModel: null == benchModel ? _self.benchModel : benchModel // ignore: cast_nullable_to_non_nullable
as String,globalEnv: null == globalEnv ? _self.globalEnv : globalEnv // ignore: cast_nullable_to_non_nullable
as List<EnvVar>,perfToolDir: null == perfToolDir ? _self.perfToolDir : perfToolDir // ignore: cast_nullable_to_non_nullable
as String,perfDatasetPath: null == perfDatasetPath ? _self.perfDatasetPath : perfDatasetPath // ignore: cast_nullable_to_non_nullable
as String,perfDuckdbCommand: null == perfDuckdbCommand ? _self.perfDuckdbCommand : perfDuckdbCommand // ignore: cast_nullable_to_non_nullable
as String,perfParams: null == perfParams ? _self.perfParams : perfParams // ignore: cast_nullable_to_non_nullable
as PerfParams,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  double terminalFontSize,  bool terminalOptionAsMeta,  int portRangeStart,  int portRangeEnd,  int healthIntervalSeconds,  String benchPrompt,  int benchBatchSize,  int? benchMaxTokens,  double? benchTemperature,  String benchModel,  List<EnvVar> globalEnv,  String perfToolDir,  String perfDatasetPath,  String perfDuckdbCommand,  PerfParams perfParams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.terminalFontSize,_that.terminalOptionAsMeta,_that.portRangeStart,_that.portRangeEnd,_that.healthIntervalSeconds,_that.benchPrompt,_that.benchBatchSize,_that.benchMaxTokens,_that.benchTemperature,_that.benchModel,_that.globalEnv,_that.perfToolDir,_that.perfDatasetPath,_that.perfDuckdbCommand,_that.perfParams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  double terminalFontSize,  bool terminalOptionAsMeta,  int portRangeStart,  int portRangeEnd,  int healthIntervalSeconds,  String benchPrompt,  int benchBatchSize,  int? benchMaxTokens,  double? benchTemperature,  String benchModel,  List<EnvVar> globalEnv,  String perfToolDir,  String perfDatasetPath,  String perfDuckdbCommand,  PerfParams perfParams)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.themeMode,_that.terminalFontSize,_that.terminalOptionAsMeta,_that.portRangeStart,_that.portRangeEnd,_that.healthIntervalSeconds,_that.benchPrompt,_that.benchBatchSize,_that.benchMaxTokens,_that.benchTemperature,_that.benchModel,_that.globalEnv,_that.perfToolDir,_that.perfDatasetPath,_that.perfDuckdbCommand,_that.perfParams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppThemeMode themeMode,  double terminalFontSize,  bool terminalOptionAsMeta,  int portRangeStart,  int portRangeEnd,  int healthIntervalSeconds,  String benchPrompt,  int benchBatchSize,  int? benchMaxTokens,  double? benchTemperature,  String benchModel,  List<EnvVar> globalEnv,  String perfToolDir,  String perfDatasetPath,  String perfDuckdbCommand,  PerfParams perfParams)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.terminalFontSize,_that.terminalOptionAsMeta,_that.portRangeStart,_that.portRangeEnd,_that.healthIntervalSeconds,_that.benchPrompt,_that.benchBatchSize,_that.benchMaxTokens,_that.benchTemperature,_that.benchModel,_that.globalEnv,_that.perfToolDir,_that.perfDatasetPath,_that.perfDuckdbCommand,_that.perfParams);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.themeMode = AppThemeMode.system, this.terminalFontSize = 14.0, this.terminalOptionAsMeta = true, this.portRangeStart = 8000, this.portRangeEnd = 8100, this.healthIntervalSeconds = 5, this.benchPrompt = defaultBenchmarkPrompt, this.benchBatchSize = 16, this.benchMaxTokens, this.benchTemperature, this.benchModel = '', final  List<EnvVar> globalEnv = const <EnvVar>[], this.perfToolDir = defaultPerfToolDir, this.perfDatasetPath = defaultPerfDatasetPath, this.perfDuckdbCommand = '', this.perfParams = const PerfParams()}): _globalEnv = globalEnv;
  

@override@JsonKey() final  AppThemeMode themeMode;
/// Terminal text size (flterm renders from font data, not app text styles).
@override@JsonKey() final  double terminalFontSize;
/// Treat Option as Meta in terminals: Option+letter sends `ESC`+letter (so
/// Option+F/B jump words in zsh) instead of macOS composing a glyph (ƒ, ∫).
@override@JsonKey() final  bool terminalOptionAsMeta;
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
/// Model name sent in benchmark requests (vLLM requires the real one;
/// llmd ignores it). Empty = send `zml_model`.
@override@JsonKey() final  String benchModel;
/// Environment variables injected into every job launch (local and remote).
/// A job's own env vars override these on a key clash.
 final  List<EnvVar> _globalEnv;
/// Environment variables injected into every job launch (local and remote).
/// A job's own env vars override these on a key clash.
@override@JsonKey() List<EnvVar> get globalEnv {
  if (_globalEnv is EqualUnmodifiableListView) return _globalEnv;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_globalEnv);
}

// Perf benchmark (monorepo tools/benchmark) integration.
@override@JsonKey() final  String perfToolDir;
@override@JsonKey() final  String perfDatasetPath;
/// A duckdb command the "Copy results" button pipes the run's raw event
/// CSV through (run in the tool dir). Empty = copy the app's own render.
@override@JsonKey() final  String perfDuckdbCommand;
/// Last-used perf run parameters — the form remembers them so nothing has
/// to be re-entered between runs.
@override@JsonKey() final  PerfParams perfParams;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.terminalFontSize, terminalFontSize) || other.terminalFontSize == terminalFontSize)&&(identical(other.terminalOptionAsMeta, terminalOptionAsMeta) || other.terminalOptionAsMeta == terminalOptionAsMeta)&&(identical(other.portRangeStart, portRangeStart) || other.portRangeStart == portRangeStart)&&(identical(other.portRangeEnd, portRangeEnd) || other.portRangeEnd == portRangeEnd)&&(identical(other.healthIntervalSeconds, healthIntervalSeconds) || other.healthIntervalSeconds == healthIntervalSeconds)&&(identical(other.benchPrompt, benchPrompt) || other.benchPrompt == benchPrompt)&&(identical(other.benchBatchSize, benchBatchSize) || other.benchBatchSize == benchBatchSize)&&(identical(other.benchMaxTokens, benchMaxTokens) || other.benchMaxTokens == benchMaxTokens)&&(identical(other.benchTemperature, benchTemperature) || other.benchTemperature == benchTemperature)&&(identical(other.benchModel, benchModel) || other.benchModel == benchModel)&&const DeepCollectionEquality().equals(other._globalEnv, _globalEnv)&&(identical(other.perfToolDir, perfToolDir) || other.perfToolDir == perfToolDir)&&(identical(other.perfDatasetPath, perfDatasetPath) || other.perfDatasetPath == perfDatasetPath)&&(identical(other.perfDuckdbCommand, perfDuckdbCommand) || other.perfDuckdbCommand == perfDuckdbCommand)&&(identical(other.perfParams, perfParams) || other.perfParams == perfParams));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,terminalFontSize,terminalOptionAsMeta,portRangeStart,portRangeEnd,healthIntervalSeconds,benchPrompt,benchBatchSize,benchMaxTokens,benchTemperature,benchModel,const DeepCollectionEquality().hash(_globalEnv),perfToolDir,perfDatasetPath,perfDuckdbCommand,perfParams);

@override
String toString() {
  return 'AppSettings(themeMode: $themeMode, terminalFontSize: $terminalFontSize, terminalOptionAsMeta: $terminalOptionAsMeta, portRangeStart: $portRangeStart, portRangeEnd: $portRangeEnd, healthIntervalSeconds: $healthIntervalSeconds, benchPrompt: $benchPrompt, benchBatchSize: $benchBatchSize, benchMaxTokens: $benchMaxTokens, benchTemperature: $benchTemperature, benchModel: $benchModel, globalEnv: $globalEnv, perfToolDir: $perfToolDir, perfDatasetPath: $perfDatasetPath, perfDuckdbCommand: $perfDuckdbCommand, perfParams: $perfParams)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 AppThemeMode themeMode, double terminalFontSize, bool terminalOptionAsMeta, int portRangeStart, int portRangeEnd, int healthIntervalSeconds, String benchPrompt, int benchBatchSize, int? benchMaxTokens, double? benchTemperature, String benchModel, List<EnvVar> globalEnv, String perfToolDir, String perfDatasetPath, String perfDuckdbCommand, PerfParams perfParams
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
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? terminalFontSize = null,Object? terminalOptionAsMeta = null,Object? portRangeStart = null,Object? portRangeEnd = null,Object? healthIntervalSeconds = null,Object? benchPrompt = null,Object? benchBatchSize = null,Object? benchMaxTokens = freezed,Object? benchTemperature = freezed,Object? benchModel = null,Object? globalEnv = null,Object? perfToolDir = null,Object? perfDatasetPath = null,Object? perfDuckdbCommand = null,Object? perfParams = null,}) {
  return _then(_AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,terminalFontSize: null == terminalFontSize ? _self.terminalFontSize : terminalFontSize // ignore: cast_nullable_to_non_nullable
as double,terminalOptionAsMeta: null == terminalOptionAsMeta ? _self.terminalOptionAsMeta : terminalOptionAsMeta // ignore: cast_nullable_to_non_nullable
as bool,portRangeStart: null == portRangeStart ? _self.portRangeStart : portRangeStart // ignore: cast_nullable_to_non_nullable
as int,portRangeEnd: null == portRangeEnd ? _self.portRangeEnd : portRangeEnd // ignore: cast_nullable_to_non_nullable
as int,healthIntervalSeconds: null == healthIntervalSeconds ? _self.healthIntervalSeconds : healthIntervalSeconds // ignore: cast_nullable_to_non_nullable
as int,benchPrompt: null == benchPrompt ? _self.benchPrompt : benchPrompt // ignore: cast_nullable_to_non_nullable
as String,benchBatchSize: null == benchBatchSize ? _self.benchBatchSize : benchBatchSize // ignore: cast_nullable_to_non_nullable
as int,benchMaxTokens: freezed == benchMaxTokens ? _self.benchMaxTokens : benchMaxTokens // ignore: cast_nullable_to_non_nullable
as int?,benchTemperature: freezed == benchTemperature ? _self.benchTemperature : benchTemperature // ignore: cast_nullable_to_non_nullable
as double?,benchModel: null == benchModel ? _self.benchModel : benchModel // ignore: cast_nullable_to_non_nullable
as String,globalEnv: null == globalEnv ? _self._globalEnv : globalEnv // ignore: cast_nullable_to_non_nullable
as List<EnvVar>,perfToolDir: null == perfToolDir ? _self.perfToolDir : perfToolDir // ignore: cast_nullable_to_non_nullable
as String,perfDatasetPath: null == perfDatasetPath ? _self.perfDatasetPath : perfDatasetPath // ignore: cast_nullable_to_non_nullable
as String,perfDuckdbCommand: null == perfDuckdbCommand ? _self.perfDuckdbCommand : perfDuckdbCommand // ignore: cast_nullable_to_non_nullable
as String,perfParams: null == perfParams ? _self.perfParams : perfParams // ignore: cast_nullable_to_non_nullable
as PerfParams,
  ));
}


}

// dart format on
