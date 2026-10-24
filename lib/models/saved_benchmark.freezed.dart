// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_benchmark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedBenchmark {

 String get id; String get name;/// Where it ran, for display — e.g. `orion:8001`.
 String get endpoint;/// The machine it ran on (its friendly name). Null for runs saved before
/// this was tracked — callers fall back to the endpoint's host.
 String? get machineName;/// The job's launch command at save time, for reference.
 String get command; String get prompt;/// The model name sent with the requests. Null for runs saved before this
/// was tracked.
 String? get model;/// Per-request output cap; null = unlimited (or not tracked).
 int? get maxTokens;/// Sampling temperature; null = the server's default (or not tracked).
 double? get temperature;/// Whether the run ignored EOS (replies ran to the token cap).
 bool get ignoreEos; int get batchSize; double get aggregateTokensPerSecond; int get completed; int get medianTtftMs; int get elapsedMs; DateTime get createdAt;/// The per-request responses (text + metrics) captured at save time.
 List<BenchmarkRequest> get requests;/// Throughput samples over the run, for the charts.
 List<BenchmarkSample> get samples;
/// Create a copy of SavedBenchmark
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedBenchmarkCopyWith<SavedBenchmark> get copyWith => _$SavedBenchmarkCopyWithImpl<SavedBenchmark>(this as SavedBenchmark, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SavedBenchmark;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedBenchmark&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.endpoint, _this.endpoint) || other.endpoint == _this.endpoint)&&(identical(other.machineName, _this.machineName) || other.machineName == _this.machineName)&&(identical(other.command, _this.command) || other.command == _this.command)&&(identical(other.prompt, _this.prompt) || other.prompt == _this.prompt)&&(identical(other.model, _this.model) || other.model == _this.model)&&(identical(other.maxTokens, _this.maxTokens) || other.maxTokens == _this.maxTokens)&&(identical(other.temperature, _this.temperature) || other.temperature == _this.temperature)&&(identical(other.ignoreEos, _this.ignoreEos) || other.ignoreEos == _this.ignoreEos)&&(identical(other.batchSize, _this.batchSize) || other.batchSize == _this.batchSize)&&(identical(other.aggregateTokensPerSecond, _this.aggregateTokensPerSecond) || other.aggregateTokensPerSecond == _this.aggregateTokensPerSecond)&&(identical(other.completed, _this.completed) || other.completed == _this.completed)&&(identical(other.medianTtftMs, _this.medianTtftMs) || other.medianTtftMs == _this.medianTtftMs)&&(identical(other.elapsedMs, _this.elapsedMs) || other.elapsedMs == _this.elapsedMs)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&const DeepCollectionEquality().equals(other.requests, _this.requests)&&const DeepCollectionEquality().equals(other.samples, _this.samples));
}


@override
int get hashCode {
  final _this = this as SavedBenchmark;
  return Object.hash(runtimeType,_this.id,_this.name,_this.endpoint,_this.machineName,_this.command,_this.prompt,_this.model,_this.maxTokens,_this.temperature,_this.ignoreEos,_this.batchSize,_this.aggregateTokensPerSecond,_this.completed,_this.medianTtftMs,_this.elapsedMs,_this.createdAt,const DeepCollectionEquality().hash(_this.requests),const DeepCollectionEquality().hash(_this.samples));
}

@override
String toString() {
  final _this = this as SavedBenchmark;
  return 'SavedBenchmark(id: ${_this.id}, name: ${_this.name}, endpoint: ${_this.endpoint}, machineName: ${_this.machineName}, command: ${_this.command}, prompt: ${_this.prompt}, model: ${_this.model}, maxTokens: ${_this.maxTokens}, temperature: ${_this.temperature}, ignoreEos: ${_this.ignoreEos}, batchSize: ${_this.batchSize}, aggregateTokensPerSecond: ${_this.aggregateTokensPerSecond}, completed: ${_this.completed}, medianTtftMs: ${_this.medianTtftMs}, elapsedMs: ${_this.elapsedMs}, createdAt: ${_this.createdAt}, requests: ${_this.requests}, samples: ${_this.samples})';
}


}

