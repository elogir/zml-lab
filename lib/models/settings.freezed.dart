// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

 AppThemeMode get themeMode;/// Terminal text size (flterm renders from font data, not app text styles).
 double get terminalFontSize;/// Treat Option as Meta in terminals: Option+letter sends `ESC`+letter (so
/// Option+F/B jump words in zsh) instead of macOS composing a glyph (ƒ, ∫).
 bool get terminalOptionAsMeta;/// Mask the address in the Benchmark tab's target bar — for screenshots
/// and screen-sharing. Display only: the real host is still what gets
/// dialled, and nothing is masked on the way into saved runs.
 bool get blurHost; String get benchPrompt; int get benchBatchSize;/// Null = unlimited (the server stops at EOS or its max seqlen).
 int? get benchMaxTokens;/// Null = the server's default temperature.
 double? get benchTemperature;/// Model name sent in benchmark requests (vLLM requires the real one;
/// llmd ignores it). Empty = send `zml_model`.
 String get benchModel;/// The text "Copy results" puts on the clipboard, with `{placeholders}`
/// filled from the run — so each person can match their team's format.
 String get benchCopyTemplate; String get perfToolDir; String get perfDatasetPath;/// A duckdb command the "Copy results" button pipes the run's raw event
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
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&(identical(other.terminalFontSize, _this.terminalFontSize) || other.terminalFontSize == _this.terminalFontSize)&&(identical(other.terminalOptionAsMeta, _this.terminalOptionAsMeta) || other.terminalOptionAsMeta == _this.terminalOptionAsMeta)&&(identical(other.blurHost, _this.blurHost) || other.blurHost == _this.blurHost)&&(identical(other.benchPrompt, _this.benchPrompt) || other.benchPrompt == _this.benchPrompt)&&(identical(other.benchBatchSize, _this.benchBatchSize) || other.benchBatchSize == _this.benchBatchSize)&&(identical(other.benchMaxTokens, _this.benchMaxTokens) || other.benchMaxTokens == _this.benchMaxTokens)&&(identical(other.benchTemperature, _this.benchTemperature) || other.benchTemperature == _this.benchTemperature)&&(identical(other.benchModel, _this.benchModel) || other.benchModel == _this.benchModel)&&(identical(other.benchCopyTemplate, _this.benchCopyTemplate) || other.benchCopyTemplate == _this.benchCopyTemplate)&&(identical(other.perfToolDir, _this.perfToolDir) || other.perfToolDir == _this.perfToolDir)&&(identical(other.perfDatasetPath, _this.perfDatasetPath) || other.perfDatasetPath == _this.perfDatasetPath)&&(identical(other.perfDuckdbCommand, _this.perfDuckdbCommand) || other.perfDuckdbCommand == _this.perfDuckdbCommand)&&(identical(other.perfParams, _this.perfParams) || other.perfParams == _this.perfParams));
}


