// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agenda_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AgendaSlot {

 String get slotId; String get medicationId; String get medicationName; String get dose; String? get notes; DateTime get scheduledTime; SlotState get state; DateTime? get loggedAt; String? get doseLogId; String? get previousStatus;
/// Create a copy of AgendaSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgendaSlotCopyWith<AgendaSlot> get copyWith => _$AgendaSlotCopyWithImpl<AgendaSlot>(this as AgendaSlot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgendaSlot&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId)&&(identical(other.medicationName, medicationName) || other.medicationName == medicationName)&&(identical(other.dose, dose) || other.dose == dose)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.state, state) || other.state == state)&&(identical(other.loggedAt, loggedAt) || other.loggedAt == loggedAt)&&(identical(other.doseLogId, doseLogId) || other.doseLogId == doseLogId)&&(identical(other.previousStatus, previousStatus) || other.previousStatus == previousStatus));
}


@override
int get hashCode => Object.hash(runtimeType,slotId,medicationId,medicationName,dose,notes,scheduledTime,state,loggedAt,doseLogId,previousStatus);

@override
String toString() {
  return 'AgendaSlot(slotId: $slotId, medicationId: $medicationId, medicationName: $medicationName, dose: $dose, notes: $notes, scheduledTime: $scheduledTime, state: $state, loggedAt: $loggedAt, doseLogId: $doseLogId, previousStatus: $previousStatus)';
}


}