/// @nodoc
abstract mixin class $SavedBenchmarkCopyWith<$Res>  {
  factory $SavedBenchmarkCopyWith(SavedBenchmark value, $Res Function(SavedBenchmark) _then) = _$SavedBenchmarkCopyWithImpl;
@useResult
$Res call({
 String id, String name, String endpoint, String? machineName, String command, String prompt, String? model, int? maxTokens, double? temperature, bool ignoreEos, int batchSize, double aggregateTokensPerSecond, int completed, int medianTtftMs, int elapsedMs, DateTime createdAt, List<BenchmarkRequest> requests, List<BenchmarkSample> samples
});




}
/// @nodoc
class _$SavedBenchmarkCopyWithImpl<$Res>
    implements $SavedBenchmarkCopyWith<$Res> {
  _$SavedBenchmarkCopyWithImpl(this._self, this._then);

  final SavedBenchmark _self;
  final $Res Function(SavedBenchmark) _then;

/// Create a copy of SavedBenchmark
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? endpoint = null,Object? machineName = freezed,Object? command = null,Object? prompt = null,Object? model = freezed,Object? maxTokens = freezed,Object? temperature = freezed,Object? ignoreEos = null,Object? batchSize = null,Object? aggregateTokensPerSecond = null,Object? completed = null,Object? medianTtftMs = null,Object? elapsedMs = null,Object? createdAt = null,Object? requests = null,Object? samples = null,}) {
  return _then(SavedBenchmark(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,machineName: freezed == machineName ? _self.machineName : machineName // ignore: cast_nullable_to_non_nullable
as String?,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,maxTokens: freezed == maxTokens ? _self.maxTokens : maxTokens // ignore: cast_nullable_to_non_nullable
as int?,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,ignoreEos: null == ignoreEos ? _self.ignoreEos : ignoreEos // ignore: cast_nullable_to_non_nullable
as bool,batchSize: null == batchSize ? _self.batchSize : batchSize // ignore: cast_nullable_to_non_nullable
as int,aggregateTokensPerSecond: null == aggregateTokensPerSecond ? _self.aggregateTokensPerSecond : aggregateTokensPerSecond // ignore: cast_nullable_to_non_nullable
as double,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,medianTtftMs: null == medianTtftMs ? _self.medianTtftMs : medianTtftMs // ignore: cast_nullable_to_non_nullable
as int,elapsedMs: null == elapsedMs ? _self.elapsedMs : elapsedMs // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as List<BenchmarkRequest>,samples: null == samples ? _self.samples : samples // ignore: cast_nullable_to_non_nullable
as List<BenchmarkSample>,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedBenchmark].
extension SavedBenchmarkPatterns on SavedBenchmark {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedBenchmark value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedBenchmark() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedBenchmark value)  $default,){
final _that = this;
switch (_that) {
case _SavedBenchmark():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedBenchmark value)?  $default,){
final _that = this;
switch (_that) {
case _SavedBenchmark() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String endpoint,  String? machineName,  String command,  String prompt,  String? model,  int? maxTokens,  double? temperature,  bool ignoreEos,  int batchSize,  double aggregateTokensPerSecond,  int completed,  int medianTtftMs,  int elapsedMs,  DateTime createdAt,  List<BenchmarkRequest> requests,  List<BenchmarkSample> samples)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedBenchmark() when $default != null:
return $default(_that.id,_that.name,_that.endpoint,_that.machineName,_that.command,_that.prompt,_that.model,_that.maxTokens,_that.temperature,_that.ignoreEos,_that.batchSize,_that.aggregateTokensPerSecond,_that.completed,_that.medianTtftMs,_that.elapsedMs,_that.createdAt,_that.requests,_that.samples);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String endpoint,  String? machineName,  String command,  String prompt,  String? model,  int? maxTokens,  double? temperature,  bool ignoreEos,  int batchSize,  double aggregateTokensPerSecond,  int completed,  int medianTtftMs,  int elapsedMs,  DateTime createdAt,  List<BenchmarkRequest> requests,  List<BenchmarkSample> samples)  $default,) {final _that = this;
switch (_that) {
case _SavedBenchmark():
return $default(_that.id,_that.name,_that.endpoint,_that.machineName,_that.command,_that.prompt,_that.model,_that.maxTokens,_that.temperature,_that.ignoreEos,_that.batchSize,_that.aggregateTokensPerSecond,_that.completed,_that.medianTtftMs,_that.elapsedMs,_that.createdAt,_that.requests,_that.samples);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String endpoint,  String? machineName,  String command,  String prompt,  String? model,  int? maxTokens,  double? temperature,  bool ignoreEos,  int batchSize,  double aggregateTokensPerSecond,  int completed,  int medianTtftMs,  int elapsedMs,  DateTime createdAt,  List<BenchmarkRequest> requests,  List<BenchmarkSample> samples)?  $default,) {final _that = this;
switch (_that) {
case _SavedBenchmark() when $default != null:
return $default(_that.id,_that.name,_that.endpoint,_that.machineName,_that.command,_that.prompt,_that.model,_that.maxTokens,_that.temperature,_that.ignoreEos,_that.batchSize,_that.aggregateTokensPerSecond,_that.completed,_that.medianTtftMs,_that.elapsedMs,_that.createdAt,_that.requests,_that.samples);case _:
  return null;

}
}

}