@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hash(runtimeType,_this.themeMode,_this.terminalFontSize,_this.terminalOptionAsMeta,_this.blurHost,_this.benchPrompt,_this.benchBatchSize,_this.benchMaxTokens,_this.benchTemperature,_this.benchModel,_this.benchCopyTemplate,_this.perfToolDir,_this.perfDatasetPath,_this.perfDuckdbCommand,_this.perfParams);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(themeMode: ${_this.themeMode}, terminalFontSize: ${_this.terminalFontSize}, terminalOptionAsMeta: ${_this.terminalOptionAsMeta}, blurHost: ${_this.blurHost}, benchPrompt: ${_this.benchPrompt}, benchBatchSize: ${_this.benchBatchSize}, benchMaxTokens: ${_this.benchMaxTokens}, benchTemperature: ${_this.benchTemperature}, benchModel: ${_this.benchModel}, benchCopyTemplate: ${_this.benchCopyTemplate}, perfToolDir: ${_this.perfToolDir}, perfDatasetPath: ${_this.perfDatasetPath}, perfDuckdbCommand: ${_this.perfDuckdbCommand}, perfParams: ${_this.perfParams})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 AppThemeMode themeMode, double terminalFontSize, bool terminalOptionAsMeta, bool blurHost, String benchPrompt, int benchBatchSize, int? benchMaxTokens, double? benchTemperature, String benchModel, String benchCopyTemplate, String perfToolDir, String perfDatasetPath, String perfDuckdbCommand, PerfParams perfParams
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
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? terminalFontSize = null,Object? terminalOptionAsMeta = null,Object? blurHost = null,Object? benchPrompt = null,Object? benchBatchSize = null,Object? benchMaxTokens = freezed,Object? benchTemperature = freezed,Object? benchModel = null,Object? benchCopyTemplate = null,Object? perfToolDir = null,Object? perfDatasetPath = null,Object? perfDuckdbCommand = null,Object? perfParams = null,}) {
  return _then(AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,terminalFontSize: null == terminalFontSize ? _self.terminalFontSize : terminalFontSize // ignore: cast_nullable_to_non_nullable
as double,terminalOptionAsMeta: null == terminalOptionAsMeta ? _self.terminalOptionAsMeta : terminalOptionAsMeta // ignore: cast_nullable_to_non_nullable
as bool,blurHost: null == blurHost ? _self.blurHost : blurHost // ignore: cast_nullable_to_non_nullable
as bool,benchPrompt: null == benchPrompt ? _self.benchPrompt : benchPrompt // ignore: cast_nullable_to_non_nullable
as String,benchBatchSize: null == benchBatchSize ? _self.benchBatchSize : benchBatchSize // ignore: cast_nullable_to_non_nullable
as int,benchMaxTokens: freezed == benchMaxTokens ? _self.benchMaxTokens : benchMaxTokens // ignore: cast_nullable_to_non_nullable
as int?,benchTemperature: freezed == benchTemperature ? _self.benchTemperature : benchTemperature // ignore: cast_nullable_to_non_nullable
as double?,benchModel: null == benchModel ? _self.benchModel : benchModel // ignore: cast_nullable_to_non_nullable
as String,benchCopyTemplate: null == benchCopyTemplate ? _self.benchCopyTemplate : benchCopyTemplate // ignore: cast_nullable_to_non_nullable
as String,perfToolDir: null == perfToolDir ? _self.perfToolDir : perfToolDir // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  double terminalFontSize,  bool terminalOptionAsMeta,  bool blurHost,  String benchPrompt,  int benchBatchSize,  int? benchMaxTokens,  double? benchTemperature,  String benchModel,  String benchCopyTemplate,  String perfToolDir,  String perfDatasetPath,  String perfDuckdbCommand,  PerfParams perfParams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.terminalFontSize,_that.terminalOptionAsMeta,_that.blurHost,_that.benchPrompt,_that.benchBatchSize,_that.benchMaxTokens,_that.benchTemperature,_that.benchModel,_that.benchCopyTemplate,_that.perfToolDir,_that.perfDatasetPath,_that.perfDuckdbCommand,_that.perfParams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  double terminalFontSize,  bool terminalOptionAsMeta,  bool blurHost,  String benchPrompt,  int benchBatchSize,  int? benchMaxTokens,  double? benchTemperature,  String benchModel,  String benchCopyTemplate,  String perfToolDir,  String perfDatasetPath,  String perfDuckdbCommand,  PerfParams perfParams)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.themeMode,_that.terminalFontSize,_that.terminalOptionAsMeta,_that.blurHost,_that.benchPrompt,_that.benchBatchSize,_that.benchMaxTokens,_that.benchTemperature,_that.benchModel,_that.benchCopyTemplate,_that.perfToolDir,_that.perfDatasetPath,_that.perfDuckdbCommand,_that.perfParams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppThemeMode themeMode,  double terminalFontSize,  bool terminalOptionAsMeta,  bool blurHost,  String benchPrompt,  int benchBatchSize,  int? benchMaxTokens,  double? benchTemperature,  String benchModel,  String benchCopyTemplate,  String perfToolDir,  String perfDatasetPath,  String perfDuckdbCommand,  PerfParams perfParams)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.terminalFontSize,_that.terminalOptionAsMeta,_that.blurHost,_that.benchPrompt,_that.benchBatchSize,_that.benchMaxTokens,_that.benchTemperature,_that.benchModel,_that.benchCopyTemplate,_that.perfToolDir,_that.perfDatasetPath,_that.perfDuckdbCommand,_that.perfParams);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.themeMode = AppThemeMode.system, this.terminalFontSize = 14.0, this.terminalOptionAsMeta = true, this.blurHost = false, this.benchPrompt = defaultBenchmarkPrompt, this.benchBatchSize = 16, this.benchMaxTokens, this.benchTemperature, this.benchModel = '', this.benchCopyTemplate = defaultResultTemplate, this.perfToolDir = defaultPerfToolDir, this.perfDatasetPath = defaultPerfDatasetPath, this.perfDuckdbCommand = '', this.perfParams = const PerfParams()});
  

@override@JsonKey() final  AppThemeMode themeMode;
/// Terminal text size (flterm renders from font data, not app text styles).
@override@JsonKey() final  double terminalFontSize;
/// Treat Option as Meta in terminals: Option+letter sends `ESC`+letter (so
/// Option+F/B jump words in zsh) instead of macOS composing a glyph (ƒ, ∫).
@override@JsonKey() final  bool terminalOptionAsMeta;
/// Mask the address in the Benchmark tab's target bar — for screenshots
/// and screen-sharing. Display only: the real host is still what gets
/// dialled, and nothing is masked on the way into saved runs.
@override@JsonKey() final  bool blurHost;
@override@JsonKey() final  String benchPrompt;
@override@JsonKey() final  int benchBatchSize;
/// Null = unlimited (the server stops at EOS or its max seqlen).
@override final  int? benchMaxTokens;
/// Null = the server's default temperature.
@override final  double? benchTemperature;
/// Model name sent in benchmark requests (vLLM requires the real one;
/// llmd ignores it). Empty = send `zml_model`.
@override@JsonKey() final  String benchModel;
/// The text "Copy results" puts on the clipboard, with `{placeholders}`
/// filled from the run — so each person can match their team's format.
@override@JsonKey() final  String benchCopyTemplate;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.terminalFontSize, terminalFontSize) || other.terminalFontSize == terminalFontSize)&&(identical(other.terminalOptionAsMeta, terminalOptionAsMeta) || other.terminalOptionAsMeta == terminalOptionAsMeta)&&(identical(other.blurHost, blurHost) || other.blurHost == blurHost)&&(identical(other.benchPrompt, benchPrompt) || other.benchPrompt == benchPrompt)&&(identical(other.benchBatchSize, benchBatchSize) || other.benchBatchSize == benchBatchSize)&&(identical(other.benchMaxTokens, benchMaxTokens) || other.benchMaxTokens == benchMaxTokens)&&(identical(other.benchTemperature, benchTemperature) || other.benchTemperature == benchTemperature)&&(identical(other.benchModel, benchModel) || other.benchModel == benchModel)&&(identical(other.benchCopyTemplate, benchCopyTemplate) || other.benchCopyTemplate == benchCopyTemplate)&&(identical(other.perfToolDir, perfToolDir) || other.perfToolDir == perfToolDir)&&(identical(other.perfDatasetPath, perfDatasetPath) || other.perfDatasetPath == perfDatasetPath)&&(identical(other.perfDuckdbCommand, perfDuckdbCommand) || other.perfDuckdbCommand == perfDuckdbCommand)&&(identical(other.perfParams, perfParams) || other.perfParams == perfParams));
}


