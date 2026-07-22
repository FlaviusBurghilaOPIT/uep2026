// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'today_agenda_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PendingDoseQueueItem {
  String get reminderId => throw _privateConstructorUsedError;
  DoseStatus get status => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PendingDoseQueueItemCopyWith<PendingDoseQueueItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PendingDoseQueueItemCopyWith<$Res> {
  factory $PendingDoseQueueItemCopyWith(PendingDoseQueueItem value,
          $Res Function(PendingDoseQueueItem) then) =
      _$PendingDoseQueueItemCopyWithImpl<$Res, PendingDoseQueueItem>;
  @useResult
  $Res call({String reminderId, DoseStatus status, DateTime timestamp});
}

/// @nodoc
class _$PendingDoseQueueItemCopyWithImpl<$Res,
        $Val extends PendingDoseQueueItem>
    implements $PendingDoseQueueItemCopyWith<$Res> {
  _$PendingDoseQueueItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reminderId = null,
    Object? status = null,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      reminderId: null == reminderId
          ? _value.reminderId
          : reminderId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as DoseStatus,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PendingDoseQueueItemImplCopyWith<$Res>
    implements $PendingDoseQueueItemCopyWith<$Res> {
  factory _$$PendingDoseQueueItemImplCopyWith(_$PendingDoseQueueItemImpl value,
          $Res Function(_$PendingDoseQueueItemImpl) then) =
      __$$PendingDoseQueueItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String reminderId, DoseStatus status, DateTime timestamp});
}