/// @nodoc
abstract mixin class $AgendaSlotCopyWith<$Res>  {
  factory $AgendaSlotCopyWith(AgendaSlot value, $Res Function(AgendaSlot) _then) = _$AgendaSlotCopyWithImpl;
@useResult
$Res call({
 String slotId, String medicationId, String medicationName, String dose, String? notes, DateTime scheduledTime, SlotState state, DateTime? loggedAt, String? doseLogId, String? previousStatus
});




}
/// @nodoc
class _$AgendaSlotCopyWithImpl<$Res>
    implements $AgendaSlotCopyWith<$Res> {
  _$AgendaSlotCopyWithImpl(this._self, this._then);

  final AgendaSlot _self;
  final $Res Function(AgendaSlot) _then;

/// Create a copy of AgendaSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slotId = null,Object? medicationId = null,Object? medicationName = null,Object? dose = null,Object? notes = freezed,Object? scheduledTime = null,Object? state = null,Object? loggedAt = freezed,Object? doseLogId = freezed,Object? previousStatus = freezed,}) {
  return _then(_self.copyWith(
slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,medicationId: null == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as String,medicationName: null == medicationName ? _self.medicationName : medicationName // ignore: cast_nullable_to_non_nullable
as String,dose: null == dose ? _self.dose : dose // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,scheduledTime: null == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as DateTime,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as SlotState,loggedAt: freezed == loggedAt ? _self.loggedAt : loggedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,doseLogId: freezed == doseLogId ? _self.doseLogId : doseLogId // ignore: cast_nullable_to_non_nullable
as String?,previousStatus: freezed == previousStatus ? _self.previousStatus : previousStatus // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgendaSlot].
extension AgendaSlotPatterns on AgendaSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgendaSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgendaSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgendaSlot value)  $default,){
final _that = this;
switch (_that) {
case _AgendaSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgendaSlot value)?  $default,){
final _that = this;
switch (_that) {
case _AgendaSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slotId,  String medicationId,  String medicationName,  String dose,  String? notes,  DateTime scheduledTime,  SlotState state,  DateTime? loggedAt,  String? doseLogId,  String? previousStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgendaSlot() when $default != null:
return $default(_that.slotId,_that.medicationId,_that.medicationName,_that.dose,_that.notes,_that.scheduledTime,_that.state,_that.loggedAt,_that.doseLogId,_that.previousStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slotId,  String medicationId,  String medicationName,  String dose,  String? notes,  DateTime scheduledTime,  SlotState state,  DateTime? loggedAt,  String? doseLogId,  String? previousStatus)  $default,) {final _that = this;
switch (_that) {
case _AgendaSlot():
return $default(_that.slotId,_that.medicationId,_that.medicationName,_that.dose,_that.notes,_that.scheduledTime,_that.state,_that.loggedAt,_that.doseLogId,_that.previousStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slotId,  String medicationId,  String medicationName,  String dose,  String? notes,  DateTime scheduledTime,  SlotState state,  DateTime? loggedAt,  String? doseLogId,  String? previousStatus)?  $default,) {final _that = this;
switch (_that) {
case _AgendaSlot() when $default != null:
return $default(_that.slotId,_that.medicationId,_that.medicationName,_that.dose,_that.notes,_that.scheduledTime,_that.state,_that.loggedAt,_that.doseLogId,_that.previousStatus);case _:
  return null;

}
}

}

/// @nodoc


class _AgendaSlot implements AgendaSlot {
  const _AgendaSlot({required this.slotId, required this.medicationId, required this.medicationName, required this.dose, this.notes, required this.scheduledTime, required this.state, this.loggedAt, this.doseLogId, this.previousStatus});
  

@override final  String slotId;
@override final  String medicationId;
@override final  String medicationName;
@override final  String dose;
@override final  String? notes;
@override final  DateTime scheduledTime;
@override final  SlotState state;
@override final  DateTime? loggedAt;
@override final  String? doseLogId;
@override final  String? previousStatus;

/// Create a copy of AgendaSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgendaSlotCopyWith<_AgendaSlot> get copyWith => __$AgendaSlotCopyWithImpl<_AgendaSlot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgendaSlot&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId)&&(identical(other.medicationName, medicationName) || other.medicationName == medicationName)&&(identical(other.dose, dose) || other.dose == dose)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.state, state) || other.state == state)&&(identical(other.loggedAt, loggedAt) || other.loggedAt == loggedAt)&&(identical(other.doseLogId, doseLogId) || other.doseLogId == doseLogId)&&(identical(other.previousStatus, previousStatus) || other.previousStatus == previousStatus));
}


@override
int get hashCode => Object.hash(runtimeType,slotId,medicationId,medicationName,dose,notes,scheduledTime,state,loggedAt,doseLogId,previousStatus);

@override
String toString() {
  return 'AgendaSlot(slotId: $slotId, medicationId: $medicationId, medicationName: $medicationName, dose: $dose, notes: $notes, scheduledTime: $scheduledTime, state: $state, loggedAt: $loggedAt, doseLogId: $doseLogId, previousStatus: $previousStatus)';
}


}

/// @nodoc
abstract mixin class _$AgendaSlotCopyWith<$Res> implements $AgendaSlotCopyWith<$Res> {
  factory _$AgendaSlotCopyWith(_AgendaSlot value, $Res Function(_AgendaSlot) _then) = __$AgendaSlotCopyWithImpl;
@override @useResult
$Res call({
 String slotId, String medicationId, String medicationName, String dose, String? notes, DateTime scheduledTime, SlotState state, DateTime? loggedAt, String? doseLogId, String? previousStatus
});




}
/// @nodoc
class __$AgendaSlotCopyWithImpl<$Res>
    implements _$AgendaSlotCopyWith<$Res> {
  __$AgendaSlotCopyWithImpl(this._self, this._then);

  final _AgendaSlot _self;
  final $Res Function(_AgendaSlot) _then;

/// Create a copy of AgendaSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slotId = null,Object? medicationId = null,Object? medicationName = null,Object? dose = null,Object? notes = freezed,Object? scheduledTime = null,Object? state = null,Object? loggedAt = freezed,Object? doseLogId = freezed,Object? previousStatus = freezed,}) {
  return _then(_AgendaSlot(
slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,medicationId: null == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as String,medicationName: null == medicationName ? _self.medicationName : medicationName // ignore: cast_nullable_to_non_nullable
as String,dose: null == dose ? _self.dose : dose // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,scheduledTime: null == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as DateTime,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as SlotState,loggedAt: freezed == loggedAt ? _self.loggedAt : loggedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,doseLogId: freezed == doseLogId ? _self.doseLogId : doseLogId // ignore: cast_nullable_to_non_nullable
as String?,previousStatus: freezed == previousStatus ? _self.previousStatus : previousStatus // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PrnMedication {

 String get medicationId; String get medicationName; String get dose; String? get notes;
/// Create a copy of PrnMedication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrnMedicationCopyWith<PrnMedication> get copyWith => _$PrnMedicationCopyWithImpl<PrnMedication>(this as PrnMedication, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrnMedication&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId)&&(identical(other.medicationName, medicationName) || other.medicationName == medicationName)&&(identical(other.dose, dose) || other.dose == dose)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,medicationId,medicationName,dose,notes);

@override
String toString() {
  return 'PrnMedication(medicationId: $medicationId, medicationName: $medicationName, dose: $dose, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $PrnMedicationCopyWith<$Res>  {
  factory $PrnMedicationCopyWith(PrnMedication value, $Res Function(PrnMedication) _then) = _$PrnMedicationCopyWithImpl;
@useResult
$Res call({
 String medicationId, String medicationName, String dose, String? notes
});




}
/// @nodoc
class _$PrnMedicationCopyWithImpl<$Res>
    implements $PrnMedicationCopyWith<$Res> {
  _$PrnMedicationCopyWithImpl(this._self, this._then);

  final PrnMedication _self;
  final $Res Function(PrnMedication) _then;

/// Create a copy of PrnMedication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? medicationId = null,Object? medicationName = null,Object? dose = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
medicationId: null == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as String,medicationName: null == medicationName ? _self.medicationName : medicationName // ignore: cast_nullable_to_non_nullable
as String,dose: null == dose ? _self.dose : dose // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PrnMedication].
extension PrnMedicationPatterns on PrnMedication {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrnMedication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrnMedication() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrnMedication value)  $default,){
final _that = this;
switch (_that) {
case _PrnMedication():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrnMedication value)?  $default,){
final _that = this;
switch (_that) {
case _PrnMedication() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String medicationId,  String medicationName,  String dose,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrnMedication() when $default != null:
return $default(_that.medicationId,_that.medicationName,_that.dose,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String medicationId,  String medicationName,  String dose,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _PrnMedication():
return $default(_that.medicationId,_that.medicationName,_that.dose,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String medicationId,  String medicationName,  String dose,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _PrnMedication() when $default != null:
return $default(_that.medicationId,_that.medicationName,_that.dose,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _PrnMedication implements PrnMedication {
  const _PrnMedication({required this.medicationId, required this.medicationName, required this.dose, this.notes});
  

@override final  String medicationId;
@override final  String medicationName;
@override final  String dose;
@override final  String? notes;

/// Create a copy of PrnMedication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrnMedicationCopyWith<_PrnMedication> get copyWith => __$PrnMedicationCopyWithImpl<_PrnMedication>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrnMedication&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId)&&(identical(other.medicationName, medicationName) || other.medicationName == medicationName)&&(identical(other.dose, dose) || other.dose == dose)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,medicationId,medicationName,dose,notes);

@override
String toString() {
  return 'PrnMedication(medicationId: $medicationId, medicationName: $medicationName, dose: $dose, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$PrnMedicationCopyWith<$Res> implements $PrnMedicationCopyWith<$Res> {
  factory _$PrnMedicationCopyWith(_PrnMedication value, $Res Function(_PrnMedication) _then) = __$PrnMedicationCopyWithImpl;
@override @useResult
$Res call({
 String medicationId, String medicationName, String dose, String? notes
});




}
/// @nodoc
class __$PrnMedicationCopyWithImpl<$Res>
    implements _$PrnMedicationCopyWith<$Res> {
  __$PrnMedicationCopyWithImpl(this._self, this._then);

  final _PrnMedication _self;
  final $Res Function(_PrnMedication) _then;

/// Create a copy of PrnMedication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? medicationId = null,Object? medicationName = null,Object? dose = null,Object? notes = freezed,}) {
  return _then(_PrnMedication(
medicationId: null == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as String,medicationName: null == medicationName ? _self.medicationName : medicationName // ignore: cast_nullable_to_non_nullable
as String,dose: null == dose ? _self.dose : dose // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$OfflineQueueEntry {

 String get idempotencyKey; OfflineQueueKind get kind; DoseLogStatus get status; DateTime get enqueuedAt; String? get slotId; String? get doseLogId; String? get medicationId;
/// Create a copy of OfflineQueueEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineQueueEntryCopyWith<OfflineQueueEntry> get copyWith => _$OfflineQueueEntryCopyWithImpl<OfflineQueueEntry>(this as OfflineQueueEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineQueueEntry&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.enqueuedAt, enqueuedAt) || other.enqueuedAt == enqueuedAt)&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.doseLogId, doseLogId) || other.doseLogId == doseLogId)&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId));
}


@override
int get hashCode => Object.hash(runtimeType,idempotencyKey,kind,status,enqueuedAt,slotId,doseLogId,medicationId);

@override
String toString() {
  return 'OfflineQueueEntry(idempotencyKey: $idempotencyKey, kind: $kind, status: $status, enqueuedAt: $enqueuedAt, slotId: $slotId, doseLogId: $doseLogId, medicationId: $medicationId)';
}


}

/// @nodoc
abstract mixin class $OfflineQueueEntryCopyWith<$Res>  {
  factory $OfflineQueueEntryCopyWith(OfflineQueueEntry value, $Res Function(OfflineQueueEntry) _then) = _$OfflineQueueEntryCopyWithImpl;
@useResult
$Res call({
 String idempotencyKey, OfflineQueueKind kind, DoseLogStatus status, DateTime enqueuedAt, String? slotId, String? doseLogId, String? medicationId
});




}
/// @nodoc
class _$OfflineQueueEntryCopyWithImpl<$Res>
    implements $OfflineQueueEntryCopyWith<$Res> {
  _$OfflineQueueEntryCopyWithImpl(this._self, this._then);

  final OfflineQueueEntry _self;
  final $Res Function(OfflineQueueEntry) _then;

/// Create a copy of OfflineQueueEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idempotencyKey = null,Object? kind = null,Object? status = null,Object? enqueuedAt = null,Object? slotId = freezed,Object? doseLogId = freezed,Object? medicationId = freezed,}) {
  return _then(_self.copyWith(
idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OfflineQueueKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DoseLogStatus,enqueuedAt: null == enqueuedAt ? _self.enqueuedAt : enqueuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,slotId: freezed == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String?,doseLogId: freezed == doseLogId ? _self.doseLogId : doseLogId // ignore: cast_nullable_to_non_nullable
as String?,medicationId: freezed == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OfflineQueueEntry].
extension OfflineQueueEntryPatterns on OfflineQueueEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OfflineQueueEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OfflineQueueEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OfflineQueueEntry value)  $default,){
final _that = this;
switch (_that) {
case _OfflineQueueEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OfflineQueueEntry value)?  $default,){
final _that = this;
switch (_that) {
case _OfflineQueueEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String idempotencyKey,  OfflineQueueKind kind,  DoseLogStatus status,  DateTime enqueuedAt,  String? slotId,  String? doseLogId,  String? medicationId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OfflineQueueEntry() when $default != null:
return $default(_that.idempotencyKey,_that.kind,_that.status,_that.enqueuedAt,_that.slotId,_that.doseLogId,_that.medicationId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String idempotencyKey,  OfflineQueueKind kind,  DoseLogStatus status,  DateTime enqueuedAt,  String? slotId,  String? doseLogId,  String? medicationId)  $default,) {final _that = this;
switch (_that) {
case _OfflineQueueEntry():
return $default(_that.idempotencyKey,_that.kind,_that.status,_that.enqueuedAt,_that.slotId,_that.doseLogId,_that.medicationId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String idempotencyKey,  OfflineQueueKind kind,  DoseLogStatus status,  DateTime enqueuedAt,  String? slotId,  String? doseLogId,  String? medicationId)?  $default,) {final _that = this;
switch (_that) {
case _OfflineQueueEntry() when $default != null:
return $default(_that.idempotencyKey,_that.kind,_that.status,_that.enqueuedAt,_that.slotId,_that.doseLogId,_that.medicationId);case _:
  return null;

}
}

}

/// @nodoc


class _OfflineQueueEntry implements OfflineQueueEntry {
  const _OfflineQueueEntry({required this.idempotencyKey, required this.kind, required this.status, required this.enqueuedAt, this.slotId, this.doseLogId, this.medicationId});
  

@override final  String idempotencyKey;
@override final  OfflineQueueKind kind;
@override final  DoseLogStatus status;
@override final  DateTime enqueuedAt;
@override final  String? slotId;
@override final  String? doseLogId;
@override final  String? medicationId;

/// Create a copy of OfflineQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfflineQueueEntryCopyWith<_OfflineQueueEntry> get copyWith => __$OfflineQueueEntryCopyWithImpl<_OfflineQueueEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfflineQueueEntry&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.enqueuedAt, enqueuedAt) || other.enqueuedAt == enqueuedAt)&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.doseLogId, doseLogId) || other.doseLogId == doseLogId)&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId));
}


@override
int get hashCode => Object.hash(runtimeType,idempotencyKey,kind,status,enqueuedAt,slotId,doseLogId,medicationId);

@override
String toString() {
  return 'OfflineQueueEntry(idempotencyKey: $idempotencyKey, kind: $kind, status: $status, enqueuedAt: $enqueuedAt, slotId: $slotId, doseLogId: $doseLogId, medicationId: $medicationId)';
}


}

/// @nodoc
abstract mixin class _$OfflineQueueEntryCopyWith<$Res> implements $OfflineQueueEntryCopyWith<$Res> {
  factory _$OfflineQueueEntryCopyWith(_OfflineQueueEntry value, $Res Function(_OfflineQueueEntry) _then) = __$OfflineQueueEntryCopyWithImpl;
@override @useResult
$Res call({
 String idempotencyKey, OfflineQueueKind kind, DoseLogStatus status, DateTime enqueuedAt, String? slotId, String? doseLogId, String? medicationId
});




}
/// @nodoc
class __$OfflineQueueEntryCopyWithImpl<$Res>
    implements _$OfflineQueueEntryCopyWith<$Res> {
  __$OfflineQueueEntryCopyWithImpl(this._self, this._then);

  final _OfflineQueueEntry _self;
  final $Res Function(_OfflineQueueEntry) _then;

/// Create a copy of OfflineQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idempotencyKey = null,Object? kind = null,Object? status = null,Object? enqueuedAt = null,Object? slotId = freezed,Object? doseLogId = freezed,Object? medicationId = freezed,}) {
  return _then(_OfflineQueueEntry(
idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OfflineQueueKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DoseLogStatus,enqueuedAt: null == enqueuedAt ? _self.enqueuedAt : enqueuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,slotId: freezed == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String?,doseLogId: freezed == doseLogId ? _self.doseLogId : doseLogId // ignore: cast_nullable_to_non_nullable
as String?,medicationId: freezed == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AgendaState {

 List<AgendaSlot> get slots; List<PrnMedication> get prn; AgendaSourceState get sourceState; DateTime? get lastSyncedAt; List<OfflineQueueEntry> get offlineQueue; Set<String> get writeInFlightSlotIds; Set<String> get writeInFlightPrnIds; String? get c8PromptSlotId; String? get rollbackErrorSlotId; bool get planUpdated; bool get timezoneAdjusted; bool get remindersOff;
/// Create a copy of AgendaState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgendaStateCopyWith<AgendaState> get copyWith => _$AgendaStateCopyWithImpl<AgendaState>(this as AgendaState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgendaState&&const DeepCollectionEquality().equals(other.slots, slots)&&const DeepCollectionEquality().equals(other.prn, prn)&&(identical(other.sourceState, sourceState) || other.sourceState == sourceState)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&const DeepCollectionEquality().equals(other.offlineQueue, offlineQueue)&&const DeepCollectionEquality().equals(other.writeInFlightSlotIds, writeInFlightSlotIds)&&const DeepCollectionEquality().equals(other.writeInFlightPrnIds, writeInFlightPrnIds)&&(identical(other.c8PromptSlotId, c8PromptSlotId) || other.c8PromptSlotId == c8PromptSlotId)&&(identical(other.rollbackErrorSlotId, rollbackErrorSlotId) || other.rollbackErrorSlotId == rollbackErrorSlotId)&&(identical(other.planUpdated, planUpdated) || other.planUpdated == planUpdated)&&(identical(other.timezoneAdjusted, timezoneAdjusted) || other.timezoneAdjusted == timezoneAdjusted)&&(identical(other.remindersOff, remindersOff) || other.remindersOff == remindersOff));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(slots),const DeepCollectionEquality().hash(prn),sourceState,lastSyncedAt,const DeepCollectionEquality().hash(offlineQueue),const DeepCollectionEquality().hash(writeInFlightSlotIds),const DeepCollectionEquality().hash(writeInFlightPrnIds),c8PromptSlotId,rollbackErrorSlotId,planUpdated,timezoneAdjusted,remindersOff);

@override
String toString() {
  return 'AgendaState(slots: $slots, prn: $prn, sourceState: $sourceState, lastSyncedAt: $lastSyncedAt, offlineQueue: $offlineQueue, writeInFlightSlotIds: $writeInFlightSlotIds, writeInFlightPrnIds: $writeInFlightPrnIds, c8PromptSlotId: $c8PromptSlotId, rollbackErrorSlotId: $rollbackErrorSlotId, planUpdated: $planUpdated, timezoneAdjusted: $timezoneAdjusted, remindersOff: $remindersOff)';
}


}

/// @nodoc
abstract mixin class $AgendaStateCopyWith<$Res>  {
  factory $AgendaStateCopyWith(AgendaState value, $Res Function(AgendaState) _then) = _$AgendaStateCopyWithImpl;
@useResult
$Res call({
 List<AgendaSlot> slots, List<PrnMedication> prn, AgendaSourceState sourceState, DateTime? lastSyncedAt, List<OfflineQueueEntry> offlineQueue, Set<String> writeInFlightSlotIds, Set<String> writeInFlightPrnIds, String? c8PromptSlotId, String? rollbackErrorSlotId, bool planUpdated, bool timezoneAdjusted, bool remindersOff
});




}
/// @nodoc
class _$AgendaStateCopyWithImpl<$Res>
    implements $AgendaStateCopyWith<$Res> {
  _$AgendaStateCopyWithImpl(this._self, this._then);

  final AgendaState _self;
  final $Res Function(AgendaState) _then;

/// Create a copy of AgendaState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slots = null,Object? prn = null,Object? sourceState = null,Object? lastSyncedAt = freezed,Object? offlineQueue = null,Object? writeInFlightSlotIds = null,Object? writeInFlightPrnIds = null,Object? c8PromptSlotId = freezed,Object? rollbackErrorSlotId = freezed,Object? planUpdated = null,Object? timezoneAdjusted = null,Object? remindersOff = null,}) {
  return _then(_self.copyWith(
slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as List<AgendaSlot>,prn: null == prn ? _self.prn : prn // ignore: cast_nullable_to_non_nullable
as List<PrnMedication>,sourceState: null == sourceState ? _self.sourceState : sourceState // ignore: cast_nullable_to_non_nullable
as AgendaSourceState,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,offlineQueue: null == offlineQueue ? _self.offlineQueue : offlineQueue // ignore: cast_nullable_to_non_nullable
as List<OfflineQueueEntry>,writeInFlightSlotIds: null == writeInFlightSlotIds ? _self.writeInFlightSlotIds : writeInFlightSlotIds // ignore: cast_nullable_to_non_nullable
as Set<String>,writeInFlightPrnIds: null == writeInFlightPrnIds ? _self.writeInFlightPrnIds : writeInFlightPrnIds // ignore: cast_nullable_to_non_nullable
as Set<String>,c8PromptSlotId: freezed == c8PromptSlotId ? _self.c8PromptSlotId : c8PromptSlotId // ignore: cast_nullable_to_non_nullable
as String?,rollbackErrorSlotId: freezed == rollbackErrorSlotId ? _self.rollbackErrorSlotId : rollbackErrorSlotId // ignore: cast_nullable_to_non_nullable
as String?,planUpdated: null == planUpdated ? _self.planUpdated : planUpdated // ignore: cast_nullable_to_non_nullable
as bool,timezoneAdjusted: null == timezoneAdjusted ? _self.timezoneAdjusted : timezoneAdjusted // ignore: cast_nullable_to_non_nullable
as bool,remindersOff: null == remindersOff ? _self.remindersOff : remindersOff // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AgendaState].
extension AgendaStatePatterns on AgendaState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgendaState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgendaState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgendaState value)  $default,){
final _that = this;
switch (_that) {
case _AgendaState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgendaState value)?  $default,){
final _that = this;
switch (_that) {
case _AgendaState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AgendaSlot> slots,  List<PrnMedication> prn,  AgendaSourceState sourceState,  DateTime? lastSyncedAt,  List<OfflineQueueEntry> offlineQueue,  Set<String> writeInFlightSlotIds,  Set<String> writeInFlightPrnIds,  String? c8PromptSlotId,  String? rollbackErrorSlotId,  bool planUpdated,  bool timezoneAdjusted,  bool remindersOff)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgendaState() when $default != null:
return $default(_that.slots,_that.prn,_that.sourceState,_that.lastSyncedAt,_that.offlineQueue,_that.writeInFlightSlotIds,_that.writeInFlightPrnIds,_that.c8PromptSlotId,_that.rollbackErrorSlotId,_that.planUpdated,_that.timezoneAdjusted,_that.remindersOff);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AgendaSlot> slots,  List<PrnMedication> prn,  AgendaSourceState sourceState,  DateTime? lastSyncedAt,  List<OfflineQueueEntry> offlineQueue,  Set<String> writeInFlightSlotIds,  Set<String> writeInFlightPrnIds,  String? c8PromptSlotId,  String? rollbackErrorSlotId,  bool planUpdated,  bool timezoneAdjusted,  bool remindersOff)  $default,) {final _that = this;
switch (_that) {
case _AgendaState():
return $default(_that.slots,_that.prn,_that.sourceState,_that.lastSyncedAt,_that.offlineQueue,_that.writeInFlightSlotIds,_that.writeInFlightPrnIds,_that.c8PromptSlotId,_that.rollbackErrorSlotId,_that.planUpdated,_that.timezoneAdjusted,_that.remindersOff);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AgendaSlot> slots,  List<PrnMedication> prn,  AgendaSourceState sourceState,  DateTime? lastSyncedAt,  List<OfflineQueueEntry> offlineQueue,  Set<String> writeInFlightSlotIds,  Set<String> writeInFlightPrnIds,  String? c8PromptSlotId,  String? rollbackErrorSlotId,  bool planUpdated,  bool timezoneAdjusted,  bool remindersOff)?  $default,) {final _that = this;
switch (_that) {
case _AgendaState() when $default != null:
return $default(_that.slots,_that.prn,_that.sourceState,_that.lastSyncedAt,_that.offlineQueue,_that.writeInFlightSlotIds,_that.writeInFlightPrnIds,_that.c8PromptSlotId,_that.rollbackErrorSlotId,_that.planUpdated,_that.timezoneAdjusted,_that.remindersOff);case _:
  return null;

}
}

}

/// @nodoc


class _AgendaState implements AgendaState {
  const _AgendaState({final  List<AgendaSlot> slots = const [], final  List<PrnMedication> prn = const [], this.sourceState = AgendaSourceState.loading, this.lastSyncedAt, final  List<OfflineQueueEntry> offlineQueue = const [], final  Set<String> writeInFlightSlotIds = const {}, final  Set<String> writeInFlightPrnIds = const {}, this.c8PromptSlotId, this.rollbackErrorSlotId, this.planUpdated = false, this.timezoneAdjusted = false, this.remindersOff = false}): _slots = slots,_prn = prn,_offlineQueue = offlineQueue,_writeInFlightSlotIds = writeInFlightSlotIds,_writeInFlightPrnIds = writeInFlightPrnIds;
  

 final  List<AgendaSlot> _slots;
@override@JsonKey() List<AgendaSlot> get slots {
  if (_slots is EqualUnmodifiableListView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slots);
}

 final  List<PrnMedication> _prn;
@override@JsonKey() List<PrnMedication> get prn {
  if (_prn is EqualUnmodifiableListView) return _prn;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_prn);
}

@override@JsonKey() final  AgendaSourceState sourceState;
@override final  DateTime? lastSyncedAt;
 final  List<OfflineQueueEntry> _offlineQueue;
@override@JsonKey() List<OfflineQueueEntry> get offlineQueue {
  if (_offlineQueue is EqualUnmodifiableListView) return _offlineQueue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_offlineQueue);
}

 final  Set<String> _writeInFlightSlotIds;
@override@JsonKey() Set<String> get writeInFlightSlotIds {
  if (_writeInFlightSlotIds is EqualUnmodifiableSetView) return _writeInFlightSlotIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_writeInFlightSlotIds);
}

 final  Set<String> _writeInFlightPrnIds;
@override@JsonKey() Set<String> get writeInFlightPrnIds {
  if (_writeInFlightPrnIds is EqualUnmodifiableSetView) return _writeInFlightPrnIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_writeInFlightPrnIds);
}

@override final  String? c8PromptSlotId;
@override final  String? rollbackErrorSlotId;
@override@JsonKey() final  bool planUpdated;
@override@JsonKey() final  bool timezoneAdjusted;
@override@JsonKey() final  bool remindersOff;

/// Create a copy of AgendaState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgendaStateCopyWith<_AgendaState> get copyWith => __$AgendaStateCopyWithImpl<_AgendaState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgendaState&&const DeepCollectionEquality().equals(other._slots, _slots)&&const DeepCollectionEquality().equals(other._prn, _prn)&&(identical(other.sourceState, sourceState) || other.sourceState == sourceState)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&const DeepCollectionEquality().equals(other._offlineQueue, _offlineQueue)&&const DeepCollectionEquality().equals(other._writeInFlightSlotIds, _writeInFlightSlotIds)&&const DeepCollectionEquality().equals(other._writeInFlightPrnIds, _writeInFlightPrnIds)&&(identical(other.c8PromptSlotId, c8PromptSlotId) || other.c8PromptSlotId == c8PromptSlotId)&&(identical(other.rollbackErrorSlotId, rollbackErrorSlotId) || other.rollbackErrorSlotId == rollbackErrorSlotId)&&(identical(other.planUpdated, planUpdated) || other.planUpdated == planUpdated)&&(identical(other.timezoneAdjusted, timezoneAdjusted) || other.timezoneAdjusted == timezoneAdjusted)&&(identical(other.remindersOff, remindersOff) || other.remindersOff == remindersOff));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_slots),const DeepCollectionEquality().hash(_prn),sourceState,lastSyncedAt,const DeepCollectionEquality().hash(_offlineQueue),const DeepCollectionEquality().hash(_writeInFlightSlotIds),const DeepCollectionEquality().hash(_writeInFlightPrnIds),c8PromptSlotId,rollbackErrorSlotId,planUpdated,timezoneAdjusted,remindersOff);

@override
String toString() {
  return 'AgendaState(slots: $slots, prn: $prn, sourceState: $sourceState, lastSyncedAt: $lastSyncedAt, offlineQueue: $offlineQueue, writeInFlightSlotIds: $writeInFlightSlotIds, writeInFlightPrnIds: $writeInFlightPrnIds, c8PromptSlotId: $c8PromptSlotId, rollbackErrorSlotId: $rollbackErrorSlotId, planUpdated: $planUpdated, timezoneAdjusted: $timezoneAdjusted, remindersOff: $remindersOff)';
}


}

/// @nodoc
abstract mixin class _$AgendaStateCopyWith<$Res> implements $AgendaStateCopyWith<$Res> {
  factory _$AgendaStateCopyWith(_AgendaState value, $Res Function(_AgendaState) _then) = __$AgendaStateCopyWithImpl;
@override @useResult
$Res call({
 List<AgendaSlot> slots, List<PrnMedication> prn, AgendaSourceState sourceState, DateTime? lastSyncedAt, List<OfflineQueueEntry> offlineQueue, Set<String> writeInFlightSlotIds, Set<String> writeInFlightPrnIds, String? c8PromptSlotId, String? rollbackErrorSlotId, bool planUpdated, bool timezoneAdjusted, bool remindersOff
});




}
/// @nodoc
class __$AgendaStateCopyWithImpl<$Res>
    implements _$AgendaStateCopyWith<$Res> {
  __$AgendaStateCopyWithImpl(this._self, this._then);

  final _AgendaState _self;
  final $Res Function(_AgendaState) _then;

/// Create a copy of AgendaState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slots = null,Object? prn = null,Object? sourceState = null,Object? lastSyncedAt = freezed,Object? offlineQueue = null,Object? writeInFlightSlotIds = null,Object? writeInFlightPrnIds = null,Object? c8PromptSlotId = freezed,Object? rollbackErrorSlotId = freezed,Object? planUpdated = null,Object? timezoneAdjusted = null,Object? remindersOff = null,}) {
  return _then(_AgendaState(
slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as List<AgendaSlot>,prn: null == prn ? _self._prn : prn // ignore: cast_nullable_to_non_nullable
as List<PrnMedication>,sourceState: null == sourceState ? _self.sourceState : sourceState // ignore: cast_nullable_to_non_nullable
as AgendaSourceState,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,offlineQueue: null == offlineQueue ? _self._offlineQueue : offlineQueue // ignore: cast_nullable_to_non_nullable
as List<OfflineQueueEntry>,writeInFlightSlotIds: null == writeInFlightSlotIds ? _self._writeInFlightSlotIds : writeInFlightSlotIds // ignore: cast_nullable_to_non_nullable
as Set<String>,writeInFlightPrnIds: null == writeInFlightPrnIds ? _self._writeInFlightPrnIds : writeInFlightPrnIds // ignore: cast_nullable_to_non_nullable
as Set<String>,c8PromptSlotId: freezed == c8PromptSlotId ? _self.c8PromptSlotId : c8PromptSlotId // ignore: cast_nullable_to_non_nullable
as String?,rollbackErrorSlotId: freezed == rollbackErrorSlotId ? _self.rollbackErrorSlotId : rollbackErrorSlotId // ignore: cast_nullable_to_non_nullable
as String?,planUpdated: null == planUpdated ? _self.planUpdated : planUpdated // ignore: cast_nullable_to_non_nullable
as bool,timezoneAdjusted: null == timezoneAdjusted ? _self.timezoneAdjusted : timezoneAdjusted // ignore: cast_nullable_to_non_nullable
as bool,remindersOff: null == remindersOff ? _self.remindersOff : remindersOff // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