@override
int get hashCode {
    return Object.hash(runtimeType,themeMode,terminalFontSize,terminalOptionAsMeta,blurHost,benchPrompt,benchBatchSize,benchMaxTokens,benchTemperature,benchModel,benchCopyTemplate,perfToolDir,perfDatasetPath,perfDuckdbCommand,perfParams);
}

@override
String toString() {
    return 'AppSettings(themeMode: $themeMode, terminalFontSize: $terminalFontSize, terminalOptionAsMeta: $terminalOptionAsMeta, blurHost: $blurHost, benchPrompt: $benchPrompt, benchBatchSize: $benchBatchSize, benchMaxTokens: $benchMaxTokens, benchTemperature: $benchTemperature, benchModel: $benchModel, benchCopyTemplate: $benchCopyTemplate, perfToolDir: $perfToolDir, perfDatasetPath: $perfDatasetPath, perfDuckdbCommand: $perfDuckdbCommand, perfParams: $perfParams)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 AppThemeMode themeMode, double terminalFontSize, bool terminalOptionAsMeta, bool blurHost, String benchPrompt, int benchBatchSize, int? benchMaxTokens, double? benchTemperature, String benchModel, String benchCopyTemplate, String perfToolDir, String perfDatasetPath, String perfDuckdbCommand, PerfParams perfParams
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
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? terminalFontSize = null,Object? terminalOptionAsMeta = null,Object? blurHost = null,Object? benchPrompt = null,Object? benchBatchSize = null,Object? benchMaxTokens = freezed,Object? benchTemperature = freezed,Object? benchModel = null,Object? benchCopyTemplate = null,Object? perfToolDir = null,Object? perfDatasetPath = null,Object? perfDuckdbCommand = null,Object? perfParams = null,}) {
  return _then(_AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,terminalFontSize: null == terminalFontSize ? _self.terminalFontSize : terminalFontSize // ignore: cast_nullable_to_non_nullable
as double,terminalOptionAsMeta: null == terminalOptionAsMeta ? _self.terminalOptionAsMeta : terminalOptionAsMeta // ignore: cast_nullable_to_non_nullable
as bool,blurHost: null == blurHost ? _self.blurHost : blurHost // ignore: cast_nullable_to_non_nullable
as bool,benchPrompt: null == benchPrompt ? _self.benchPrompt : benchPrompt // ignore: cast_nullable_to_non_nullable
as String,benchBatchSize: null == benchBatchSize ? _self.benchBatchSize : benchBatchSize // ignore: cast_nullable_to_non_nullable
as int,benchMaxTokens: freezed == benchMaxTokens ? _self.benchMaxTokens : benchMaxTokens // ignore: cast_nullable_to_non_nullable
as int?,benchTemperature: freezed == benchTemperature ? _self.benchTemperature : benchTemperature // ignore: cast_nullable_to_non_nullable
as double?,benchModel: null == benchModel ? _self.benchModel : benchModel // ignore: cast_nullable_to_non_nullable
as String,benchCopyTemplate: null == benchCopyTemplate ? _self.benchCopyTemplate : benchCopyTemplate // ignore: cast_nullable_to_non_nullable
as String,perfToolDir: null == perfToolDir ? _self.perfToolDir : perfToolDir // ignore: cast_nullable_to_non_nullable
as String,perfDatasetPath: null == perfDatasetPath ? _self.perfDatasetPath : perfDatasetPath // ignore: cast_nullable_to_non_nullable
as String,perfDuckdbCommand: null == perfDuckdbCommand ? _self.perfDuckdbCommand : perfDuckdbCommand // ignore: cast_nullable_to_non_nullable
as String,perfParams: null == perfParams ? _self.perfParams : perfParams // ignore: cast_nullable_to_non_nullable
as PerfParams,
  ));
}


}

// dart format on
