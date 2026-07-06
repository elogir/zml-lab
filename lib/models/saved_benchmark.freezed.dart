// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_benchmark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedBenchmark {

 String get id; String get name;/// Where it ran, for display — e.g. `orion:8001`.
 String get endpoint;/// The machine it ran on (its friendly name). Null for runs saved before
/// this was tracked — callers fall back to the endpoint's host.
 String? get machineName;/// The job's launch command at save time, for reference.
 String get command; String get prompt; int get batchSize; double get aggregateTokensPerSecond; int get completed; int get medianTtftMs; int get elapsedMs; DateTime get createdAt;/// The per-request responses (text + metrics) captured at save time.
 List<BenchmarkRequest> get requests;/// Throughput samples over the run, for the charts.
 List<BenchmarkSample> get samples;
/// Create a copy of SavedBenchmark
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedBenchmarkCopyWith<SavedBenchmark> get copyWith => _$SavedBenchmarkCopyWithImpl<SavedBenchmark>(this as SavedBenchmark, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedBenchmark&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.machineName, machineName) || other.machineName == machineName)&&(identical(other.command, command) || other.command == command)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.batchSize, batchSize) || other.batchSize == batchSize)&&(identical(other.aggregateTokensPerSecond, aggregateTokensPerSecond) || other.aggregateTokensPerSecond == aggregateTokensPerSecond)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.medianTtftMs, medianTtftMs) || other.medianTtftMs == medianTtftMs)&&(identical(other.elapsedMs, elapsedMs) || other.elapsedMs == elapsedMs)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.requests, requests)&&const DeepCollectionEquality().equals(other.samples, samples));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,endpoint,machineName,command,prompt,batchSize,aggregateTokensPerSecond,completed,medianTtftMs,elapsedMs,createdAt,const DeepCollectionEquality().hash(requests),const DeepCollectionEquality().hash(samples));

@override
String toString() {
  return 'SavedBenchmark(id: $id, name: $name, endpoint: $endpoint, machineName: $machineName, command: $command, prompt: $prompt, batchSize: $batchSize, aggregateTokensPerSecond: $aggregateTokensPerSecond, completed: $completed, medianTtftMs: $medianTtftMs, elapsedMs: $elapsedMs, createdAt: $createdAt, requests: $requests, samples: $samples)';
}


}

/// @nodoc
abstract mixin class $SavedBenchmarkCopyWith<$Res>  {
  factory $SavedBenchmarkCopyWith(SavedBenchmark value, $Res Function(SavedBenchmark) _then) = _$SavedBenchmarkCopyWithImpl;
@useResult
$Res call({
 String id, String name, String endpoint, String? machineName, String command, String prompt, int batchSize, double aggregateTokensPerSecond, int completed, int medianTtftMs, int elapsedMs, DateTime createdAt, List<BenchmarkRequest> requests, List<BenchmarkSample> samples
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? endpoint = null,Object? machineName = freezed,Object? command = null,Object? prompt = null,Object? batchSize = null,Object? aggregateTokensPerSecond = null,Object? completed = null,Object? medianTtftMs = null,Object? elapsedMs = null,Object? createdAt = null,Object? requests = null,Object? samples = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,machineName: freezed == machineName ? _self.machineName : machineName // ignore: cast_nullable_to_non_nullable
as String?,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,batchSize: null == batchSize ? _self.batchSize : batchSize // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String endpoint,  String? machineName,  String command,  String prompt,  int batchSize,  double aggregateTokensPerSecond,  int completed,  int medianTtftMs,  int elapsedMs,  DateTime createdAt,  List<BenchmarkRequest> requests,  List<BenchmarkSample> samples)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedBenchmark() when $default != null:
return $default(_that.id,_that.name,_that.endpoint,_that.machineName,_that.command,_that.prompt,_that.batchSize,_that.aggregateTokensPerSecond,_that.completed,_that.medianTtftMs,_that.elapsedMs,_that.createdAt,_that.requests,_that.samples);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String endpoint,  String? machineName,  String command,  String prompt,  int batchSize,  double aggregateTokensPerSecond,  int completed,  int medianTtftMs,  int elapsedMs,  DateTime createdAt,  List<BenchmarkRequest> requests,  List<BenchmarkSample> samples)  $default,) {final _that = this;
switch (_that) {
case _SavedBenchmark():
return $default(_that.id,_that.name,_that.endpoint,_that.machineName,_that.command,_that.prompt,_that.batchSize,_that.aggregateTokensPerSecond,_that.completed,_that.medianTtftMs,_that.elapsedMs,_that.createdAt,_that.requests,_that.samples);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String endpoint,  String? machineName,  String command,  String prompt,  int batchSize,  double aggregateTokensPerSecond,  int completed,  int medianTtftMs,  int elapsedMs,  DateTime createdAt,  List<BenchmarkRequest> requests,  List<BenchmarkSample> samples)?  $default,) {final _that = this;
switch (_that) {
case _SavedBenchmark() when $default != null:
return $default(_that.id,_that.name,_that.endpoint,_that.machineName,_that.command,_that.prompt,_that.batchSize,_that.aggregateTokensPerSecond,_that.completed,_that.medianTtftMs,_that.elapsedMs,_that.createdAt,_that.requests,_that.samples);case _:
  return null;

}
}

}

