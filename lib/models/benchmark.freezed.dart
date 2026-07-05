// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'benchmark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BenchmarkRequest {

 int get index; BenchmarkRequestStatus get status; String get text; int get tokens; double get tokensPerSecond; int? get ttftMs; int? get latencyMs;/// The server's `finish_reason` for the reply, once one arrived
/// (`stop`, `length`, `tool_calls`, …).
 String? get finishReason;
/// Create a copy of BenchmarkRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BenchmarkRequestCopyWith<BenchmarkRequest> get copyWith => _$BenchmarkRequestCopyWithImpl<BenchmarkRequest>(this as BenchmarkRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BenchmarkRequest&&(identical(other.index, index) || other.index == index)&&(identical(other.status, status) || other.status == status)&&(identical(other.text, text) || other.text == text)&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.tokensPerSecond, tokensPerSecond) || other.tokensPerSecond == tokensPerSecond)&&(identical(other.ttftMs, ttftMs) || other.ttftMs == ttftMs)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.finishReason, finishReason) || other.finishReason == finishReason));
}


@override
int get hashCode => Object.hash(runtimeType,index,status,text,tokens,tokensPerSecond,ttftMs,latencyMs,finishReason);

@override
String toString() {
  return 'BenchmarkRequest(index: $index, status: $status, text: $text, tokens: $tokens, tokensPerSecond: $tokensPerSecond, ttftMs: $ttftMs, latencyMs: $latencyMs, finishReason: $finishReason)';
}


}

/// @nodoc
abstract mixin class $BenchmarkRequestCopyWith<$Res>  {
  factory $BenchmarkRequestCopyWith(BenchmarkRequest value, $Res Function(BenchmarkRequest) _then) = _$BenchmarkRequestCopyWithImpl;
@useResult
$Res call({
 int index, BenchmarkRequestStatus status, String text, int tokens, double tokensPerSecond, int? ttftMs, int? latencyMs, String? finishReason
});




}
/// @nodoc
class _$BenchmarkRequestCopyWithImpl<$Res>
    implements $BenchmarkRequestCopyWith<$Res> {
  _$BenchmarkRequestCopyWithImpl(this._self, this._then);

  final BenchmarkRequest _self;
  final $Res Function(BenchmarkRequest) _then;

/// Create a copy of BenchmarkRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? status = null,Object? text = null,Object? tokens = null,Object? tokensPerSecond = null,Object? ttftMs = freezed,Object? latencyMs = freezed,Object? finishReason = freezed,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BenchmarkRequestStatus,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as int,tokensPerSecond: null == tokensPerSecond ? _self.tokensPerSecond : tokensPerSecond // ignore: cast_nullable_to_non_nullable
as double,ttftMs: freezed == ttftMs ? _self.ttftMs : ttftMs // ignore: cast_nullable_to_non_nullable
as int?,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,finishReason: freezed == finishReason ? _self.finishReason : finishReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BenchmarkRequest].
extension BenchmarkRequestPatterns on BenchmarkRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BenchmarkRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BenchmarkRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BenchmarkRequest value)  $default,){
final _that = this;
switch (_that) {
case _BenchmarkRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BenchmarkRequest value)?  $default,){
final _that = this;
switch (_that) {
case _BenchmarkRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  BenchmarkRequestStatus status,  String text,  int tokens,  double tokensPerSecond,  int? ttftMs,  int? latencyMs,  String? finishReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BenchmarkRequest() when $default != null:
return $default(_that.index,_that.status,_that.text,_that.tokens,_that.tokensPerSecond,_that.ttftMs,_that.latencyMs,_that.finishReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  BenchmarkRequestStatus status,  String text,  int tokens,  double tokensPerSecond,  int? ttftMs,  int? latencyMs,  String? finishReason)  $default,) {final _that = this;
switch (_that) {
case _BenchmarkRequest():
return $default(_that.index,_that.status,_that.text,_that.tokens,_that.tokensPerSecond,_that.ttftMs,_that.latencyMs,_that.finishReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  BenchmarkRequestStatus status,  String text,  int tokens,  double tokensPerSecond,  int? ttftMs,  int? latencyMs,  String? finishReason)?  $default,) {final _that = this;
switch (_that) {
case _BenchmarkRequest() when $default != null:
return $default(_that.index,_that.status,_that.text,_that.tokens,_that.tokensPerSecond,_that.ttftMs,_that.latencyMs,_that.finishReason);case _:
  return null;

}
}

}

/// @nodoc


class _BenchmarkRequest extends BenchmarkRequest {
  const _BenchmarkRequest({required this.index, this.status = BenchmarkRequestStatus.queued, this.text = '', this.tokens = 0, this.tokensPerSecond = 0, this.ttftMs, this.latencyMs, this.finishReason}): super._();
  

@override final  int index;
@override@JsonKey() final  BenchmarkRequestStatus status;
@override@JsonKey() final  String text;
@override@JsonKey() final  int tokens;
@override@JsonKey() final  double tokensPerSecond;
@override final  int? ttftMs;
@override final  int? latencyMs;
/// The server's `finish_reason` for the reply, once one arrived
/// (`stop`, `length`, `tool_calls`, …).
@override final  String? finishReason;

/// Create a copy of BenchmarkRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BenchmarkRequestCopyWith<_BenchmarkRequest> get copyWith => __$BenchmarkRequestCopyWithImpl<_BenchmarkRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BenchmarkRequest&&(identical(other.index, index) || other.index == index)&&(identical(other.status, status) || other.status == status)&&(identical(other.text, text) || other.text == text)&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.tokensPerSecond, tokensPerSecond) || other.tokensPerSecond == tokensPerSecond)&&(identical(other.ttftMs, ttftMs) || other.ttftMs == ttftMs)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.finishReason, finishReason) || other.finishReason == finishReason));
}


@override
int get hashCode => Object.hash(runtimeType,index,status,text,tokens,tokensPerSecond,ttftMs,latencyMs,finishReason);

@override
String toString() {
  return 'BenchmarkRequest(index: $index, status: $status, text: $text, tokens: $tokens, tokensPerSecond: $tokensPerSecond, ttftMs: $ttftMs, latencyMs: $latencyMs, finishReason: $finishReason)';
}


}

