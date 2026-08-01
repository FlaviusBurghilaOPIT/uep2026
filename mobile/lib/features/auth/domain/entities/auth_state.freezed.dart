// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthState {

 bool get isSignedIn; bool get isLoading;/// True until the boot-time JWT check ([AuthNotifier.checkAuthStatus])
/// finishes. Boot routing waits for this to flip false before deciding
/// main vs Welcome, so a stored-but-invalid token is never routed around.
 bool get isInitializing; String? get errorMessage; String? get patientId; String? get caseId; String? get fullName; String? get email; String? get phone; String? get dateOfBirth; String? get primaryCondition; String? get inviteCode;
/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStateCopyWith<AuthState> get copyWith => _$AuthStateCopyWithImpl<AuthState>(this as AuthState, _$identity);

  /// Serializes this AuthState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState&&(identical(other.isSignedIn, isSignedIn) || other.isSignedIn == isSignedIn)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isInitializing, isInitializing) || other.isInitializing == isInitializing)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.caseId, caseId) || other.caseId == caseId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.primaryCondition, primaryCondition) || other.primaryCondition == primaryCondition)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isSignedIn,isLoading,isInitializing,errorMessage,patientId,caseId,fullName,email,phone,dateOfBirth,primaryCondition,inviteCode);

@override
String toString() {
  return 'AuthState(isSignedIn: $isSignedIn, isLoading: $isLoading, isInitializing: $isInitializing, errorMessage: $errorMessage, patientId: $patientId, caseId: $caseId, fullName: $fullName, email: $email, phone: $phone, dateOfBirth: $dateOfBirth, primaryCondition: $primaryCondition, inviteCode: $inviteCode)';
}


}

/// @nodoc
abstract mixin class $AuthStateCopyWith<$Res>  {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) _then) = _$AuthStateCopyWithImpl;
@useResult
$Res call({
 bool isSignedIn, bool isLoading, bool isInitializing, String? errorMessage, String? patientId, String? caseId, String? fullName, String? email, String? phone, String? dateOfBirth, String? primaryCondition, String? inviteCode
});




}
/// @nodoc
class _$AuthStateCopyWithImpl<$Res>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._self, this._then);

  final AuthState _self;
  final $Res Function(AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSignedIn = null,Object? isLoading = null,Object? isInitializing = null,Object? errorMessage = freezed,Object? patientId = freezed,Object? caseId = freezed,Object? fullName = freezed,Object? email = freezed,Object? phone = freezed,Object? dateOfBirth = freezed,Object? primaryCondition = freezed,Object? inviteCode = freezed,}) {
  return _then(_self.copyWith(
isSignedIn: null == isSignedIn ? _self.isSignedIn : isSignedIn // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isInitializing: null == isInitializing ? _self.isInitializing : isInitializing // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,patientId: freezed == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String?,caseId: freezed == caseId ? _self.caseId : caseId // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,primaryCondition: freezed == primaryCondition ? _self.primaryCondition : primaryCondition // ignore: cast_nullable_to_non_nullable
as String?,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthState value)  $default,){
final _that = this;
switch (_that) {
case _AuthState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isSignedIn,  bool isLoading,  bool isInitializing,  String? errorMessage,  String? patientId,  String? caseId,  String? fullName,  String? email,  String? phone,  String? dateOfBirth,  String? primaryCondition,  String? inviteCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.isSignedIn,_that.isLoading,_that.isInitializing,_that.errorMessage,_that.patientId,_that.caseId,_that.fullName,_that.email,_that.phone,_that.dateOfBirth,_that.primaryCondition,_that.inviteCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isSignedIn,  bool isLoading,  bool isInitializing,  String? errorMessage,  String? patientId,  String? caseId,  String? fullName,  String? email,  String? phone,  String? dateOfBirth,  String? primaryCondition,  String? inviteCode)  $default,) {final _that = this;
switch (_that) {
case _AuthState():
return $default(_that.isSignedIn,_that.isLoading,_that.isInitializing,_that.errorMessage,_that.patientId,_that.caseId,_that.fullName,_that.email,_that.phone,_that.dateOfBirth,_that.primaryCondition,_that.inviteCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isSignedIn,  bool isLoading,  bool isInitializing,  String? errorMessage,  String? patientId,  String? caseId,  String? fullName,  String? email,  String? phone,  String? dateOfBirth,  String? primaryCondition,  String? inviteCode)?  $default,) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.isSignedIn,_that.isLoading,_that.isInitializing,_that.errorMessage,_that.patientId,_that.caseId,_that.fullName,_that.email,_that.phone,_that.dateOfBirth,_that.primaryCondition,_that.inviteCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthState implements AuthState {
  const _AuthState({this.isSignedIn = false, this.isLoading = false, this.isInitializing = true, this.errorMessage, this.patientId, this.caseId, this.fullName, this.email, this.phone, this.dateOfBirth, this.primaryCondition, this.inviteCode});
  factory _AuthState.fromJson(Map<String, dynamic> json) => _$AuthStateFromJson(json);

@override@JsonKey() final  bool isSignedIn;
@override@JsonKey() final  bool isLoading;
/// True until the boot-time JWT check ([AuthNotifier.checkAuthStatus])
/// finishes. Boot routing waits for this to flip false before deciding
/// main vs Welcome, so a stored-but-invalid token is never routed around.
@override@JsonKey() final  bool isInitializing;
@override final  String? errorMessage;
@override final  String? patientId;
@override final  String? caseId;
@override final  String? fullName;
@override final  String? email;
@override final  String? phone;
@override final  String? dateOfBirth;
@override final  String? primaryCondition;
@override final  String? inviteCode;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthStateCopyWith<_AuthState> get copyWith => __$AuthStateCopyWithImpl<_AuthState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthState&&(identical(other.isSignedIn, isSignedIn) || other.isSignedIn == isSignedIn)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isInitializing, isInitializing) || other.isInitializing == isInitializing)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.caseId, caseId) || other.caseId == caseId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.primaryCondition, primaryCondition) || other.primaryCondition == primaryCondition)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isSignedIn,isLoading,isInitializing,errorMessage,patientId,caseId,fullName,email,phone,dateOfBirth,primaryCondition,inviteCode);

