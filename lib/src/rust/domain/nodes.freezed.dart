// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nodes.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NodeInput {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeInput&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'NodeInput(field0: $field0)';
}


}

/// @nodoc
class $NodeInputCopyWith<$Res>  {
$NodeInputCopyWith(NodeInput _, $Res Function(NodeInput) __);
}


/// Adds pattern-matching-related methods to [NodeInput].
extension NodeInputPatterns on NodeInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NodeInput_Info value)?  info,TResult Function( NodeInput_Task value)?  task,TResult Function( NodeInput_Inter value)?  inter,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NodeInput_Info() when info != null:
return info(_that);case NodeInput_Task() when task != null:
return task(_that);case NodeInput_Inter() when inter != null:
return inter(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NodeInput_Info value)  info,required TResult Function( NodeInput_Task value)  task,required TResult Function( NodeInput_Inter value)  inter,}){
final _that = this;
switch (_that) {
case NodeInput_Info():
return info(_that);case NodeInput_Task():
return task(_that);case NodeInput_Inter():
return inter(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NodeInput_Info value)?  info,TResult? Function( NodeInput_Task value)?  task,TResult? Function( NodeInput_Inter value)?  inter,}){
final _that = this;
switch (_that) {
case NodeInput_Info() when info != null:
return info(_that);case NodeInput_Task() when task != null:
return task(_that);case NodeInput_Inter() when inter != null:
return inter(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( INode field0)?  info,TResult Function( TaskNode field0)?  task,TResult Function( InterNode field0)?  inter,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NodeInput_Info() when info != null:
return info(_that.field0);case NodeInput_Task() when task != null:
return task(_that.field0);case NodeInput_Inter() when inter != null:
return inter(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( INode field0)  info,required TResult Function( TaskNode field0)  task,required TResult Function( InterNode field0)  inter,}) {final _that = this;
switch (_that) {
case NodeInput_Info():
return info(_that.field0);case NodeInput_Task():
return task(_that.field0);case NodeInput_Inter():
return inter(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( INode field0)?  info,TResult? Function( TaskNode field0)?  task,TResult? Function( InterNode field0)?  inter,}) {final _that = this;
switch (_that) {
case NodeInput_Info() when info != null:
return info(_that.field0);case NodeInput_Task() when task != null:
return task(_that.field0);case NodeInput_Inter() when inter != null:
return inter(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class NodeInput_Info extends NodeInput {
  const NodeInput_Info(this.field0): super._();
  

@override final  INode field0;

/// Create a copy of NodeInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeInput_InfoCopyWith<NodeInput_Info> get copyWith => _$NodeInput_InfoCopyWithImpl<NodeInput_Info>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeInput_Info&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodeInput.info(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodeInput_InfoCopyWith<$Res> implements $NodeInputCopyWith<$Res> {
  factory $NodeInput_InfoCopyWith(NodeInput_Info value, $Res Function(NodeInput_Info) _then) = _$NodeInput_InfoCopyWithImpl;
@useResult
$Res call({
 INode field0
});




}
/// @nodoc
class _$NodeInput_InfoCopyWithImpl<$Res>
    implements $NodeInput_InfoCopyWith<$Res> {
  _$NodeInput_InfoCopyWithImpl(this._self, this._then);

  final NodeInput_Info _self;
  final $Res Function(NodeInput_Info) _then;

/// Create a copy of NodeInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodeInput_Info(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as INode,
  ));
}


}

/// @nodoc


class NodeInput_Task extends NodeInput {
  const NodeInput_Task(this.field0): super._();
  

@override final  TaskNode field0;

/// Create a copy of NodeInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeInput_TaskCopyWith<NodeInput_Task> get copyWith => _$NodeInput_TaskCopyWithImpl<NodeInput_Task>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeInput_Task&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodeInput.task(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodeInput_TaskCopyWith<$Res> implements $NodeInputCopyWith<$Res> {
  factory $NodeInput_TaskCopyWith(NodeInput_Task value, $Res Function(NodeInput_Task) _then) = _$NodeInput_TaskCopyWithImpl;
@useResult
$Res call({
 TaskNode field0
});




}
/// @nodoc
class _$NodeInput_TaskCopyWithImpl<$Res>
    implements $NodeInput_TaskCopyWith<$Res> {
  _$NodeInput_TaskCopyWithImpl(this._self, this._then);

  final NodeInput_Task _self;
  final $Res Function(NodeInput_Task) _then;

/// Create a copy of NodeInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodeInput_Task(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as TaskNode,
  ));
}


}

/// @nodoc


class NodeInput_Inter extends NodeInput {
  const NodeInput_Inter(this.field0): super._();
  

@override final  InterNode field0;

/// Create a copy of NodeInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeInput_InterCopyWith<NodeInput_Inter> get copyWith => _$NodeInput_InterCopyWithImpl<NodeInput_Inter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeInput_Inter&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodeInput.inter(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodeInput_InterCopyWith<$Res> implements $NodeInputCopyWith<$Res> {
  factory $NodeInput_InterCopyWith(NodeInput_Inter value, $Res Function(NodeInput_Inter) _then) = _$NodeInput_InterCopyWithImpl;
@useResult
$Res call({
 InterNode field0
});




}
/// @nodoc
class _$NodeInput_InterCopyWithImpl<$Res>
    implements $NodeInput_InterCopyWith<$Res> {
  _$NodeInput_InterCopyWithImpl(this._self, this._then);

  final NodeInput_Inter _self;
  final $Res Function(NodeInput_Inter) _then;

/// Create a copy of NodeInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodeInput_Inter(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as InterNode,
  ));
}


}

/// @nodoc
mixin _$NodeOutput {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeOutput&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'NodeOutput(field0: $field0)';
}


}

