// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'benchmark_chat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatTurn {

 bool get fromUser; String get text; bool get streaming; int get tokens; double get tokensPerSecond; int? get ttftMs; int? get latencyMs;
/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTurnCopyWith<ChatTurn> get copyWith => _$ChatTurnCopyWithImpl<ChatTurn>(this as ChatTurn, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTurn&&(identical(other.fromUser, fromUser) || other.fromUser == fromUser)&&(identical(other.text, text) || other.text == text)&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.tokensPerSecond, tokensPerSecond) || other.tokensPerSecond == tokensPerSecond)&&(identical(other.ttftMs, ttftMs) || other.ttftMs == ttftMs)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs));
}


@override
int get hashCode => Object.hash(runtimeType,fromUser,text,streaming,tokens,tokensPerSecond,ttftMs,latencyMs);

@override
String toString() {
  return 'ChatTurn(fromUser: $fromUser, text: $text, streaming: $streaming, tokens: $tokens, tokensPerSecond: $tokensPerSecond, ttftMs: $ttftMs, latencyMs: $latencyMs)';
}


}

/// @nodoc
abstract mixin class $ChatTurnCopyWith<$Res>  {
  factory $ChatTurnCopyWith(ChatTurn value, $Res Function(ChatTurn) _then) = _$ChatTurnCopyWithImpl;
@useResult
$Res call({
 bool fromUser, String text, bool streaming, int tokens, double tokensPerSecond, int? ttftMs, int? latencyMs
});




}
/// @nodoc
class _$ChatTurnCopyWithImpl<$Res>
    implements $ChatTurnCopyWith<$Res> {
  _$ChatTurnCopyWithImpl(this._self, this._then);

  final ChatTurn _self;
  final $Res Function(ChatTurn) _then;

/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fromUser = null,Object? text = null,Object? streaming = null,Object? tokens = null,Object? tokensPerSecond = null,Object? ttftMs = freezed,Object? latencyMs = freezed,}) {
  return _then(_self.copyWith(
fromUser: null == fromUser ? _self.fromUser : fromUser // ignore: cast_nullable_to_non_nullable
as bool,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as bool,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as int,tokensPerSecond: null == tokensPerSecond ? _self.tokensPerSecond : tokensPerSecond // ignore: cast_nullable_to_non_nullable
as double,ttftMs: freezed == ttftMs ? _self.ttftMs : ttftMs // ignore: cast_nullable_to_non_nullable
as int?,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatTurn].
extension ChatTurnPatterns on ChatTurn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatTurn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatTurn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatTurn value)  $default,){
final _that = this;
switch (_that) {
case _ChatTurn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatTurn value)?  $default,){
final _that = this;
switch (_that) {
case _ChatTurn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool fromUser,  String text,  bool streaming,  int tokens,  double tokensPerSecond,  int? ttftMs,  int? latencyMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatTurn() when $default != null:
return $default(_that.fromUser,_that.text,_that.streaming,_that.tokens,_that.tokensPerSecond,_that.ttftMs,_that.latencyMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool fromUser,  String text,  bool streaming,  int tokens,  double tokensPerSecond,  int? ttftMs,  int? latencyMs)  $default,) {final _that = this;
switch (_that) {
case _ChatTurn():
return $default(_that.fromUser,_that.text,_that.streaming,_that.tokens,_that.tokensPerSecond,_that.ttftMs,_that.latencyMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool fromUser,  String text,  bool streaming,  int tokens,  double tokensPerSecond,  int? ttftMs,  int? latencyMs)?  $default,) {final _that = this;
switch (_that) {
case _ChatTurn() when $default != null:
return $default(_that.fromUser,_that.text,_that.streaming,_that.tokens,_that.tokensPerSecond,_that.ttftMs,_that.latencyMs);case _:
  return null;

}
}

}

/// @nodoc


class _ChatTurn implements ChatTurn {
  const _ChatTurn({required this.fromUser, this.text = '', this.streaming = false, this.tokens = 0, this.tokensPerSecond = 0.0, this.ttftMs, this.latencyMs});
  

@override final  bool fromUser;
@override@JsonKey() final  String text;
@override@JsonKey() final  bool streaming;
@override@JsonKey() final  int tokens;
@override@JsonKey() final  double tokensPerSecond;
@override final  int? ttftMs;
@override final  int? latencyMs;

/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatTurnCopyWith<_ChatTurn> get copyWith => __$ChatTurnCopyWithImpl<_ChatTurn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatTurn&&(identical(other.fromUser, fromUser) || other.fromUser == fromUser)&&(identical(other.text, text) || other.text == text)&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.tokensPerSecond, tokensPerSecond) || other.tokensPerSecond == tokensPerSecond)&&(identical(other.ttftMs, ttftMs) || other.ttftMs == ttftMs)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs));
}


@override
int get hashCode => Object.hash(runtimeType,fromUser,text,streaming,tokens,tokensPerSecond,ttftMs,latencyMs);

@override
String toString() {
  return 'ChatTurn(fromUser: $fromUser, text: $text, streaming: $streaming, tokens: $tokens, tokensPerSecond: $tokensPerSecond, ttftMs: $ttftMs, latencyMs: $latencyMs)';
}


}