@override
String toString() {
  return 'AuthState(isSignedIn: $isSignedIn, isLoading: $isLoading, isInitializing: $isInitializing, errorMessage: $errorMessage, patientId: $patientId, caseId: $caseId, fullName: $fullName, email: $email, phone: $phone, dateOfBirth: $dateOfBirth, primaryCondition: $primaryCondition, inviteCode: $inviteCode)';
}


}

/// @nodoc
abstract mixin class _$AuthStateCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory _$AuthStateCopyWith(_AuthState value, $Res Function(_AuthState) _then) = __$AuthStateCopyWithImpl;
@override @useResult
$Res call({
 bool isSignedIn, bool isLoading, bool isInitializing, String? errorMessage, String? patientId, String? caseId, String? fullName, String? email, String? phone, String? dateOfBirth, String? primaryCondition, String? inviteCode
});




}
/// @nodoc
class __$AuthStateCopyWithImpl<$Res>
    implements _$AuthStateCopyWith<$Res> {
  __$AuthStateCopyWithImpl(this._self, this._then);

  final _AuthState _self;
  final $Res Function(_AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSignedIn = null,Object? isLoading = null,Object? isInitializing = null,Object? errorMessage = freezed,Object? patientId = freezed,Object? caseId = freezed,Object? fullName = freezed,Object? email = freezed,Object? phone = freezed,Object? dateOfBirth = freezed,Object? primaryCondition = freezed,Object? inviteCode = freezed,}) {
  return _then(_AuthState(
isSignedIn: null == isSignedIn ? _self.isSignedIn : isSignedIn // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isInitializing: null == isInitializing ? _self.isInitializing : isInitializing // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,patientId: freezed == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String?,caseId: freezed == caseId ? _self.caseId : caseId // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,primaryCondition: freezed == primaryCondition ? _self.primaryCondition : primaryCondition // ignore: cast_nullable_to_non_nullable
as String?,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