/// @nodoc
class __$$PendingDoseQueueItemImplCopyWithImpl<$Res>
    extends _$PendingDoseQueueItemCopyWithImpl<$Res, _$PendingDoseQueueItemImpl>
    implements _$$PendingDoseQueueItemImplCopyWith<$Res> {
  __$$PendingDoseQueueItemImplCopyWithImpl(_$PendingDoseQueueItemImpl _value,
      $Res Function(_$PendingDoseQueueItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reminderId = null,
    Object? status = null,
    Object? timestamp = null,
  }) {
    return _then(_$PendingDoseQueueItemImpl(
      reminderId: null == reminderId
          ? _value.reminderId
          : reminderId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as DoseStatus,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$PendingDoseQueueItemImpl implements _PendingDoseQueueItem {
  const _$PendingDoseQueueItemImpl(
      {required this.reminderId,
      required this.status,
      required this.timestamp});

  @override
  final String reminderId;
  @override
  final DoseStatus status;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'PendingDoseQueueItem(reminderId: $reminderId, status: $status, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PendingDoseQueueItemImpl &&
            (identical(other.reminderId, reminderId) ||
                other.reminderId == reminderId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reminderId, status, timestamp);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PendingDoseQueueItemImplCopyWith<_$PendingDoseQueueItemImpl>
      get copyWith =>
          __$$PendingDoseQueueItemImplCopyWithImpl<_$PendingDoseQueueItemImpl>(
              this, _$identity);
}

abstract class _PendingDoseQueueItem implements PendingDoseQueueItem {
  const factory _PendingDoseQueueItem(
      {required final String reminderId,
      required final DoseStatus status,
      required final DateTime timestamp}) = _$PendingDoseQueueItemImpl;

  @override
  String get reminderId;
  @override
  DoseStatus get status;
  @override
  DateTime get timestamp;
  @override
  @JsonKey(ignore: true)
  _$$PendingDoseQueueItemImplCopyWith<_$PendingDoseQueueItemImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MedicationItem {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get dose => throw _privateConstructorUsedError;
  String get scheduleText => throw _privateConstructorUsedError;
  String get duration => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MedicationItemCopyWith<MedicationItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MedicationItemCopyWith<$Res> {
  factory $MedicationItemCopyWith(
          MedicationItem value, $Res Function(MedicationItem) then) =
      _$MedicationItemCopyWithImpl<$Res, MedicationItem>;
  @useResult
  $Res call(
      {String id,
      String name,
      String dose,
      String scheduleText,
      String duration,
      String? notes});
}

/// @nodoc
class _$MedicationItemCopyWithImpl<$Res, $Val extends MedicationItem>
    implements $MedicationItemCopyWith<$Res> {
  _$MedicationItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? dose = null,
    Object? scheduleText = null,
    Object? duration = null,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      dose: null == dose
          ? _value.dose
          : dose // ignore: cast_nullable_to_non_nullable
              as String,
      scheduleText: null == scheduleText
          ? _value.scheduleText
          : scheduleText // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MedicationItemImplCopyWith<$Res>
    implements $MedicationItemCopyWith<$Res> {
  factory _$$MedicationItemImplCopyWith(_$MedicationItemImpl value,
          $Res Function(_$MedicationItemImpl) then) =
      __$$MedicationItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String dose,
      String scheduleText,
      String duration,
      String? notes});
}

/// @nodoc
class __$$MedicationItemImplCopyWithImpl<$Res>
    extends _$MedicationItemCopyWithImpl<$Res, _$MedicationItemImpl>
    implements _$$MedicationItemImplCopyWith<$Res> {
  __$$MedicationItemImplCopyWithImpl(
      _$MedicationItemImpl _value, $Res Function(_$MedicationItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? dose = null,
    Object? scheduleText = null,
    Object? duration = null,
    Object? notes = freezed,
  }) {
    return _then(_$MedicationItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      dose: null == dose
          ? _value.dose
          : dose // ignore: cast_nullable_to_non_nullable
              as String,
      scheduleText: null == scheduleText
          ? _value.scheduleText
          : scheduleText // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MedicationItemImpl implements _MedicationItem {
  const _$MedicationItemImpl(
      {required this.id,
      required this.name,
      required this.dose,
      required this.scheduleText,
      required this.duration,
      this.notes});

  @override
  final String id;
  @override
  final String name;
  @override
  final String dose;
  @override
  final String scheduleText;
  @override
  final String duration;
  @override
  final String? notes;

  @override
  String toString() {
    return 'MedicationItem(id: $id, name: $name, dose: $dose, scheduleText: $scheduleText, duration: $duration, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MedicationItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.dose, dose) || other.dose == dose) &&
            (identical(other.scheduleText, scheduleText) ||
                other.scheduleText == scheduleText) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, dose, scheduleText, duration, notes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MedicationItemImplCopyWith<_$MedicationItemImpl> get copyWith =>
      __$$MedicationItemImplCopyWithImpl<_$MedicationItemImpl>(
          this, _$identity);
}

abstract class _MedicationItem implements MedicationItem {
  const factory _MedicationItem(
      {required final String id,
      required final String name,
      required final String dose,
      required final String scheduleText,
      required final String duration,
      final String? notes}) = _$MedicationItemImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get dose;
  @override
  String get scheduleText;
  @override
  String get duration;
  @override
  String? get notes;
  @override
  @JsonKey(ignore: true)
  _$$MedicationItemImplCopyWith<_$MedicationItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AgendaState {
  AsyncValue<List<MedicationItem>> get medications =>
      throw _privateConstructorUsedError;
  Map<String, DoseStatus> get doseStatuses =>
      throw _privateConstructorUsedError;
  List<PendingDoseQueueItem> get offlineQueue =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AgendaStateCopyWith<AgendaState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgendaStateCopyWith<$Res> {
  factory $AgendaStateCopyWith(
          AgendaState value, $Res Function(AgendaState) then) =
      _$AgendaStateCopyWithImpl<$Res, AgendaState>;
  @useResult
  $Res call(
      {AsyncValue<List<MedicationItem>> medications,
      Map<String, DoseStatus> doseStatuses,
      List<PendingDoseQueueItem> offlineQueue});
}

/// @nodoc
class _$AgendaStateCopyWithImpl<$Res, $Val extends AgendaState>
    implements $AgendaStateCopyWith<$Res> {
  _$AgendaStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? medications = null,
    Object? doseStatuses = null,
    Object? offlineQueue = null,
  }) {
    return _then(_value.copyWith(
      medications: null == medications
          ? _value.medications
          : medications // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<MedicationItem>>,
      doseStatuses: null == doseStatuses
          ? _value.doseStatuses
          : doseStatuses // ignore: cast_nullable_to_non_nullable
              as Map<String, DoseStatus>,
      offlineQueue: null == offlineQueue
          ? _value.offlineQueue
          : offlineQueue // ignore: cast_nullable_to_non_nullable
              as List<PendingDoseQueueItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AgendaStateImplCopyWith<$Res>
    implements $AgendaStateCopyWith<$Res> {
  factory _$$AgendaStateImplCopyWith(
          _$AgendaStateImpl value, $Res Function(_$AgendaStateImpl) then) =
      __$$AgendaStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AsyncValue<List<MedicationItem>> medications,
      Map<String, DoseStatus> doseStatuses,
      List<PendingDoseQueueItem> offlineQueue});
}

/// @nodoc
class __$$AgendaStateImplCopyWithImpl<$Res>
    extends _$AgendaStateCopyWithImpl<$Res, _$AgendaStateImpl>
    implements _$$AgendaStateImplCopyWith<$Res> {
  __$$AgendaStateImplCopyWithImpl(
      _$AgendaStateImpl _value, $Res Function(_$AgendaStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? medications = null,
    Object? doseStatuses = null,
    Object? offlineQueue = null,
  }) {
    return _then(_$AgendaStateImpl(
      medications: null == medications
          ? _value.medications
          : medications // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<MedicationItem>>,
      doseStatuses: null == doseStatuses
          ? _value._doseStatuses
          : doseStatuses // ignore: cast_nullable_to_non_nullable
              as Map<String, DoseStatus>,
      offlineQueue: null == offlineQueue
          ? _value._offlineQueue
          : offlineQueue // ignore: cast_nullable_to_non_nullable
              as List<PendingDoseQueueItem>,
    ));
  }
}

/// @nodoc

class _$AgendaStateImpl implements _AgendaState {
  const _$AgendaStateImpl(
      {required this.medications,
      required final Map<String, DoseStatus> doseStatuses,
      final List<PendingDoseQueueItem> offlineQueue = const []})
      : _doseStatuses = doseStatuses,
        _offlineQueue = offlineQueue;

  @override
  final AsyncValue<List<MedicationItem>> medications;
  final Map<String, DoseStatus> _doseStatuses;
  @override
  Map<String, DoseStatus> get doseStatuses {
    if (_doseStatuses is EqualUnmodifiableMapView) return _doseStatuses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_doseStatuses);
  }

  final List<PendingDoseQueueItem> _offlineQueue;
  @override
  @JsonKey()
  List<PendingDoseQueueItem> get offlineQueue {
    if (_offlineQueue is EqualUnmodifiableListView) return _offlineQueue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_offlineQueue);
  }

  @override
  String toString() {
    return 'AgendaState(medications: $medications, doseStatuses: $doseStatuses, offlineQueue: $offlineQueue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgendaStateImpl &&
            (identical(other.medications, medications) ||
                other.medications == medications) &&
            const DeepCollectionEquality()
                .equals(other._doseStatuses, _doseStatuses) &&
            const DeepCollectionEquality()
                .equals(other._offlineQueue, _offlineQueue));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      medications,
      const DeepCollectionEquality().hash(_doseStatuses),
      const DeepCollectionEquality().hash(_offlineQueue));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AgendaStateImplCopyWith<_$AgendaStateImpl> get copyWith =>
      __$$AgendaStateImplCopyWithImpl<_$AgendaStateImpl>(this, _$identity);
}

abstract class _AgendaState implements AgendaState {
  const factory _AgendaState(
      {required final AsyncValue<List<MedicationItem>> medications,
      required final Map<String, DoseStatus> doseStatuses,
      final List<PendingDoseQueueItem> offlineQueue}) = _$AgendaStateImpl;

  @override
  AsyncValue<List<MedicationItem>> get medications;
  @override
  Map<String, DoseStatus> get doseStatuses;
  @override
  List<PendingDoseQueueItem> get offlineQueue;
  @override
  @JsonKey(ignore: true)
  _$$AgendaStateImplCopyWith<_$AgendaStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
