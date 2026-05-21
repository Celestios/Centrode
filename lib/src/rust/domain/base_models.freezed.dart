// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'base_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EntityPatch {

 List<Object> get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntityPatch&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'EntityPatch(field0: $field0)';
}


}

/// @nodoc
class $EntityPatchCopyWith<$Res>  {
$EntityPatchCopyWith(EntityPatch _, $Res Function(EntityPatch) __);
}


/// Adds pattern-matching-related methods to [EntityPatch].
extension EntityPatchPatterns on EntityPatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EntityPatch_Node value)?  node,TResult Function( EntityPatch_Relation value)?  relation,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EntityPatch_Node() when node != null:
return node(_that);case EntityPatch_Relation() when relation != null:
return relation(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EntityPatch_Node value)  node,required TResult Function( EntityPatch_Relation value)  relation,}){
final _that = this;
switch (_that) {
case EntityPatch_Node():
return node(_that);case EntityPatch_Relation():
return relation(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EntityPatch_Node value)?  node,TResult? Function( EntityPatch_Relation value)?  relation,}){
final _that = this;
switch (_that) {
case EntityPatch_Node() when node != null:
return node(_that);case EntityPatch_Relation() when relation != null:
return relation(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<NodePatch> field0)?  node,TResult Function( List<RelationPatch> field0)?  relation,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EntityPatch_Node() when node != null:
return node(_that.field0);case EntityPatch_Relation() when relation != null:
return relation(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<NodePatch> field0)  node,required TResult Function( List<RelationPatch> field0)  relation,}) {final _that = this;
switch (_that) {
case EntityPatch_Node():
return node(_that.field0);case EntityPatch_Relation():
return relation(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<NodePatch> field0)?  node,TResult? Function( List<RelationPatch> field0)?  relation,}) {final _that = this;
switch (_that) {
case EntityPatch_Node() when node != null:
return node(_that.field0);case EntityPatch_Relation() when relation != null:
return relation(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class EntityPatch_Node extends EntityPatch {
  const EntityPatch_Node(final  List<NodePatch> field0): _field0 = field0,super._();
  

 final  List<NodePatch> _field0;
@override List<NodePatch> get field0 {
  if (_field0 is EqualUnmodifiableListView) return _field0;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_field0);
}


/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntityPatch_NodeCopyWith<EntityPatch_Node> get copyWith => _$EntityPatch_NodeCopyWithImpl<EntityPatch_Node>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntityPatch_Node&&const DeepCollectionEquality().equals(other._field0, _field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_field0));

@override
String toString() {
  return 'EntityPatch.node(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $EntityPatch_NodeCopyWith<$Res> implements $EntityPatchCopyWith<$Res> {
  factory $EntityPatch_NodeCopyWith(EntityPatch_Node value, $Res Function(EntityPatch_Node) _then) = _$EntityPatch_NodeCopyWithImpl;
@useResult
$Res call({
 List<NodePatch> field0
});




}
/// @nodoc
class _$EntityPatch_NodeCopyWithImpl<$Res>
    implements $EntityPatch_NodeCopyWith<$Res> {
  _$EntityPatch_NodeCopyWithImpl(this._self, this._then);

  final EntityPatch_Node _self;
  final $Res Function(EntityPatch_Node) _then;

/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(EntityPatch_Node(
null == field0 ? _self._field0 : field0 // ignore: cast_nullable_to_non_nullable
as List<NodePatch>,
  ));
}


}

/// @nodoc


class EntityPatch_Relation extends EntityPatch {
  const EntityPatch_Relation(final  List<RelationPatch> field0): _field0 = field0,super._();
  

 final  List<RelationPatch> _field0;
@override List<RelationPatch> get field0 {
  if (_field0 is EqualUnmodifiableListView) return _field0;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_field0);
}


/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntityPatch_RelationCopyWith<EntityPatch_Relation> get copyWith => _$EntityPatch_RelationCopyWithImpl<EntityPatch_Relation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntityPatch_Relation&&const DeepCollectionEquality().equals(other._field0, _field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_field0));

@override
String toString() {
  return 'EntityPatch.relation(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $EntityPatch_RelationCopyWith<$Res> implements $EntityPatchCopyWith<$Res> {
  factory $EntityPatch_RelationCopyWith(EntityPatch_Relation value, $Res Function(EntityPatch_Relation) _then) = _$EntityPatch_RelationCopyWithImpl;
@useResult
$Res call({
 List<RelationPatch> field0
});




}
/// @nodoc
class _$EntityPatch_RelationCopyWithImpl<$Res>
    implements $EntityPatch_RelationCopyWith<$Res> {
  _$EntityPatch_RelationCopyWithImpl(this._self, this._then);

  final EntityPatch_Relation _self;
  final $Res Function(EntityPatch_Relation) _then;

/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(EntityPatch_Relation(
null == field0 ? _self._field0 : field0 // ignore: cast_nullable_to_non_nullable
as List<RelationPatch>,
  ));
}


}

// dart format on