/// @nodoc
abstract mixin class _$ChatTurnCopyWith<$Res> implements $ChatTurnCopyWith<$Res> {
  factory _$ChatTurnCopyWith(_ChatTurn value, $Res Function(_ChatTurn) _then) = __$ChatTurnCopyWithImpl;
@override @useResult
$Res call({
 bool fromUser, String text, bool streaming, int tokens, double tokensPerSecond, int? ttftMs, int? latencyMs
});




}
/// @nodoc
class __$ChatTurnCopyWithImpl<$Res>
    implements _$ChatTurnCopyWith<$Res> {
  __$ChatTurnCopyWithImpl(this._self, this._then);

  final _ChatTurn _self;
  final $Res Function(_ChatTurn) _then;

/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fromUser = null,Object? text = null,Object? streaming = null,Object? tokens = null,Object? tokensPerSecond = null,Object? ttftMs = freezed,Object? latencyMs = freezed,}) {
  return _then(_ChatTurn(
fromUser: null == fromUser ? _self.fromUser : fromUser // ignore: cast_nullable_to_non_nullable
as bool,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as bool,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as int,tokensPerSecond: null == tokensPerSecond ? _self.tokensPerSecond : tokensPerSecond // ignore: cast_nullable_to_non_nullable
as double,ttftMs: freezed == ttftMs ? _self.ttftMs : ttftMs // ignore: cast_nullable_to_non_nullable
as int?,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$BenchmarkChat {

 List<ChatTurn> get turns;
/// Create a copy of BenchmarkChat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BenchmarkChatCopyWith<BenchmarkChat> get copyWith => _$BenchmarkChatCopyWithImpl<BenchmarkChat>(this as BenchmarkChat, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BenchmarkChat&&const DeepCollectionEquality().equals(other.turns, turns));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(turns));

@override
String toString() {
  return 'BenchmarkChat(turns: $turns)';
}


}

/// @nodoc
abstract mixin class $BenchmarkChatCopyWith<$Res>  {
  factory $BenchmarkChatCopyWith(BenchmarkChat value, $Res Function(BenchmarkChat) _then) = _$BenchmarkChatCopyWithImpl;
@useResult
$Res call({
 List<ChatTurn> turns
});




}
/// @nodoc
class _$BenchmarkChatCopyWithImpl<$Res>
    implements $BenchmarkChatCopyWith<$Res> {
  _$BenchmarkChatCopyWithImpl(this._self, this._then);

  final BenchmarkChat _self;
  final $Res Function(BenchmarkChat) _then;

/// Create a copy of BenchmarkChat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? turns = null,}) {
  return _then(_self.copyWith(
turns: null == turns ? _self.turns : turns // ignore: cast_nullable_to_non_nullable
as List<ChatTurn>,
  ));
}

}


/// Adds pattern-matching-related methods to [BenchmarkChat].
extension BenchmarkChatPatterns on BenchmarkChat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BenchmarkChat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BenchmarkChat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BenchmarkChat value)  $default,){
final _that = this;
switch (_that) {
case _BenchmarkChat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BenchmarkChat value)?  $default,){
final _that = this;
switch (_that) {
case _BenchmarkChat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ChatTurn> turns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BenchmarkChat() when $default != null:
return $default(_that.turns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ChatTurn> turns)  $default,) {final _that = this;
switch (_that) {
case _BenchmarkChat():
return $default(_that.turns);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ChatTurn> turns)?  $default,) {final _that = this;
switch (_that) {
case _BenchmarkChat() when $default != null:
return $default(_that.turns);case _:
  return null;

}
}

}

/// @nodoc


class _BenchmarkChat extends BenchmarkChat {
  const _BenchmarkChat({final  List<ChatTurn> turns = const <ChatTurn>[]}): _turns = turns,super._();
  

 final  List<ChatTurn> _turns;
@override@JsonKey() List<ChatTurn> get turns {
  if (_turns is EqualUnmodifiableListView) return _turns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_turns);
}


/// Create a copy of BenchmarkChat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BenchmarkChatCopyWith<_BenchmarkChat> get copyWith => __$BenchmarkChatCopyWithImpl<_BenchmarkChat>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BenchmarkChat&&const DeepCollectionEquality().equals(other._turns, _turns));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_turns));

@override
String toString() {
  return 'BenchmarkChat(turns: $turns)';
}


}

/// @nodoc
abstract mixin class _$BenchmarkChatCopyWith<$Res> implements $BenchmarkChatCopyWith<$Res> {
  factory _$BenchmarkChatCopyWith(_BenchmarkChat value, $Res Function(_BenchmarkChat) _then) = __$BenchmarkChatCopyWithImpl;
@override @useResult
$Res call({
 List<ChatTurn> turns
});




}
/// @nodoc
class __$BenchmarkChatCopyWithImpl<$Res>
    implements _$BenchmarkChatCopyWith<$Res> {
  __$BenchmarkChatCopyWithImpl(this._self, this._then);

  final _BenchmarkChat _self;
  final $Res Function(_BenchmarkChat) _then;

/// Create a copy of BenchmarkChat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? turns = null,}) {
  return _then(_BenchmarkChat(
turns: null == turns ? _self._turns : turns // ignore: cast_nullable_to_non_nullable
as List<ChatTurn>,
  ));
}


}

// dart format on
