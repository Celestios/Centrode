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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GraphEvent_NodeUpdated value)?  nodeUpdated,TResult Function( GraphEvent_RelationUpdated value)?  relationUpdated,TResult Function( GraphEvent_BatchUpdated value)?  batchUpdated,TResult Function( GraphEvent_BoundaryUpdated value)?  boundaryUpdated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated() when nodeUpdated != null:
return nodeUpdated(_that);case GraphEvent_RelationUpdated() when relationUpdated != null:
return relationUpdated(_that);case GraphEvent_BatchUpdated() when batchUpdated != null:
return batchUpdated(_that);case GraphEvent_BoundaryUpdated() when boundaryUpdated != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GraphEvent_NodeUpdated value)  nodeUpdated,required TResult Function( GraphEvent_RelationUpdated value)  relationUpdated,required TResult Function( GraphEvent_BatchUpdated value)  batchUpdated,required TResult Function( GraphEvent_BoundaryUpdated value)  boundaryUpdated,}){
final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated():
return nodeUpdated(_that);case GraphEvent_RelationUpdated():
return relationUpdated(_that);case GraphEvent_BatchUpdated():
return batchUpdated(_that);case GraphEvent_BoundaryUpdated():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GraphEvent_NodeUpdated value)?  nodeUpdated,TResult? Function( GraphEvent_RelationUpdated value)?  relationUpdated,TResult? Function( GraphEvent_BatchUpdated value)?  batchUpdated,TResult? Function( GraphEvent_BoundaryUpdated value)?  boundaryUpdated,}){
final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated() when nodeUpdated != null:
return nodeUpdated(_that);case GraphEvent_RelationUpdated() when relationUpdated != null:
return relationUpdated(_that);case GraphEvent_BatchUpdated() when batchUpdated != null:
return batchUpdated(_that);case GraphEvent_BoundaryUpdated() when boundaryUpdated != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TypedRecordId id,  List<NodePatch> patches)?  nodeUpdated,TResult Function( TypedRecordId id,  List<RelationPatch> patches)?  relationUpdated,TResult Function( GraphDelta field0)?  batchUpdated,TResult Function( BoundingBox field0)?  boundaryUpdated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated() when nodeUpdated != null:
return nodeUpdated(_that.id,_that.patches);case GraphEvent_RelationUpdated() when relationUpdated != null:
return relationUpdated(_that.id,_that.patches);case GraphEvent_BatchUpdated() when batchUpdated != null:
return batchUpdated(_that.field0);case GraphEvent_BoundaryUpdated() when boundaryUpdated != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TypedRecordId id,  List<NodePatch> patches)  nodeUpdated,required TResult Function( TypedRecordId id,  List<RelationPatch> patches)  relationUpdated,required TResult Function( GraphDelta field0)  batchUpdated,required TResult Function( BoundingBox field0)  boundaryUpdated,}) {final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated():
return nodeUpdated(_that.id,_that.patches);case GraphEvent_RelationUpdated():
return relationUpdated(_that.id,_that.patches);case GraphEvent_BatchUpdated():
return batchUpdated(_that.field0);case GraphEvent_BoundaryUpdated():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TypedRecordId id,  List<NodePatch> patches)?  nodeUpdated,TResult? Function( TypedRecordId id,  List<RelationPatch> patches)?  relationUpdated,TResult? Function( GraphDelta field0)?  batchUpdated,TResult? Function( BoundingBox field0)?  boundaryUpdated,}) {final _that = this;
switch (_that) {
case GraphEvent_NodeUpdated() when nodeUpdated != null:
return nodeUpdated(_that.id,_that.patches);case GraphEvent_RelationUpdated() when relationUpdated != null:
return relationUpdated(_that.id,_that.patches);case GraphEvent_BatchUpdated() when batchUpdated != null:
return batchUpdated(_that.field0);case GraphEvent_BoundaryUpdated() when boundaryUpdated != null:
return boundaryUpdated(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class GraphEvent_NodeUpdated extends GraphEvent {
  const GraphEvent_NodeUpdated({required this.id, required final  List<NodePatch> patches}): _patches = patches,super._();
  

 final  TypedRecordId id;
 final  List<NodePatch> _patches;
 List<NodePatch> get patches {
  if (_patches is EqualUnmodifiableListView) return _patches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_patches);
}


/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphEvent_NodeUpdatedCopyWith<GraphEvent_NodeUpdated> get copyWith => _$GraphEvent_NodeUpdatedCopyWithImpl<GraphEvent_NodeUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphEvent_NodeUpdated&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._patches, _patches));
}