/// @nodoc


class _SavedBenchmark extends SavedBenchmark {
  const _SavedBenchmark({required this.id, required this.name, required this.endpoint, this.machineName, this.command = '', required this.prompt, this.model, this.maxTokens, this.temperature, this.ignoreEos = false, required this.batchSize, required this.aggregateTokensPerSecond, required this.completed, required this.medianTtftMs, required this.elapsedMs, required this.createdAt,  List<BenchmarkRequest> requests = const <BenchmarkRequest>[],  List<BenchmarkSample> samples = const <BenchmarkSample>[]}): _requests = requests,_samples = samples,super._();
  

@override final  String id;
@override final  String name;
/// Where it ran, for display — e.g. `orion:8001`.
@override final  String endpoint;
/// The machine it ran on (its friendly name). Null for runs saved before
/// this was tracked — callers fall back to the endpoint's host.
@override final  String? machineName;
/// The job's launch command at save time, for reference.
@override@JsonKey() final  String command;
@override final  String prompt;
/// The model name sent with the requests. Null for runs saved before this
/// was tracked.
@override final  String? model;
/// Per-request output cap; null = unlimited (or not tracked).
@override final  int? maxTokens;
/// Sampling temperature; null = the server's default (or not tracked).
@override final  double? temperature;
/// Whether the run ignored EOS (replies ran to the token cap).
@override@JsonKey() final  bool ignoreEos;
@override final  int batchSize;
@override final  double aggregateTokensPerSecond;
@override final  int completed;
@override final  int medianTtftMs;
@override final  int elapsedMs;
@override final  DateTime createdAt;
/// The per-request responses (text + metrics) captured at save time.
 final  List<BenchmarkRequest> _requests;
/// The per-request responses (text + metrics) captured at save time.
@override@JsonKey() List<BenchmarkRequest> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}

/// Throughput samples over the run, for the charts.
 final  List<BenchmarkSample> _samples;
/// Throughput samples over the run, for the charts.
@override@JsonKey() List<BenchmarkSample> get samples {
  if (_samples is EqualUnmodifiableListView) return _samples;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_samples);
}