/// @nodoc
abstract mixin class _$BenchmarkRequestCopyWith<$Res> implements $BenchmarkRequestCopyWith<$Res> {
  factory _$BenchmarkRequestCopyWith(_BenchmarkRequest value, $Res Function(_BenchmarkRequest) _then) = __$BenchmarkRequestCopyWithImpl;
@override @useResult
$Res call({
 int index, BenchmarkRequestStatus status, String text, int tokens, double tokensPerSecond, int? ttftMs, int? latencyMs, String? finishReason
});




}
/// @nodoc
class __$BenchmarkRequestCopyWithImpl<$Res>
    implements _$BenchmarkRequestCopyWith<$Res> {
  __$BenchmarkRequestCopyWithImpl(this._self, this._then);

  final _BenchmarkRequest _self;
  final $Res Function(_BenchmarkRequest) _then;

/// Create a copy of BenchmarkRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? status = null,Object? text = null,Object? tokens = null,Object? tokensPerSecond = null,Object? ttftMs = freezed,Object? latencyMs = freezed,Object? finishReason = freezed,}) {
  return _then(_BenchmarkRequest(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BenchmarkRequestStatus,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as int,tokensPerSecond: null == tokensPerSecond ? _self.tokensPerSecond : tokensPerSecond // ignore: cast_nullable_to_non_nullable
as double,ttftMs: freezed == ttftMs ? _self.ttftMs : ttftMs // ignore: cast_nullable_to_non_nullable
as int?,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,finishReason: freezed == finishReason ? _self.finishReason : finishReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$BenchmarkRun {

 String get prompt; int get batchSize;/// Per-request output-token cap. Null means unlimited — the server decides
/// (it stops at its max sequence length).
 int? get maxTokens;/// Sampling temperature. Null means the server's default.
 double? get temperature; List<BenchmarkRequest> get requests; bool get isRunning; Duration get elapsed;// The aggregate throughput captured at full concurrency (see
// [aggregateTokensPerSecond]). 0 until the first request finishes, then
// held static for the rest of the run and after.
 double get frozenAggregate;
/// Create a copy of BenchmarkRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BenchmarkRunCopyWith<BenchmarkRun> get copyWith => _$BenchmarkRunCopyWithImpl<BenchmarkRun>(this as BenchmarkRun, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BenchmarkRun&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.batchSize, batchSize) || other.batchSize == batchSize)&&(identical(other.maxTokens, maxTokens) || other.maxTokens == maxTokens)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&const DeepCollectionEquality().equals(other.requests, requests)&&(identical(other.isRunning, isRunning) || other.isRunning == isRunning)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.frozenAggregate, frozenAggregate) || other.frozenAggregate == frozenAggregate));
}


@override
int get hashCode => Object.hash(runtimeType,prompt,batchSize,maxTokens,temperature,const DeepCollectionEquality().hash(requests),isRunning,elapsed,frozenAggregate);

@override
String toString() {
  return 'BenchmarkRun(prompt: $prompt, batchSize: $batchSize, maxTokens: $maxTokens, temperature: $temperature, requests: $requests, isRunning: $isRunning, elapsed: $elapsed, frozenAggregate: $frozenAggregate)';
}


}

/// @nodoc
abstract mixin class $BenchmarkRunCopyWith<$Res>  {
  factory $BenchmarkRunCopyWith(BenchmarkRun value, $Res Function(BenchmarkRun) _then) = _$BenchmarkRunCopyWithImpl;
@useResult
$Res call({
 String prompt, int batchSize, int? maxTokens, double? temperature, List<BenchmarkRequest> requests, bool isRunning, Duration elapsed, double frozenAggregate
});




}
/// @nodoc
class _$BenchmarkRunCopyWithImpl<$Res>
    implements $BenchmarkRunCopyWith<$Res> {
  _$BenchmarkRunCopyWithImpl(this._self, this._then);

  final BenchmarkRun _self;
  final $Res Function(BenchmarkRun) _then;

/// Create a copy of BenchmarkRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? prompt = null,Object? batchSize = null,Object? maxTokens = freezed,Object? temperature = freezed,Object? requests = null,Object? isRunning = null,Object? elapsed = null,Object? frozenAggregate = null,}) {
  return _then(_self.copyWith(
prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,batchSize: null == batchSize ? _self.batchSize : batchSize // ignore: cast_nullable_to_non_nullable
as int,maxTokens: freezed == maxTokens ? _self.maxTokens : maxTokens // ignore: cast_nullable_to_non_nullable
as int?,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as List<BenchmarkRequest>,isRunning: null == isRunning ? _self.isRunning : isRunning // ignore: cast_nullable_to_non_nullable
as bool,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as Duration,frozenAggregate: null == frozenAggregate ? _self.frozenAggregate : frozenAggregate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BenchmarkRun].
extension BenchmarkRunPatterns on BenchmarkRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BenchmarkRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BenchmarkRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BenchmarkRun value)  $default,){
final _that = this;
switch (_that) {
case _BenchmarkRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BenchmarkRun value)?  $default,){
final _that = this;
switch (_that) {
case _BenchmarkRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String prompt,  int batchSize,  int? maxTokens,  double? temperature,  List<BenchmarkRequest> requests,  bool isRunning,  Duration elapsed,  double frozenAggregate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BenchmarkRun() when $default != null:
return $default(_that.prompt,_that.batchSize,_that.maxTokens,_that.temperature,_that.requests,_that.isRunning,_that.elapsed,_that.frozenAggregate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String prompt,  int batchSize,  int? maxTokens,  double? temperature,  List<BenchmarkRequest> requests,  bool isRunning,  Duration elapsed,  double frozenAggregate)  $default,) {final _that = this;
switch (_that) {
case _BenchmarkRun():
return $default(_that.prompt,_that.batchSize,_that.maxTokens,_that.temperature,_that.requests,_that.isRunning,_that.elapsed,_that.frozenAggregate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String prompt,  int batchSize,  int? maxTokens,  double? temperature,  List<BenchmarkRequest> requests,  bool isRunning,  Duration elapsed,  double frozenAggregate)?  $default,) {final _that = this;
switch (_that) {
case _BenchmarkRun() when $default != null:
return $default(_that.prompt,_that.batchSize,_that.maxTokens,_that.temperature,_that.requests,_that.isRunning,_that.elapsed,_that.frozenAggregate);case _:
  return null;

}
}

}

/// @nodoc


class _BenchmarkRun extends BenchmarkRun {
  const _BenchmarkRun({required this.prompt, required this.batchSize, this.maxTokens, this.temperature, final  List<BenchmarkRequest> requests = const <BenchmarkRequest>[], this.isRunning = false, this.elapsed = Duration.zero, this.frozenAggregate = 0.0}): _requests = requests,super._();
  

@override final  String prompt;
@override final  int batchSize;
/// Per-request output-token cap. Null means unlimited — the server decides
/// (it stops at its max sequence length).
@override final  int? maxTokens;
/// Sampling temperature. Null means the server's default.
@override final  double? temperature;
 final  List<BenchmarkRequest> _requests;
@override@JsonKey() List<BenchmarkRequest> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}

@override@JsonKey() final  bool isRunning;
@override@JsonKey() final  Duration elapsed;
// The aggregate throughput captured at full concurrency (see
// [aggregateTokensPerSecond]). 0 until the first request finishes, then
// held static for the rest of the run and after.
@override@JsonKey() final  double frozenAggregate;

/// Create a copy of BenchmarkRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BenchmarkRunCopyWith<_BenchmarkRun> get copyWith => __$BenchmarkRunCopyWithImpl<_BenchmarkRun>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BenchmarkRun&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.batchSize, batchSize) || other.batchSize == batchSize)&&(identical(other.maxTokens, maxTokens) || other.maxTokens == maxTokens)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&const DeepCollectionEquality().equals(other._requests, _requests)&&(identical(other.isRunning, isRunning) || other.isRunning == isRunning)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.frozenAggregate, frozenAggregate) || other.frozenAggregate == frozenAggregate));
}


@override
int get hashCode => Object.hash(runtimeType,prompt,batchSize,maxTokens,temperature,const DeepCollectionEquality().hash(_requests),isRunning,elapsed,frozenAggregate);

@override
String toString() {
  return 'BenchmarkRun(prompt: $prompt, batchSize: $batchSize, maxTokens: $maxTokens, temperature: $temperature, requests: $requests, isRunning: $isRunning, elapsed: $elapsed, frozenAggregate: $frozenAggregate)';
}


}

/// @nodoc
abstract mixin class _$BenchmarkRunCopyWith<$Res> implements $BenchmarkRunCopyWith<$Res> {
  factory _$BenchmarkRunCopyWith(_BenchmarkRun value, $Res Function(_BenchmarkRun) _then) = __$BenchmarkRunCopyWithImpl;
@override @useResult
$Res call({
 String prompt, int batchSize, int? maxTokens, double? temperature, List<BenchmarkRequest> requests, bool isRunning, Duration elapsed, double frozenAggregate
});




}
/// @nodoc
class __$BenchmarkRunCopyWithImpl<$Res>
    implements _$BenchmarkRunCopyWith<$Res> {
  __$BenchmarkRunCopyWithImpl(this._self, this._then);

  final _BenchmarkRun _self;
  final $Res Function(_BenchmarkRun) _then;

/// Create a copy of BenchmarkRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? prompt = null,Object? batchSize = null,Object? maxTokens = freezed,Object? temperature = freezed,Object? requests = null,Object? isRunning = null,Object? elapsed = null,Object? frozenAggregate = null,}) {
  return _then(_BenchmarkRun(
prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,batchSize: null == batchSize ? _self.batchSize : batchSize // ignore: cast_nullable_to_non_nullable
as int,maxTokens: freezed == maxTokens ? _self.maxTokens : maxTokens // ignore: cast_nullable_to_non_nullable
as int?,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,requests: null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<BenchmarkRequest>,isRunning: null == isRunning ? _self.isRunning : isRunning // ignore: cast_nullable_to_non_nullable
as bool,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as Duration,frozenAggregate: null == frozenAggregate ? _self.frozenAggregate : frozenAggregate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
