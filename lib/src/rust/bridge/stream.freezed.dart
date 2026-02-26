// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GraphEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GraphEvent()';
}


}

/// @nodoc
class $GraphEventCopyWith<$Res>  {
$GraphEventCopyWith(GraphEvent _, $Res Function(GraphEvent) __);
}


/// Adds pattern-matching-related methods to [GraphEvent].
extension GraphEventPatterns on GraphEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GraphEvent_NodeUpdated value)?  nodeUpdated,TResult Function( GraphEvent_NodeDeleted value)?  nodeDeleted,TResult Function( GraphEvent_RelationUpdated value)?  relationUpdated,TResult Function( GraphEvent_SnapshotLoaded value)?  snapshotLoaded,TResult Function( GraphEvent_BoundaryUpdated value)?  boundaryUpdated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated() when nodeUpdated != null:
return nodeUpdated(_that);case GraphEvent_NodeDeleted() when nodeDeleted != null:
return nodeDeleted(_that);case GraphEvent_RelationUpdated() when relationUpdated != null:
return relationUpdated(_that);case GraphEvent_SnapshotLoaded() when snapshotLoaded != null:
return snapshotLoaded(_that);case GraphEvent_BoundaryUpdated() when boundaryUpdated != null:
return boundaryUpdated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GraphEvent_NodeUpdated value)  nodeUpdated,required TResult Function( GraphEvent_NodeDeleted value)  nodeDeleted,required TResult Function( GraphEvent_RelationUpdated value)  relationUpdated,required TResult Function( GraphEvent_SnapshotLoaded value)  snapshotLoaded,required TResult Function( GraphEvent_BoundaryUpdated value)  boundaryUpdated,}){
final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated():
return nodeUpdated(_that);case GraphEvent_NodeDeleted():
return nodeDeleted(_that);case GraphEvent_RelationUpdated():
return relationUpdated(_that);case GraphEvent_SnapshotLoaded():
return snapshotLoaded(_that);case GraphEvent_BoundaryUpdated():
return boundaryUpdated(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GraphEvent_NodeUpdated value)?  nodeUpdated,TResult? Function( GraphEvent_NodeDeleted value)?  nodeDeleted,TResult? Function( GraphEvent_RelationUpdated value)?  relationUpdated,TResult? Function( GraphEvent_SnapshotLoaded value)?  snapshotLoaded,TResult? Function( GraphEvent_BoundaryUpdated value)?  boundaryUpdated,}){
final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated() when nodeUpdated != null:
return nodeUpdated(_that);case GraphEvent_NodeDeleted() when nodeDeleted != null:
return nodeDeleted(_that);case GraphEvent_RelationUpdated() when relationUpdated != null:
return relationUpdated(_that);case GraphEvent_SnapshotLoaded() when snapshotLoaded != null:
return snapshotLoaded(_that);case GraphEvent_BoundaryUpdated() when boundaryUpdated != null:
return boundaryUpdated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( NodeOutput field0)?  nodeUpdated,TResult Function( String field0)?  nodeDeleted,TResult Function()?  relationUpdated,TResult Function()?  snapshotLoaded,TResult Function( BoundingBox field0)?  boundaryUpdated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated() when nodeUpdated != null:
return nodeUpdated(_that.field0);case GraphEvent_NodeDeleted() when nodeDeleted != null:
return nodeDeleted(_that.field0);case GraphEvent_RelationUpdated() when relationUpdated != null:
return relationUpdated();case GraphEvent_SnapshotLoaded() when snapshotLoaded != null:
return snapshotLoaded();case GraphEvent_BoundaryUpdated() when boundaryUpdated != null:
return boundaryUpdated(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( NodeOutput field0)  nodeUpdated,required TResult Function( String field0)  nodeDeleted,required TResult Function()  relationUpdated,required TResult Function()  snapshotLoaded,required TResult Function( BoundingBox field0)  boundaryUpdated,}) {final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated():
return nodeUpdated(_that.field0);case GraphEvent_NodeDeleted():
return nodeDeleted(_that.field0);case GraphEvent_RelationUpdated():
return relationUpdated();case GraphEvent_SnapshotLoaded():
return snapshotLoaded();case GraphEvent_BoundaryUpdated():
return boundaryUpdated(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( NodeOutput field0)?  nodeUpdated,TResult? Function( String field0)?  nodeDeleted,TResult? Function()?  relationUpdated,TResult? Function()?  snapshotLoaded,TResult? Function( BoundingBox field0)?  boundaryUpdated,}) {final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated() when nodeUpdated != null:
return nodeUpdated(_that.field0);case GraphEvent_NodeDeleted() when nodeDeleted != null:
return nodeDeleted(_that.field0);case GraphEvent_RelationUpdated() when relationUpdated != null:
return relationUpdated();case GraphEvent_SnapshotLoaded() when snapshotLoaded != null:
return snapshotLoaded();case GraphEvent_BoundaryUpdated() when boundaryUpdated != null:
return boundaryUpdated(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class GraphEvent_NodeUpdated extends GraphEvent {
  const GraphEvent_NodeUpdated(this.field0): super._();
  

 final  NodeOutput field0;

/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphEvent_NodeUpdatedCopyWith<GraphEvent_NodeUpdated> get copyWith => _$GraphEvent_NodeUpdatedCopyWithImpl<GraphEvent_NodeUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphEvent_NodeUpdated&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'GraphEvent.nodeUpdated(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $GraphEvent_NodeUpdatedCopyWith<$Res> implements $GraphEventCopyWith<$Res> {
  factory $GraphEvent_NodeUpdatedCopyWith(GraphEvent_NodeUpdated value, $Res Function(GraphEvent_NodeUpdated) _then) = _$GraphEvent_NodeUpdatedCopyWithImpl;
@useResult
$Res call({
 NodeOutput field0
});


$NodeOutputCopyWith<$Res> get field0;

}
/// @nodoc
class _$GraphEvent_NodeUpdatedCopyWithImpl<$Res>
    implements $GraphEvent_NodeUpdatedCopyWith<$Res> {
  _$GraphEvent_NodeUpdatedCopyWithImpl(this._self, this._then);

  final GraphEvent_NodeUpdated _self;
  final $Res Function(GraphEvent_NodeUpdated) _then;

/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(GraphEvent_NodeUpdated(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as NodeOutput,
  ));
}

/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NodeOutputCopyWith<$Res> get field0 {
  
  return $NodeOutputCopyWith<$Res>(_self.field0, (value) {
    return _then(_self.copyWith(field0: value));
  });
}
}

/// @nodoc


class GraphEvent_NodeDeleted extends GraphEvent {
  const GraphEvent_NodeDeleted(this.field0): super._();
  

 final  String field0;

/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphEvent_NodeDeletedCopyWith<GraphEvent_NodeDeleted> get copyWith => _$GraphEvent_NodeDeletedCopyWithImpl<GraphEvent_NodeDeleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphEvent_NodeDeleted&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'GraphEvent.nodeDeleted(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $GraphEvent_NodeDeletedCopyWith<$Res> implements $GraphEventCopyWith<$Res> {
  factory $GraphEvent_NodeDeletedCopyWith(GraphEvent_NodeDeleted value, $Res Function(GraphEvent_NodeDeleted) _then) = _$GraphEvent_NodeDeletedCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$GraphEvent_NodeDeletedCopyWithImpl<$Res>
    implements $GraphEvent_NodeDeletedCopyWith<$Res> {
  _$GraphEvent_NodeDeletedCopyWithImpl(this._self, this._then);

  final GraphEvent_NodeDeleted _self;
  final $Res Function(GraphEvent_NodeDeleted) _then;

/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(GraphEvent_NodeDeleted(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class GraphEvent_RelationUpdated extends GraphEvent {
  const GraphEvent_RelationUpdated(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphEvent_RelationUpdated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GraphEvent.relationUpdated()';
}


}




/// @nodoc


class GraphEvent_SnapshotLoaded extends GraphEvent {
  const GraphEvent_SnapshotLoaded(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphEvent_SnapshotLoaded);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GraphEvent.snapshotLoaded()';
}


}




/// @nodoc


class GraphEvent_BoundaryUpdated extends GraphEvent {
  const GraphEvent_BoundaryUpdated(this.field0): super._();
  

 final  BoundingBox field0;

/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphEvent_BoundaryUpdatedCopyWith<GraphEvent_BoundaryUpdated> get copyWith => _$GraphEvent_BoundaryUpdatedCopyWithImpl<GraphEvent_BoundaryUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphEvent_BoundaryUpdated&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'GraphEvent.boundaryUpdated(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $GraphEvent_BoundaryUpdatedCopyWith<$Res> implements $GraphEventCopyWith<$Res> {
  factory $GraphEvent_BoundaryUpdatedCopyWith(GraphEvent_BoundaryUpdated value, $Res Function(GraphEvent_BoundaryUpdated) _then) = _$GraphEvent_BoundaryUpdatedCopyWithImpl;
@useResult
$Res call({
 BoundingBox field0
});




}
/// @nodoc
class _$GraphEvent_BoundaryUpdatedCopyWithImpl<$Res>
    implements $GraphEvent_BoundaryUpdatedCopyWith<$Res> {
  _$GraphEvent_BoundaryUpdatedCopyWithImpl(this._self, this._then);

  final GraphEvent_BoundaryUpdated _self;
  final $Res Function(GraphEvent_BoundaryUpdated) _then;

/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(GraphEvent_BoundaryUpdated(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as BoundingBox,
  ));
}


}

// dart format on