/// Create a copy of SavedBenchmark
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedBenchmarkCopyWith<_SavedBenchmark> get copyWith => __$SavedBenchmarkCopyWithImpl<_SavedBenchmark>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedBenchmark&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.machineName, machineName) || other.machineName == machineName)&&(identical(other.command, command) || other.command == command)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.model, model) || other.model == model)&&(identical(other.maxTokens, maxTokens) || other.maxTokens == maxTokens)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.ignoreEos, ignoreEos) || other.ignoreEos == ignoreEos)&&(identical(other.batchSize, batchSize) || other.batchSize == batchSize)&&(identical(other.aggregateTokensPerSecond, aggregateTokensPerSecond) || other.aggregateTokensPerSecond == aggregateTokensPerSecond)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.medianTtftMs, medianTtftMs) || other.medianTtftMs == medianTtftMs)&&(identical(other.elapsedMs, elapsedMs) || other.elapsedMs == elapsedMs)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.requests, _requests)&&const DeepCollectionEquality().equals(other.samples, _samples));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,endpoint,machineName,command,prompt,model,maxTokens,temperature,ignoreEos,batchSize,aggregateTokensPerSecond,completed,medianTtftMs,elapsedMs,createdAt,const DeepCollectionEquality().hash(_requests),const DeepCollectionEquality().hash(_samples));
}

@override
String toString() {
    return 'SavedBenchmark(id: $id, name: $name, endpoint: $endpoint, machineName: $machineName, command: $command, prompt: $prompt, model: $model, maxTokens: $maxTokens, temperature: $temperature, ignoreEos: $ignoreEos, batchSize: $batchSize, aggregateTokensPerSecond: $aggregateTokensPerSecond, completed: $completed, medianTtftMs: $medianTtftMs, elapsedMs: $elapsedMs, createdAt: $createdAt, requests: $requests, samples: $samples)';
}


}

/// @nodoc
abstract mixin class _$SavedBenchmarkCopyWith<$Res> implements $SavedBenchmarkCopyWith<$Res> {
  factory _$SavedBenchmarkCopyWith(_SavedBenchmark value, $Res Function(_SavedBenchmark) _then) = __$SavedBenchmarkCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String endpoint, String? machineName, String command, String prompt, String? model, int? maxTokens, double? temperature, bool ignoreEos, int batchSize, double aggregateTokensPerSecond, int completed, int medianTtftMs, int elapsedMs, DateTime createdAt, List<BenchmarkRequest> requests, List<BenchmarkSample> samples
});




}
/// @nodoc
class __$SavedBenchmarkCopyWithImpl<$Res>
    implements _$SavedBenchmarkCopyWith<$Res> {
  __$SavedBenchmarkCopyWithImpl(this._self, this._then);

  final _SavedBenchmark _self;
  final $Res Function(_SavedBenchmark) _then;

/// Create a copy of SavedBenchmark
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? endpoint = null,Object? machineName = freezed,Object? command = null,Object? prompt = null,Object? model = freezed,Object? maxTokens = freezed,Object? temperature = freezed,Object? ignoreEos = null,Object? batchSize = null,Object? aggregateTokensPerSecond = null,Object? completed = null,Object? medianTtftMs = null,Object? elapsedMs = null,Object? createdAt = null,Object? requests = null,Object? samples = null,}) {
  return _then(_SavedBenchmark(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,machineName: freezed == machineName ? _self.machineName : machineName // ignore: cast_nullable_to_non_nullable
as String?,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,maxTokens: freezed == maxTokens ? _self.maxTokens : maxTokens // ignore: cast_nullable_to_non_nullable
as int?,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,ignoreEos: null == ignoreEos ? _self.ignoreEos : ignoreEos // ignore: cast_nullable_to_non_nullable
as bool,batchSize: null == batchSize ? _self.batchSize : batchSize // ignore: cast_nullable_to_non_nullable
as int,aggregateTokensPerSecond: null == aggregateTokensPerSecond ? _self.aggregateTokensPerSecond : aggregateTokensPerSecond // ignore: cast_nullable_to_non_nullable
as double,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,medianTtftMs: null == medianTtftMs ? _self.medianTtftMs : medianTtftMs // ignore: cast_nullable_to_non_nullable
as int,elapsedMs: null == elapsedMs ? _self.elapsedMs : elapsedMs // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,requests: null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<BenchmarkRequest>,samples: null == samples ? _self._samples : samples // ignore: cast_nullable_to_non_nullable
as List<BenchmarkSample>,
  ));
}


}

// dart format on