@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_patches));

@override
String toString() {
  return 'GraphEvent.nodeUpdated(id: $id, patches: $patches)';
}


}

/// @nodoc
abstract mixin class $GraphEvent_NodeUpdatedCopyWith<$Res> implements $GraphEventCopyWith<$Res> {
  factory $GraphEvent_NodeUpdatedCopyWith(GraphEvent_NodeUpdated value, $Res Function(GraphEvent_NodeUpdated) _then) = _$GraphEvent_NodeUpdatedCopyWithImpl;
@useResult
$Res call({
 TypedRecordId id, List<NodePatch> patches
});




}
/// @nodoc
class _$GraphEvent_NodeUpdatedCopyWithImpl<$Res>
    implements $GraphEvent_NodeUpdatedCopyWith<$Res> {
  _$GraphEvent_NodeUpdatedCopyWithImpl(this._self, this._then);

  final GraphEvent_NodeUpdated _self;
  final $Res Function(GraphEvent_NodeUpdated) _then;

/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patches = null,}) {
  return _then(GraphEvent_NodeUpdated(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as TypedRecordId,patches: null == patches ? _self._patches : patches // ignore: cast_nullable_to_non_nullable
as List<NodePatch>,
  ));
}


}

/// @nodoc


class GraphEvent_RelationUpdated extends GraphEvent {
  const GraphEvent_RelationUpdated({required this.id, required final  List<RelationPatch> patches}): _patches = patches,super._();
  

 final  TypedRecordId id;
 final  List<RelationPatch> _patches;
 List<RelationPatch> get patches {
  if (_patches is EqualUnmodifiableListView) return _patches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_patches);
}


/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphEvent_RelationUpdatedCopyWith<GraphEvent_RelationUpdated> get copyWith => _$GraphEvent_RelationUpdatedCopyWithImpl<GraphEvent_RelationUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphEvent_RelationUpdated&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._patches, _patches));
}


@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_patches));

@override
String toString() {
  return 'GraphEvent.relationUpdated(id: $id, patches: $patches)';
}


}

/// @nodoc
abstract mixin class $GraphEvent_RelationUpdatedCopyWith<$Res> implements $GraphEventCopyWith<$Res> {
  factory $GraphEvent_RelationUpdatedCopyWith(GraphEvent_RelationUpdated value, $Res Function(GraphEvent_RelationUpdated) _then) = _$GraphEvent_RelationUpdatedCopyWithImpl;
@useResult
$Res call({
 TypedRecordId id, List<RelationPatch> patches
});




}
/// @nodoc
class _$GraphEvent_RelationUpdatedCopyWithImpl<$Res>
    implements $GraphEvent_RelationUpdatedCopyWith<$Res> {
  _$GraphEvent_RelationUpdatedCopyWithImpl(this._self, this._then);

  final GraphEvent_RelationUpdated _self;
  final $Res Function(GraphEvent_RelationUpdated) _then;

/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patches = null,}) {
  return _then(GraphEvent_RelationUpdated(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as TypedRecordId,patches: null == patches ? _self._patches : patches // ignore: cast_nullable_to_non_nullable
as List<RelationPatch>,
  ));
}


}

/// @nodoc


class GraphEvent_BatchUpdated extends GraphEvent {
  const GraphEvent_BatchUpdated(this.field0): super._();
  

 final  GraphDelta field0;

/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphEvent_BatchUpdatedCopyWith<GraphEvent_BatchUpdated> get copyWith => _$GraphEvent_BatchUpdatedCopyWithImpl<GraphEvent_BatchUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphEvent_BatchUpdated&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'GraphEvent.batchUpdated(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $GraphEvent_BatchUpdatedCopyWith<$Res> implements $GraphEventCopyWith<$Res> {
  factory $GraphEvent_BatchUpdatedCopyWith(GraphEvent_BatchUpdated value, $Res Function(GraphEvent_BatchUpdated) _then) = _$GraphEvent_BatchUpdatedCopyWithImpl;
@useResult
$Res call({
 GraphDelta field0
});




}
/// @nodoc
class _$GraphEvent_BatchUpdatedCopyWithImpl<$Res>
    implements $GraphEvent_BatchUpdatedCopyWith<$Res> {
  _$GraphEvent_BatchUpdatedCopyWithImpl(this._self, this._then);

  final GraphEvent_BatchUpdated _self;
  final $Res Function(GraphEvent_BatchUpdated) _then;

/// Create a copy of GraphEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(GraphEvent_BatchUpdated(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as GraphDelta,
  ));
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