/// @nodoc


class _SavedBenchmark extends SavedBenchmark {
  const _SavedBenchmark({required this.id, required this.name, required this.endpoint, this.machineName, this.command = '', required this.prompt, required this.batchSize, required this.aggregateTokensPerSecond, required this.completed, required this.medianTtftMs, required this.elapsedMs, required this.createdAt, final  List<BenchmarkRequest> requests = const <BenchmarkRequest>[], final  List<BenchmarkSample> samples = const <BenchmarkSample>[]}): _requests = requests,_samples = samples,super._();
  

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedBenchmark&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.machineName, machineName) || other.machineName == machineName)&&(identical(other.command, command) || other.command == command)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.batchSize, batchSize) || other.batchSize == batchSize)&&(identical(other.aggregateTokensPerSecond, aggregateTokensPerSecond) || other.aggregateTokensPerSecond == aggregateTokensPerSecond)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.medianTtftMs, medianTtftMs) || other.medianTtftMs == medianTtftMs)&&(identical(other.elapsedMs, elapsedMs) || other.elapsedMs == elapsedMs)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._requests, _requests)&&const DeepCollectionEquality().equals(other._samples, _samples));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,endpoint,machineName,command,prompt,batchSize,aggregateTokensPerSecond,completed,medianTtftMs,elapsedMs,createdAt,const DeepCollectionEquality().hash(_requests),const DeepCollectionEquality().hash(_samples));

@override
String toString() {
  return 'SavedBenchmark(id: $id, name: $name, endpoint: $endpoint, machineName: $machineName, command: $command, prompt: $prompt, batchSize: $batchSize, aggregateTokensPerSecond: $aggregateTokensPerSecond, completed: $completed, medianTtftMs: $medianTtftMs, elapsedMs: $elapsedMs, createdAt: $createdAt, requests: $requests, samples: $samples)';
}


}

/// @nodoc
abstract mixin class _$SavedBenchmarkCopyWith<$Res> implements $SavedBenchmarkCopyWith<$Res> {
  factory _$SavedBenchmarkCopyWith(_SavedBenchmark value, $Res Function(_SavedBenchmark) _then) = __$SavedBenchmarkCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String endpoint, String? machineName, String command, String prompt, int batchSize, double aggregateTokensPerSecond, int completed, int medianTtftMs, int elapsedMs, DateTime createdAt, List<BenchmarkRequest> requests, List<BenchmarkSample> samples
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? endpoint = null,Object? machineName = freezed,Object? command = null,Object? prompt = null,Object? batchSize = null,Object? aggregateTokensPerSecond = null,Object? completed = null,Object? medianTtftMs = null,Object? elapsedMs = null,Object? createdAt = null,Object? requests = null,Object? samples = null,}) {
  return _then(_SavedBenchmark(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,machineName: freezed == machineName ? _self.machineName : machineName // ignore: cast_nullable_to_non_nullable
as String?,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,batchSize: null == batchSize ? _self.batchSize : batchSize // ignore: cast_nullable_to_non_nullable
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