/// @nodoc
class $NodeOutputCopyWith<$Res>  {
$NodeOutputCopyWith(NodeOutput _, $Res Function(NodeOutput) __);
}


/// Adds pattern-matching-related methods to [NodeOutput].
extension NodeOutputPatterns on NodeOutput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NodeOutput_Info value)?  info,TResult Function( NodeOutput_Task value)?  task,TResult Function( NodeOutput_Inter value)?  inter,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NodeOutput_Info() when info != null:
return info(_that);case NodeOutput_Task() when task != null:
return task(_that);case NodeOutput_Inter() when inter != null:
return inter(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NodeOutput_Info value)  info,required TResult Function( NodeOutput_Task value)  task,required TResult Function( NodeOutput_Inter value)  inter,}){
final _that = this;
switch (_that) {
case NodeOutput_Info():
return info(_that);case NodeOutput_Task():
return task(_that);case NodeOutput_Inter():
return inter(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NodeOutput_Info value)?  info,TResult? Function( NodeOutput_Task value)?  task,TResult? Function( NodeOutput_Inter value)?  inter,}){
final _that = this;
switch (_that) {
case NodeOutput_Info() when info != null:
return info(_that);case NodeOutput_Task() when task != null:
return task(_that);case NodeOutput_Inter() when inter != null:
return inter(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( INode field0)?  info,TResult Function( TaskNode field0)?  task,TResult Function( InterNode field0)?  inter,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NodeOutput_Info() when info != null:
return info(_that.field0);case NodeOutput_Task() when task != null:
return task(_that.field0);case NodeOutput_Inter() when inter != null:
return inter(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( INode field0)  info,required TResult Function( TaskNode field0)  task,required TResult Function( InterNode field0)  inter,}) {final _that = this;
switch (_that) {
case NodeOutput_Info():
return info(_that.field0);case NodeOutput_Task():
return task(_that.field0);case NodeOutput_Inter():
return inter(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( INode field0)?  info,TResult? Function( TaskNode field0)?  task,TResult? Function( InterNode field0)?  inter,}) {final _that = this;
switch (_that) {
case NodeOutput_Info() when info != null:
return info(_that.field0);case NodeOutput_Task() when task != null:
return task(_that.field0);case NodeOutput_Inter() when inter != null:
return inter(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class NodeOutput_Info extends NodeOutput {
  const NodeOutput_Info(this.field0): super._();
  

@override final  INode field0;

/// Create a copy of NodeOutput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeOutput_InfoCopyWith<NodeOutput_Info> get copyWith => _$NodeOutput_InfoCopyWithImpl<NodeOutput_Info>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeOutput_Info&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodeOutput.info(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodeOutput_InfoCopyWith<$Res> implements $NodeOutputCopyWith<$Res> {
  factory $NodeOutput_InfoCopyWith(NodeOutput_Info value, $Res Function(NodeOutput_Info) _then) = _$NodeOutput_InfoCopyWithImpl;
@useResult
$Res call({
 INode field0
});




}
/// @nodoc
class _$NodeOutput_InfoCopyWithImpl<$Res>
    implements $NodeOutput_InfoCopyWith<$Res> {
  _$NodeOutput_InfoCopyWithImpl(this._self, this._then);

  final NodeOutput_Info _self;
  final $Res Function(NodeOutput_Info) _then;

/// Create a copy of NodeOutput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodeOutput_Info(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as INode,
  ));
}


}

/// @nodoc


class NodeOutput_Task extends NodeOutput {
  const NodeOutput_Task(this.field0): super._();
  

@override final  TaskNode field0;

/// Create a copy of NodeOutput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeOutput_TaskCopyWith<NodeOutput_Task> get copyWith => _$NodeOutput_TaskCopyWithImpl<NodeOutput_Task>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeOutput_Task&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodeOutput.task(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodeOutput_TaskCopyWith<$Res> implements $NodeOutputCopyWith<$Res> {
  factory $NodeOutput_TaskCopyWith(NodeOutput_Task value, $Res Function(NodeOutput_Task) _then) = _$NodeOutput_TaskCopyWithImpl;
@useResult
$Res call({
 TaskNode field0
});




}
/// @nodoc
class _$NodeOutput_TaskCopyWithImpl<$Res>
    implements $NodeOutput_TaskCopyWith<$Res> {
  _$NodeOutput_TaskCopyWithImpl(this._self, this._then);

  final NodeOutput_Task _self;
  final $Res Function(NodeOutput_Task) _then;

/// Create a copy of NodeOutput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodeOutput_Task(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as TaskNode,
  ));
}


}

/// @nodoc


class NodeOutput_Inter extends NodeOutput {
  const NodeOutput_Inter(this.field0): super._();
  

@override final  InterNode field0;

/// Create a copy of NodeOutput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeOutput_InterCopyWith<NodeOutput_Inter> get copyWith => _$NodeOutput_InterCopyWithImpl<NodeOutput_Inter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeOutput_Inter&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodeOutput.inter(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodeOutput_InterCopyWith<$Res> implements $NodeOutputCopyWith<$Res> {
  factory $NodeOutput_InterCopyWith(NodeOutput_Inter value, $Res Function(NodeOutput_Inter) _then) = _$NodeOutput_InterCopyWithImpl;
@useResult
$Res call({
 InterNode field0
});




}
/// @nodoc
class _$NodeOutput_InterCopyWithImpl<$Res>
    implements $NodeOutput_InterCopyWith<$Res> {
  _$NodeOutput_InterCopyWithImpl(this._self, this._then);

  final NodeOutput_Inter _self;
  final $Res Function(NodeOutput_Inter) _then;

/// Create a copy of NodeOutput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodeOutput_Inter(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as InterNode,
  ));
}


}

// dart format on
