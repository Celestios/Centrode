// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patches.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EntityPatch {

 Object get field0;



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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EntityPatch_Node value)?  node,TResult Function( EntityPatch_Relation value)?  relation,TResult Function( EntityPatch_CreateNode value)?  createNode,TResult Function( EntityPatch_DeleteNode value)?  deleteNode,TResult Function( EntityPatch_CreateRelation value)?  createRelation,TResult Function( EntityPatch_DeleteRelation value)?  deleteRelation,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EntityPatch_Node() when node != null:
return node(_that);case EntityPatch_Relation() when relation != null:
return relation(_that);case EntityPatch_CreateNode() when createNode != null:
return createNode(_that);case EntityPatch_DeleteNode() when deleteNode != null:
return deleteNode(_that);case EntityPatch_CreateRelation() when createRelation != null:
return createRelation(_that);case EntityPatch_DeleteRelation() when deleteRelation != null:
return deleteRelation(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EntityPatch_Node value)  node,required TResult Function( EntityPatch_Relation value)  relation,required TResult Function( EntityPatch_CreateNode value)  createNode,required TResult Function( EntityPatch_DeleteNode value)  deleteNode,required TResult Function( EntityPatch_CreateRelation value)  createRelation,required TResult Function( EntityPatch_DeleteRelation value)  deleteRelation,}){
final _that = this;
switch (_that) {
case EntityPatch_Node():
return node(_that);case EntityPatch_Relation():
return relation(_that);case EntityPatch_CreateNode():
return createNode(_that);case EntityPatch_DeleteNode():
return deleteNode(_that);case EntityPatch_CreateRelation():
return createRelation(_that);case EntityPatch_DeleteRelation():
return deleteRelation(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EntityPatch_Node value)?  node,TResult? Function( EntityPatch_Relation value)?  relation,TResult? Function( EntityPatch_CreateNode value)?  createNode,TResult? Function( EntityPatch_DeleteNode value)?  deleteNode,TResult? Function( EntityPatch_CreateRelation value)?  createRelation,TResult? Function( EntityPatch_DeleteRelation value)?  deleteRelation,}){
final _that = this;
switch (_that) {
case EntityPatch_Node() when node != null:
return node(_that);case EntityPatch_Relation() when relation != null:
return relation(_that);case EntityPatch_CreateNode() when createNode != null:
return createNode(_that);case EntityPatch_DeleteNode() when deleteNode != null:
return deleteNode(_that);case EntityPatch_CreateRelation() when createRelation != null:
return createRelation(_that);case EntityPatch_DeleteRelation() when deleteRelation != null:
return deleteRelation(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<NodePatch> field0)?  node,TResult Function( List<RelationPatch> field0)?  relation,TResult Function( Nodes field0,  List<IRelation> field1)?  createNode,TResult Function( Nodes field0,  List<IRelation> field1)?  deleteNode,TResult Function( IRelation field0)?  createRelation,TResult Function( IRelation field0)?  deleteRelation,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EntityPatch_Node() when node != null:
return node(_that.field0);case EntityPatch_Relation() when relation != null:
return relation(_that.field0);case EntityPatch_CreateNode() when createNode != null:
return createNode(_that.field0,_that.field1);case EntityPatch_DeleteNode() when deleteNode != null:
return deleteNode(_that.field0,_that.field1);case EntityPatch_CreateRelation() when createRelation != null:
return createRelation(_that.field0);case EntityPatch_DeleteRelation() when deleteRelation != null:
return deleteRelation(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<NodePatch> field0)  node,required TResult Function( List<RelationPatch> field0)  relation,required TResult Function( Nodes field0,  List<IRelation> field1)  createNode,required TResult Function( Nodes field0,  List<IRelation> field1)  deleteNode,required TResult Function( IRelation field0)  createRelation,required TResult Function( IRelation field0)  deleteRelation,}) {final _that = this;
switch (_that) {
case EntityPatch_Node():
return node(_that.field0);case EntityPatch_Relation():
return relation(_that.field0);case EntityPatch_CreateNode():
return createNode(_that.field0,_that.field1);case EntityPatch_DeleteNode():
return deleteNode(_that.field0,_that.field1);case EntityPatch_CreateRelation():
return createRelation(_that.field0);case EntityPatch_DeleteRelation():
return deleteRelation(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<NodePatch> field0)?  node,TResult? Function( List<RelationPatch> field0)?  relation,TResult? Function( Nodes field0,  List<IRelation> field1)?  createNode,TResult? Function( Nodes field0,  List<IRelation> field1)?  deleteNode,TResult? Function( IRelation field0)?  createRelation,TResult? Function( IRelation field0)?  deleteRelation,}) {final _that = this;
switch (_that) {
case EntityPatch_Node() when node != null:
return node(_that.field0);case EntityPatch_Relation() when relation != null:
return relation(_that.field0);case EntityPatch_CreateNode() when createNode != null:
return createNode(_that.field0,_that.field1);case EntityPatch_DeleteNode() when deleteNode != null:
return deleteNode(_that.field0,_that.field1);case EntityPatch_CreateRelation() when createRelation != null:
return createRelation(_that.field0);case EntityPatch_DeleteRelation() when deleteRelation != null:
return deleteRelation(_that.field0);case _:
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

/// @nodoc


class EntityPatch_CreateNode extends EntityPatch {
  const EntityPatch_CreateNode(this.field0, final  List<IRelation> field1): _field1 = field1,super._();
  

@override final  Nodes field0;
 final  List<IRelation> _field1;
 List<IRelation> get field1 {
  if (_field1 is EqualUnmodifiableListView) return _field1;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_field1);
}


/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntityPatch_CreateNodeCopyWith<EntityPatch_CreateNode> get copyWith => _$EntityPatch_CreateNodeCopyWithImpl<EntityPatch_CreateNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntityPatch_CreateNode&&(identical(other.field0, field0) || other.field0 == field0)&&const DeepCollectionEquality().equals(other._field1, _field1));
}


@override
int get hashCode => Object.hash(runtimeType,field0,const DeepCollectionEquality().hash(_field1));

@override
String toString() {
  return 'EntityPatch.createNode(field0: $field0, field1: $field1)';
}


}

/// @nodoc
abstract mixin class $EntityPatch_CreateNodeCopyWith<$Res> implements $EntityPatchCopyWith<$Res> {
  factory $EntityPatch_CreateNodeCopyWith(EntityPatch_CreateNode value, $Res Function(EntityPatch_CreateNode) _then) = _$EntityPatch_CreateNodeCopyWithImpl;
@useResult
$Res call({
 Nodes field0, List<IRelation> field1
});


$NodesCopyWith<$Res> get field0;

}
/// @nodoc
class _$EntityPatch_CreateNodeCopyWithImpl<$Res>
    implements $EntityPatch_CreateNodeCopyWith<$Res> {
  _$EntityPatch_CreateNodeCopyWithImpl(this._self, this._then);

  final EntityPatch_CreateNode _self;
  final $Res Function(EntityPatch_CreateNode) _then;

/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,Object? field1 = null,}) {
  return _then(EntityPatch_CreateNode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Nodes,null == field1 ? _self._field1 : field1 // ignore: cast_nullable_to_non_nullable
as List<IRelation>,
  ));
}

/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NodesCopyWith<$Res> get field0 {
  
  return $NodesCopyWith<$Res>(_self.field0, (value) {
    return _then(_self.copyWith(field0: value));
  });
}
}

/// @nodoc


class EntityPatch_DeleteNode extends EntityPatch {
  const EntityPatch_DeleteNode(this.field0, final  List<IRelation> field1): _field1 = field1,super._();
  

@override final  Nodes field0;
 final  List<IRelation> _field1;
 List<IRelation> get field1 {
  if (_field1 is EqualUnmodifiableListView) return _field1;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_field1);
}


/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntityPatch_DeleteNodeCopyWith<EntityPatch_DeleteNode> get copyWith => _$EntityPatch_DeleteNodeCopyWithImpl<EntityPatch_DeleteNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntityPatch_DeleteNode&&(identical(other.field0, field0) || other.field0 == field0)&&const DeepCollectionEquality().equals(other._field1, _field1));
}


@override
int get hashCode => Object.hash(runtimeType,field0,const DeepCollectionEquality().hash(_field1));

@override
String toString() {
  return 'EntityPatch.deleteNode(field0: $field0, field1: $field1)';
}


}

/// @nodoc
abstract mixin class $EntityPatch_DeleteNodeCopyWith<$Res> implements $EntityPatchCopyWith<$Res> {
  factory $EntityPatch_DeleteNodeCopyWith(EntityPatch_DeleteNode value, $Res Function(EntityPatch_DeleteNode) _then) = _$EntityPatch_DeleteNodeCopyWithImpl;
@useResult
$Res call({
 Nodes field0, List<IRelation> field1
});


$NodesCopyWith<$Res> get field0;

}
/// @nodoc
class _$EntityPatch_DeleteNodeCopyWithImpl<$Res>
    implements $EntityPatch_DeleteNodeCopyWith<$Res> {
  _$EntityPatch_DeleteNodeCopyWithImpl(this._self, this._then);

  final EntityPatch_DeleteNode _self;
  final $Res Function(EntityPatch_DeleteNode) _then;

/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,Object? field1 = null,}) {
  return _then(EntityPatch_DeleteNode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Nodes,null == field1 ? _self._field1 : field1 // ignore: cast_nullable_to_non_nullable
as List<IRelation>,
  ));
}

/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NodesCopyWith<$Res> get field0 {
  
  return $NodesCopyWith<$Res>(_self.field0, (value) {
    return _then(_self.copyWith(field0: value));
  });
}
}

/// @nodoc


class EntityPatch_CreateRelation extends EntityPatch {
  const EntityPatch_CreateRelation(this.field0): super._();
  

@override final  IRelation field0;

/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntityPatch_CreateRelationCopyWith<EntityPatch_CreateRelation> get copyWith => _$EntityPatch_CreateRelationCopyWithImpl<EntityPatch_CreateRelation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntityPatch_CreateRelation&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'EntityPatch.createRelation(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $EntityPatch_CreateRelationCopyWith<$Res> implements $EntityPatchCopyWith<$Res> {
  factory $EntityPatch_CreateRelationCopyWith(EntityPatch_CreateRelation value, $Res Function(EntityPatch_CreateRelation) _then) = _$EntityPatch_CreateRelationCopyWithImpl;
@useResult
$Res call({
 IRelation field0
});




}
/// @nodoc
class _$EntityPatch_CreateRelationCopyWithImpl<$Res>
    implements $EntityPatch_CreateRelationCopyWith<$Res> {
  _$EntityPatch_CreateRelationCopyWithImpl(this._self, this._then);

  final EntityPatch_CreateRelation _self;
  final $Res Function(EntityPatch_CreateRelation) _then;

/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(EntityPatch_CreateRelation(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as IRelation,
  ));
}


}

/// @nodoc


class EntityPatch_DeleteRelation extends EntityPatch {
  const EntityPatch_DeleteRelation(this.field0): super._();
  

@override final  IRelation field0;

/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntityPatch_DeleteRelationCopyWith<EntityPatch_DeleteRelation> get copyWith => _$EntityPatch_DeleteRelationCopyWithImpl<EntityPatch_DeleteRelation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntityPatch_DeleteRelation&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'EntityPatch.deleteRelation(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $EntityPatch_DeleteRelationCopyWith<$Res> implements $EntityPatchCopyWith<$Res> {
  factory $EntityPatch_DeleteRelationCopyWith(EntityPatch_DeleteRelation value, $Res Function(EntityPatch_DeleteRelation) _then) = _$EntityPatch_DeleteRelationCopyWithImpl;
@useResult
$Res call({
 IRelation field0
});




}
/// @nodoc
class _$EntityPatch_DeleteRelationCopyWithImpl<$Res>
    implements $EntityPatch_DeleteRelationCopyWith<$Res> {
  _$EntityPatch_DeleteRelationCopyWithImpl(this._self, this._then);

  final EntityPatch_DeleteRelation _self;
  final $Res Function(EntityPatch_DeleteRelation) _then;

/// Create a copy of EntityPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(EntityPatch_DeleteRelation(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as IRelation,
  ));
}


}

/// @nodoc
mixin _$NodePatch {

 Object? get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'NodePatch(field0: $field0)';
}


}

/// @nodoc
class $NodePatchCopyWith<$Res>  {
$NodePatchCopyWith(NodePatch _, $Res Function(NodePatch) __);
}


/// Adds pattern-matching-related methods to [NodePatch].
extension NodePatchPatterns on NodePatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NodePatch_Position value)?  position,TResult Function( NodePatch_Size value)?  size,TResult Function( NodePatch_Content value)?  content,TResult Function( NodePatch_IsExpanded value)?  isExpanded,TResult Function( NodePatch_Style value)?  style,TResult Function( NodePatch_TagOp value)?  tagOp,TResult Function( NodePatch_Significance value)?  significance,TResult Function( NodePatch_TaskState value)?  taskState,TResult Function( NodePatch_ShapeType value)?  shapeType,TResult Function( NodePatch_BrushType value)?  brushType,TResult Function( NodePatch_MediaType value)?  mediaType,TResult Function( NodePatch_Attachment value)?  attachment,TResult Function( NodePatch_Attachments value)?  attachments,TResult Function( NodePatch_Title value)?  title,TResult Function( NodePatch_Verb value)?  verb,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that);case NodePatch_Size() when size != null:
return size(_that);case NodePatch_Content() when content != null:
return content(_that);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that);case NodePatch_Style() when style != null:
return style(_that);case NodePatch_TagOp() when tagOp != null:
return tagOp(_that);case NodePatch_Significance() when significance != null:
return significance(_that);case NodePatch_TaskState() when taskState != null:
return taskState(_that);case NodePatch_ShapeType() when shapeType != null:
return shapeType(_that);case NodePatch_BrushType() when brushType != null:
return brushType(_that);case NodePatch_MediaType() when mediaType != null:
return mediaType(_that);case NodePatch_Attachment() when attachment != null:
return attachment(_that);case NodePatch_Attachments() when attachments != null:
return attachments(_that);case NodePatch_Title() when title != null:
return title(_that);case NodePatch_Verb() when verb != null:
return verb(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NodePatch_Position value)  position,required TResult Function( NodePatch_Size value)  size,required TResult Function( NodePatch_Content value)  content,required TResult Function( NodePatch_IsExpanded value)  isExpanded,required TResult Function( NodePatch_Style value)  style,required TResult Function( NodePatch_TagOp value)  tagOp,required TResult Function( NodePatch_Significance value)  significance,required TResult Function( NodePatch_TaskState value)  taskState,required TResult Function( NodePatch_ShapeType value)  shapeType,required TResult Function( NodePatch_BrushType value)  brushType,required TResult Function( NodePatch_MediaType value)  mediaType,required TResult Function( NodePatch_Attachment value)  attachment,required TResult Function( NodePatch_Attachments value)  attachments,required TResult Function( NodePatch_Title value)  title,required TResult Function( NodePatch_Verb value)  verb,}){
final _that = this;
switch (_that) {
case NodePatch_Position():
return position(_that);case NodePatch_Size():
return size(_that);case NodePatch_Content():
return content(_that);case NodePatch_IsExpanded():
return isExpanded(_that);case NodePatch_Style():
return style(_that);case NodePatch_TagOp():
return tagOp(_that);case NodePatch_Significance():
return significance(_that);case NodePatch_TaskState():
return taskState(_that);case NodePatch_ShapeType():
return shapeType(_that);case NodePatch_BrushType():
return brushType(_that);case NodePatch_MediaType():
return mediaType(_that);case NodePatch_Attachment():
return attachment(_that);case NodePatch_Attachments():
return attachments(_that);case NodePatch_Title():
return title(_that);case NodePatch_Verb():
return verb(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NodePatch_Position value)?  position,TResult? Function( NodePatch_Size value)?  size,TResult? Function( NodePatch_Content value)?  content,TResult? Function( NodePatch_IsExpanded value)?  isExpanded,TResult? Function( NodePatch_Style value)?  style,TResult? Function( NodePatch_TagOp value)?  tagOp,TResult? Function( NodePatch_Significance value)?  significance,TResult? Function( NodePatch_TaskState value)?  taskState,TResult? Function( NodePatch_ShapeType value)?  shapeType,TResult? Function( NodePatch_BrushType value)?  brushType,TResult? Function( NodePatch_MediaType value)?  mediaType,TResult? Function( NodePatch_Attachment value)?  attachment,TResult? Function( NodePatch_Attachments value)?  attachments,TResult? Function( NodePatch_Title value)?  title,TResult? Function( NodePatch_Verb value)?  verb,}){
final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that);case NodePatch_Size() when size != null:
return size(_that);case NodePatch_Content() when content != null:
return content(_that);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that);case NodePatch_Style() when style != null:
return style(_that);case NodePatch_TagOp() when tagOp != null:
return tagOp(_that);case NodePatch_Significance() when significance != null:
return significance(_that);case NodePatch_TaskState() when taskState != null:
return taskState(_that);case NodePatch_ShapeType() when shapeType != null:
return shapeType(_that);case NodePatch_BrushType() when brushType != null:
return brushType(_that);case NodePatch_MediaType() when mediaType != null:
return mediaType(_that);case NodePatch_Attachment() when attachment != null:
return attachment(_that);case NodePatch_Attachments() when attachments != null:
return attachments(_that);case NodePatch_Title() when title != null:
return title(_that);case NodePatch_Verb() when verb != null:
return verb(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Coordinates field0)?  position,TResult Function( Size field0)?  size,TResult Function( Content field0)?  content,TResult Function( bool field0)?  isExpanded,TResult Function( NodeStyle? field0)?  style,TResult Function( TagOperation field0)?  tagOp,TResult Function( int field0)?  significance,TResult Function( TaskState field0)?  taskState,TResult Function( ShapeType field0)?  shapeType,TResult Function( BrushType field0)?  brushType,TResult Function( MediaType field0)?  mediaType,TResult Function( Attachment field0)?  attachment,TResult Function( List<Attachment> field0)?  attachments,TResult Function( String field0)?  title,TResult Function( String field0)?  verb,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that.field0);case NodePatch_Size() when size != null:
return size(_that.field0);case NodePatch_Content() when content != null:
return content(_that.field0);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that.field0);case NodePatch_Style() when style != null:
return style(_that.field0);case NodePatch_TagOp() when tagOp != null:
return tagOp(_that.field0);case NodePatch_Significance() when significance != null:
return significance(_that.field0);case NodePatch_TaskState() when taskState != null:
return taskState(_that.field0);case NodePatch_ShapeType() when shapeType != null:
return shapeType(_that.field0);case NodePatch_BrushType() when brushType != null:
return brushType(_that.field0);case NodePatch_MediaType() when mediaType != null:
return mediaType(_that.field0);case NodePatch_Attachment() when attachment != null:
return attachment(_that.field0);case NodePatch_Attachments() when attachments != null:
return attachments(_that.field0);case NodePatch_Title() when title != null:
return title(_that.field0);case NodePatch_Verb() when verb != null:
return verb(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Coordinates field0)  position,required TResult Function( Size field0)  size,required TResult Function( Content field0)  content,required TResult Function( bool field0)  isExpanded,required TResult Function( NodeStyle? field0)  style,required TResult Function( TagOperation field0)  tagOp,required TResult Function( int field0)  significance,required TResult Function( TaskState field0)  taskState,required TResult Function( ShapeType field0)  shapeType,required TResult Function( BrushType field0)  brushType,required TResult Function( MediaType field0)  mediaType,required TResult Function( Attachment field0)  attachment,required TResult Function( List<Attachment> field0)  attachments,required TResult Function( String field0)  title,required TResult Function( String field0)  verb,}) {final _that = this;
switch (_that) {
case NodePatch_Position():
return position(_that.field0);case NodePatch_Size():
return size(_that.field0);case NodePatch_Content():
return content(_that.field0);case NodePatch_IsExpanded():
return isExpanded(_that.field0);case NodePatch_Style():
return style(_that.field0);case NodePatch_TagOp():
return tagOp(_that.field0);case NodePatch_Significance():
return significance(_that.field0);case NodePatch_TaskState():
return taskState(_that.field0);case NodePatch_ShapeType():
return shapeType(_that.field0);case NodePatch_BrushType():
return brushType(_that.field0);case NodePatch_MediaType():
return mediaType(_that.field0);case NodePatch_Attachment():
return attachment(_that.field0);case NodePatch_Attachments():
return attachments(_that.field0);case NodePatch_Title():
return title(_that.field0);case NodePatch_Verb():
return verb(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Coordinates field0)?  position,TResult? Function( Size field0)?  size,TResult? Function( Content field0)?  content,TResult? Function( bool field0)?  isExpanded,TResult? Function( NodeStyle? field0)?  style,TResult? Function( TagOperation field0)?  tagOp,TResult? Function( int field0)?  significance,TResult? Function( TaskState field0)?  taskState,TResult? Function( ShapeType field0)?  shapeType,TResult? Function( BrushType field0)?  brushType,TResult? Function( MediaType field0)?  mediaType,TResult? Function( Attachment field0)?  attachment,TResult? Function( List<Attachment> field0)?  attachments,TResult? Function( String field0)?  title,TResult? Function( String field0)?  verb,}) {final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that.field0);case NodePatch_Size() when size != null:
return size(_that.field0);case NodePatch_Content() when content != null:
return content(_that.field0);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that.field0);case NodePatch_Style() when style != null:
return style(_that.field0);case NodePatch_TagOp() when tagOp != null:
return tagOp(_that.field0);case NodePatch_Significance() when significance != null:
return significance(_that.field0);case NodePatch_TaskState() when taskState != null:
return taskState(_that.field0);case NodePatch_ShapeType() when shapeType != null:
return shapeType(_that.field0);case NodePatch_BrushType() when brushType != null:
return brushType(_that.field0);case NodePatch_MediaType() when mediaType != null:
return mediaType(_that.field0);case NodePatch_Attachment() when attachment != null:
return attachment(_that.field0);case NodePatch_Attachments() when attachments != null:
return attachments(_that.field0);case NodePatch_Title() when title != null:
return title(_that.field0);case NodePatch_Verb() when verb != null:
return verb(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class NodePatch_Position extends NodePatch {
  const NodePatch_Position(this.field0): super._();
  

@override final  Coordinates field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_PositionCopyWith<NodePatch_Position> get copyWith => _$NodePatch_PositionCopyWithImpl<NodePatch_Position>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_Position&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.position(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_PositionCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_PositionCopyWith(NodePatch_Position value, $Res Function(NodePatch_Position) _then) = _$NodePatch_PositionCopyWithImpl;
@useResult
$Res call({
 Coordinates field0
});




}
/// @nodoc
class _$NodePatch_PositionCopyWithImpl<$Res>
    implements $NodePatch_PositionCopyWith<$Res> {
  _$NodePatch_PositionCopyWithImpl(this._self, this._then);

  final NodePatch_Position _self;
  final $Res Function(NodePatch_Position) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_Position(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Coordinates,
  ));
}


}

/// @nodoc


class NodePatch_Size extends NodePatch {
  const NodePatch_Size(this.field0): super._();
  

@override final  Size field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_SizeCopyWith<NodePatch_Size> get copyWith => _$NodePatch_SizeCopyWithImpl<NodePatch_Size>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_Size&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.size(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_SizeCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_SizeCopyWith(NodePatch_Size value, $Res Function(NodePatch_Size) _then) = _$NodePatch_SizeCopyWithImpl;
@useResult
$Res call({
 Size field0
});




}
/// @nodoc
class _$NodePatch_SizeCopyWithImpl<$Res>
    implements $NodePatch_SizeCopyWith<$Res> {
  _$NodePatch_SizeCopyWithImpl(this._self, this._then);

  final NodePatch_Size _self;
  final $Res Function(NodePatch_Size) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_Size(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Size,
  ));
}


}

/// @nodoc


class NodePatch_Content extends NodePatch {
  const NodePatch_Content(this.field0): super._();
  

@override final  Content field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_ContentCopyWith<NodePatch_Content> get copyWith => _$NodePatch_ContentCopyWithImpl<NodePatch_Content>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_Content&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.content(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_ContentCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_ContentCopyWith(NodePatch_Content value, $Res Function(NodePatch_Content) _then) = _$NodePatch_ContentCopyWithImpl;
@useResult
$Res call({
 Content field0
});




}
/// @nodoc
class _$NodePatch_ContentCopyWithImpl<$Res>
    implements $NodePatch_ContentCopyWith<$Res> {
  _$NodePatch_ContentCopyWithImpl(this._self, this._then);

  final NodePatch_Content _self;
  final $Res Function(NodePatch_Content) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_Content(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Content,
  ));
}


}

/// @nodoc


class NodePatch_IsExpanded extends NodePatch {
  const NodePatch_IsExpanded(this.field0): super._();
  

@override final  bool field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_IsExpandedCopyWith<NodePatch_IsExpanded> get copyWith => _$NodePatch_IsExpandedCopyWithImpl<NodePatch_IsExpanded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_IsExpanded&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.isExpanded(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_IsExpandedCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_IsExpandedCopyWith(NodePatch_IsExpanded value, $Res Function(NodePatch_IsExpanded) _then) = _$NodePatch_IsExpandedCopyWithImpl;
@useResult
$Res call({
 bool field0
});




}
/// @nodoc
class _$NodePatch_IsExpandedCopyWithImpl<$Res>
    implements $NodePatch_IsExpandedCopyWith<$Res> {
  _$NodePatch_IsExpandedCopyWithImpl(this._self, this._then);

  final NodePatch_IsExpanded _self;
  final $Res Function(NodePatch_IsExpanded) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_IsExpanded(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class NodePatch_Style extends NodePatch {
  const NodePatch_Style([this.field0]): super._();
  

@override final  NodeStyle? field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_StyleCopyWith<NodePatch_Style> get copyWith => _$NodePatch_StyleCopyWithImpl<NodePatch_Style>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_Style&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.style(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_StyleCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_StyleCopyWith(NodePatch_Style value, $Res Function(NodePatch_Style) _then) = _$NodePatch_StyleCopyWithImpl;
@useResult
$Res call({
 NodeStyle? field0
});


$NodeStyleCopyWith<$Res>? get field0;

}
/// @nodoc
class _$NodePatch_StyleCopyWithImpl<$Res>
    implements $NodePatch_StyleCopyWith<$Res> {
  _$NodePatch_StyleCopyWithImpl(this._self, this._then);

  final NodePatch_Style _self;
  final $Res Function(NodePatch_Style) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = freezed,}) {
  return _then(NodePatch_Style(
freezed == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as NodeStyle?,
  ));
}

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NodeStyleCopyWith<$Res>? get field0 {
    if (_self.field0 == null) {
    return null;
  }

  return $NodeStyleCopyWith<$Res>(_self.field0!, (value) {
    return _then(_self.copyWith(field0: value));
  });
}
}

/// @nodoc


class NodePatch_TagOp extends NodePatch {
  const NodePatch_TagOp(this.field0): super._();
  

@override final  TagOperation field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_TagOpCopyWith<NodePatch_TagOp> get copyWith => _$NodePatch_TagOpCopyWithImpl<NodePatch_TagOp>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_TagOp&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.tagOp(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_TagOpCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_TagOpCopyWith(NodePatch_TagOp value, $Res Function(NodePatch_TagOp) _then) = _$NodePatch_TagOpCopyWithImpl;
@useResult
$Res call({
 TagOperation field0
});


$TagOperationCopyWith<$Res> get field0;

}
/// @nodoc
class _$NodePatch_TagOpCopyWithImpl<$Res>
    implements $NodePatch_TagOpCopyWith<$Res> {
  _$NodePatch_TagOpCopyWithImpl(this._self, this._then);

  final NodePatch_TagOp _self;
  final $Res Function(NodePatch_TagOp) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_TagOp(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as TagOperation,
  ));
}

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TagOperationCopyWith<$Res> get field0 {
  
  return $TagOperationCopyWith<$Res>(_self.field0, (value) {
    return _then(_self.copyWith(field0: value));
  });
}
}

/// @nodoc


class NodePatch_Significance extends NodePatch {
  const NodePatch_Significance(this.field0): super._();
  

@override final  int field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_SignificanceCopyWith<NodePatch_Significance> get copyWith => _$NodePatch_SignificanceCopyWithImpl<NodePatch_Significance>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_Significance&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.significance(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_SignificanceCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_SignificanceCopyWith(NodePatch_Significance value, $Res Function(NodePatch_Significance) _then) = _$NodePatch_SignificanceCopyWithImpl;
@useResult
$Res call({
 int field0
});




}
/// @nodoc
class _$NodePatch_SignificanceCopyWithImpl<$Res>
    implements $NodePatch_SignificanceCopyWith<$Res> {
  _$NodePatch_SignificanceCopyWithImpl(this._self, this._then);

  final NodePatch_Significance _self;
  final $Res Function(NodePatch_Significance) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_Significance(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class NodePatch_TaskState extends NodePatch {
  const NodePatch_TaskState(this.field0): super._();
  

@override final  TaskState field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_TaskStateCopyWith<NodePatch_TaskState> get copyWith => _$NodePatch_TaskStateCopyWithImpl<NodePatch_TaskState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_TaskState&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.taskState(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_TaskStateCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_TaskStateCopyWith(NodePatch_TaskState value, $Res Function(NodePatch_TaskState) _then) = _$NodePatch_TaskStateCopyWithImpl;
@useResult
$Res call({
 TaskState field0
});




}
/// @nodoc
class _$NodePatch_TaskStateCopyWithImpl<$Res>
    implements $NodePatch_TaskStateCopyWith<$Res> {
  _$NodePatch_TaskStateCopyWithImpl(this._self, this._then);

  final NodePatch_TaskState _self;
  final $Res Function(NodePatch_TaskState) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_TaskState(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as TaskState,
  ));
}


}

/// @nodoc


class NodePatch_ShapeType extends NodePatch {
  const NodePatch_ShapeType(this.field0): super._();
  

@override final  ShapeType field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_ShapeTypeCopyWith<NodePatch_ShapeType> get copyWith => _$NodePatch_ShapeTypeCopyWithImpl<NodePatch_ShapeType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_ShapeType&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.shapeType(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_ShapeTypeCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_ShapeTypeCopyWith(NodePatch_ShapeType value, $Res Function(NodePatch_ShapeType) _then) = _$NodePatch_ShapeTypeCopyWithImpl;
@useResult
$Res call({
 ShapeType field0
});




}
/// @nodoc
class _$NodePatch_ShapeTypeCopyWithImpl<$Res>
    implements $NodePatch_ShapeTypeCopyWith<$Res> {
  _$NodePatch_ShapeTypeCopyWithImpl(this._self, this._then);

  final NodePatch_ShapeType _self;
  final $Res Function(NodePatch_ShapeType) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_ShapeType(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as ShapeType,
  ));
}


}

/// @nodoc


class NodePatch_BrushType extends NodePatch {
  const NodePatch_BrushType(this.field0): super._();
  

@override final  BrushType field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_BrushTypeCopyWith<NodePatch_BrushType> get copyWith => _$NodePatch_BrushTypeCopyWithImpl<NodePatch_BrushType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_BrushType&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.brushType(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_BrushTypeCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_BrushTypeCopyWith(NodePatch_BrushType value, $Res Function(NodePatch_BrushType) _then) = _$NodePatch_BrushTypeCopyWithImpl;
@useResult
$Res call({
 BrushType field0
});




}
/// @nodoc
class _$NodePatch_BrushTypeCopyWithImpl<$Res>
    implements $NodePatch_BrushTypeCopyWith<$Res> {
  _$NodePatch_BrushTypeCopyWithImpl(this._self, this._then);

  final NodePatch_BrushType _self;
  final $Res Function(NodePatch_BrushType) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_BrushType(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as BrushType,
  ));
}


}

/// @nodoc


class NodePatch_MediaType extends NodePatch {
  const NodePatch_MediaType(this.field0): super._();
  

@override final  MediaType field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_MediaTypeCopyWith<NodePatch_MediaType> get copyWith => _$NodePatch_MediaTypeCopyWithImpl<NodePatch_MediaType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_MediaType&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.mediaType(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_MediaTypeCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_MediaTypeCopyWith(NodePatch_MediaType value, $Res Function(NodePatch_MediaType) _then) = _$NodePatch_MediaTypeCopyWithImpl;
@useResult
$Res call({
 MediaType field0
});




}
/// @nodoc
class _$NodePatch_MediaTypeCopyWithImpl<$Res>
    implements $NodePatch_MediaTypeCopyWith<$Res> {
  _$NodePatch_MediaTypeCopyWithImpl(this._self, this._then);

  final NodePatch_MediaType _self;
  final $Res Function(NodePatch_MediaType) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_MediaType(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as MediaType,
  ));
}


}

/// @nodoc


class NodePatch_Attachment extends NodePatch {
  const NodePatch_Attachment(this.field0): super._();
  

@override final  Attachment field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_AttachmentCopyWith<NodePatch_Attachment> get copyWith => _$NodePatch_AttachmentCopyWithImpl<NodePatch_Attachment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_Attachment&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.attachment(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_AttachmentCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_AttachmentCopyWith(NodePatch_Attachment value, $Res Function(NodePatch_Attachment) _then) = _$NodePatch_AttachmentCopyWithImpl;
@useResult
$Res call({
 Attachment field0
});




}
/// @nodoc
class _$NodePatch_AttachmentCopyWithImpl<$Res>
    implements $NodePatch_AttachmentCopyWith<$Res> {
  _$NodePatch_AttachmentCopyWithImpl(this._self, this._then);

  final NodePatch_Attachment _self;
  final $Res Function(NodePatch_Attachment) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_Attachment(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Attachment,
  ));
}


}

/// @nodoc


class NodePatch_Attachments extends NodePatch {
  const NodePatch_Attachments(final  List<Attachment> field0): _field0 = field0,super._();
  

 final  List<Attachment> _field0;
@override List<Attachment> get field0 {
  if (_field0 is EqualUnmodifiableListView) return _field0;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_field0);
}


/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_AttachmentsCopyWith<NodePatch_Attachments> get copyWith => _$NodePatch_AttachmentsCopyWithImpl<NodePatch_Attachments>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_Attachments&&const DeepCollectionEquality().equals(other._field0, _field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_field0));

@override
String toString() {
  return 'NodePatch.attachments(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_AttachmentsCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_AttachmentsCopyWith(NodePatch_Attachments value, $Res Function(NodePatch_Attachments) _then) = _$NodePatch_AttachmentsCopyWithImpl;
@useResult
$Res call({
 List<Attachment> field0
});




}
/// @nodoc
class _$NodePatch_AttachmentsCopyWithImpl<$Res>
    implements $NodePatch_AttachmentsCopyWith<$Res> {
  _$NodePatch_AttachmentsCopyWithImpl(this._self, this._then);

  final NodePatch_Attachments _self;
  final $Res Function(NodePatch_Attachments) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_Attachments(
null == field0 ? _self._field0 : field0 // ignore: cast_nullable_to_non_nullable
as List<Attachment>,
  ));
}


}

/// @nodoc


class NodePatch_Title extends NodePatch {
  const NodePatch_Title(this.field0): super._();
  

@override final  String field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_TitleCopyWith<NodePatch_Title> get copyWith => _$NodePatch_TitleCopyWithImpl<NodePatch_Title>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_Title&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.title(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_TitleCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_TitleCopyWith(NodePatch_Title value, $Res Function(NodePatch_Title) _then) = _$NodePatch_TitleCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$NodePatch_TitleCopyWithImpl<$Res>
    implements $NodePatch_TitleCopyWith<$Res> {
  _$NodePatch_TitleCopyWithImpl(this._self, this._then);

  final NodePatch_Title _self;
  final $Res Function(NodePatch_Title) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_Title(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NodePatch_Verb extends NodePatch {
  const NodePatch_Verb(this.field0): super._();
  

@override final  String field0;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_VerbCopyWith<NodePatch_Verb> get copyWith => _$NodePatch_VerbCopyWithImpl<NodePatch_Verb>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_Verb&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'NodePatch.verb(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_VerbCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_VerbCopyWith(NodePatch_Verb value, $Res Function(NodePatch_Verb) _then) = _$NodePatch_VerbCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$NodePatch_VerbCopyWithImpl<$Res>
    implements $NodePatch_VerbCopyWith<$Res> {
  _$NodePatch_VerbCopyWithImpl(this._self, this._then);

  final NodePatch_Verb _self;
  final $Res Function(NodePatch_Verb) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_Verb(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RelationPatch {

 Object? get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationPatch&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'RelationPatch(field0: $field0)';
}


}

/// @nodoc
class $RelationPatchCopyWith<$Res>  {
$RelationPatchCopyWith(RelationPatch _, $Res Function(RelationPatch) __);
}


/// Adds pattern-matching-related methods to [RelationPatch].
extension RelationPatchPatterns on RelationPatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RelationPatch_Verb value)?  verb,TResult Function( RelationPatch_Endpoints value)?  endpoints,TResult Function( RelationPatch_Style value)?  style,TResult Function( RelationPatch_Layout value)?  layout,TResult Function( RelationPatch_Direction value)?  direction,TResult Function( RelationPatch_RoutingMode value)?  routingMode,TResult Function( RelationPatch_PortSides value)?  portSides,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RelationPatch_Verb() when verb != null:
return verb(_that);case RelationPatch_Endpoints() when endpoints != null:
return endpoints(_that);case RelationPatch_Style() when style != null:
return style(_that);case RelationPatch_Layout() when layout != null:
return layout(_that);case RelationPatch_Direction() when direction != null:
return direction(_that);case RelationPatch_RoutingMode() when routingMode != null:
return routingMode(_that);case RelationPatch_PortSides() when portSides != null:
return portSides(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RelationPatch_Verb value)  verb,required TResult Function( RelationPatch_Endpoints value)  endpoints,required TResult Function( RelationPatch_Style value)  style,required TResult Function( RelationPatch_Layout value)  layout,required TResult Function( RelationPatch_Direction value)  direction,required TResult Function( RelationPatch_RoutingMode value)  routingMode,required TResult Function( RelationPatch_PortSides value)  portSides,}){
final _that = this;
switch (_that) {
case RelationPatch_Verb():
return verb(_that);case RelationPatch_Endpoints():
return endpoints(_that);case RelationPatch_Style():
return style(_that);case RelationPatch_Layout():
return layout(_that);case RelationPatch_Direction():
return direction(_that);case RelationPatch_RoutingMode():
return routingMode(_that);case RelationPatch_PortSides():
return portSides(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RelationPatch_Verb value)?  verb,TResult? Function( RelationPatch_Endpoints value)?  endpoints,TResult? Function( RelationPatch_Style value)?  style,TResult? Function( RelationPatch_Layout value)?  layout,TResult? Function( RelationPatch_Direction value)?  direction,TResult? Function( RelationPatch_RoutingMode value)?  routingMode,TResult? Function( RelationPatch_PortSides value)?  portSides,}){
final _that = this;
switch (_that) {
case RelationPatch_Verb() when verb != null:
return verb(_that);case RelationPatch_Endpoints() when endpoints != null:
return endpoints(_that);case RelationPatch_Style() when style != null:
return style(_that);case RelationPatch_Layout() when layout != null:
return layout(_that);case RelationPatch_Direction() when direction != null:
return direction(_that);case RelationPatch_RoutingMode() when routingMode != null:
return routingMode(_that);case RelationPatch_PortSides() when portSides != null:
return portSides(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field0)?  verb,TResult Function( TypedRecordId field0,  TypedRecordId field1)?  endpoints,TResult Function( RelationStyle? field0)?  style,TResult Function( RelationLayout? field0)?  layout,TResult Function( RelationDirection field0)?  direction,TResult Function( RoutingMode field0)?  routingMode,TResult Function( PortSide? field0,  PortSide? field1)?  portSides,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RelationPatch_Verb() when verb != null:
return verb(_that.field0);case RelationPatch_Endpoints() when endpoints != null:
return endpoints(_that.field0,_that.field1);case RelationPatch_Style() when style != null:
return style(_that.field0);case RelationPatch_Layout() when layout != null:
return layout(_that.field0);case RelationPatch_Direction() when direction != null:
return direction(_that.field0);case RelationPatch_RoutingMode() when routingMode != null:
return routingMode(_that.field0);case RelationPatch_PortSides() when portSides != null:
return portSides(_that.field0,_that.field1);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field0)  verb,required TResult Function( TypedRecordId field0,  TypedRecordId field1)  endpoints,required TResult Function( RelationStyle? field0)  style,required TResult Function( RelationLayout? field0)  layout,required TResult Function( RelationDirection field0)  direction,required TResult Function( RoutingMode field0)  routingMode,required TResult Function( PortSide? field0,  PortSide? field1)  portSides,}) {final _that = this;
switch (_that) {
case RelationPatch_Verb():
return verb(_that.field0);case RelationPatch_Endpoints():
return endpoints(_that.field0,_that.field1);case RelationPatch_Style():
return style(_that.field0);case RelationPatch_Layout():
return layout(_that.field0);case RelationPatch_Direction():
return direction(_that.field0);case RelationPatch_RoutingMode():
return routingMode(_that.field0);case RelationPatch_PortSides():
return portSides(_that.field0,_that.field1);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field0)?  verb,TResult? Function( TypedRecordId field0,  TypedRecordId field1)?  endpoints,TResult? Function( RelationStyle? field0)?  style,TResult? Function( RelationLayout? field0)?  layout,TResult? Function( RelationDirection field0)?  direction,TResult? Function( RoutingMode field0)?  routingMode,TResult? Function( PortSide? field0,  PortSide? field1)?  portSides,}) {final _that = this;
switch (_that) {
case RelationPatch_Verb() when verb != null:
return verb(_that.field0);case RelationPatch_Endpoints() when endpoints != null:
return endpoints(_that.field0,_that.field1);case RelationPatch_Style() when style != null:
return style(_that.field0);case RelationPatch_Layout() when layout != null:
return layout(_that.field0);case RelationPatch_Direction() when direction != null:
return direction(_that.field0);case RelationPatch_RoutingMode() when routingMode != null:
return routingMode(_that.field0);case RelationPatch_PortSides() when portSides != null:
return portSides(_that.field0,_that.field1);case _:
  return null;

}
}

}

/// @nodoc


class RelationPatch_Verb extends RelationPatch {
  const RelationPatch_Verb(this.field0): super._();
  

@override final  String field0;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationPatch_VerbCopyWith<RelationPatch_Verb> get copyWith => _$RelationPatch_VerbCopyWithImpl<RelationPatch_Verb>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationPatch_Verb&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'RelationPatch.verb(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $RelationPatch_VerbCopyWith<$Res> implements $RelationPatchCopyWith<$Res> {
  factory $RelationPatch_VerbCopyWith(RelationPatch_Verb value, $Res Function(RelationPatch_Verb) _then) = _$RelationPatch_VerbCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$RelationPatch_VerbCopyWithImpl<$Res>
    implements $RelationPatch_VerbCopyWith<$Res> {
  _$RelationPatch_VerbCopyWithImpl(this._self, this._then);

  final RelationPatch_Verb _self;
  final $Res Function(RelationPatch_Verb) _then;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(RelationPatch_Verb(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RelationPatch_Endpoints extends RelationPatch {
  const RelationPatch_Endpoints(this.field0, this.field1): super._();
  

@override final  TypedRecordId field0;
 final  TypedRecordId field1;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationPatch_EndpointsCopyWith<RelationPatch_Endpoints> get copyWith => _$RelationPatch_EndpointsCopyWithImpl<RelationPatch_Endpoints>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationPatch_Endpoints&&(identical(other.field0, field0) || other.field0 == field0)&&(identical(other.field1, field1) || other.field1 == field1));
}


@override
int get hashCode => Object.hash(runtimeType,field0,field1);

@override
String toString() {
  return 'RelationPatch.endpoints(field0: $field0, field1: $field1)';
}


}

/// @nodoc
abstract mixin class $RelationPatch_EndpointsCopyWith<$Res> implements $RelationPatchCopyWith<$Res> {
  factory $RelationPatch_EndpointsCopyWith(RelationPatch_Endpoints value, $Res Function(RelationPatch_Endpoints) _then) = _$RelationPatch_EndpointsCopyWithImpl;
@useResult
$Res call({
 TypedRecordId field0, TypedRecordId field1
});




}
/// @nodoc
class _$RelationPatch_EndpointsCopyWithImpl<$Res>
    implements $RelationPatch_EndpointsCopyWith<$Res> {
  _$RelationPatch_EndpointsCopyWithImpl(this._self, this._then);

  final RelationPatch_Endpoints _self;
  final $Res Function(RelationPatch_Endpoints) _then;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,Object? field1 = null,}) {
  return _then(RelationPatch_Endpoints(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as TypedRecordId,null == field1 ? _self.field1 : field1 // ignore: cast_nullable_to_non_nullable
as TypedRecordId,
  ));
}


}

/// @nodoc


class RelationPatch_Style extends RelationPatch {
  const RelationPatch_Style([this.field0]): super._();
  

@override final  RelationStyle? field0;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationPatch_StyleCopyWith<RelationPatch_Style> get copyWith => _$RelationPatch_StyleCopyWithImpl<RelationPatch_Style>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationPatch_Style&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'RelationPatch.style(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $RelationPatch_StyleCopyWith<$Res> implements $RelationPatchCopyWith<$Res> {
  factory $RelationPatch_StyleCopyWith(RelationPatch_Style value, $Res Function(RelationPatch_Style) _then) = _$RelationPatch_StyleCopyWithImpl;
@useResult
$Res call({
 RelationStyle? field0
});


$RelationStyleCopyWith<$Res>? get field0;

}
/// @nodoc
class _$RelationPatch_StyleCopyWithImpl<$Res>
    implements $RelationPatch_StyleCopyWith<$Res> {
  _$RelationPatch_StyleCopyWithImpl(this._self, this._then);

  final RelationPatch_Style _self;
  final $Res Function(RelationPatch_Style) _then;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = freezed,}) {
  return _then(RelationPatch_Style(
freezed == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as RelationStyle?,
  ));
}

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RelationStyleCopyWith<$Res>? get field0 {
    if (_self.field0 == null) {
    return null;
  }

  return $RelationStyleCopyWith<$Res>(_self.field0!, (value) {
    return _then(_self.copyWith(field0: value));
  });
}
}

/// @nodoc


class RelationPatch_Layout extends RelationPatch {
  const RelationPatch_Layout([this.field0]): super._();
  

@override final  RelationLayout? field0;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationPatch_LayoutCopyWith<RelationPatch_Layout> get copyWith => _$RelationPatch_LayoutCopyWithImpl<RelationPatch_Layout>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationPatch_Layout&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'RelationPatch.layout(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $RelationPatch_LayoutCopyWith<$Res> implements $RelationPatchCopyWith<$Res> {
  factory $RelationPatch_LayoutCopyWith(RelationPatch_Layout value, $Res Function(RelationPatch_Layout) _then) = _$RelationPatch_LayoutCopyWithImpl;
@useResult
$Res call({
 RelationLayout? field0
});


$RelationLayoutCopyWith<$Res>? get field0;

}
/// @nodoc
class _$RelationPatch_LayoutCopyWithImpl<$Res>
    implements $RelationPatch_LayoutCopyWith<$Res> {
  _$RelationPatch_LayoutCopyWithImpl(this._self, this._then);

  final RelationPatch_Layout _self;
  final $Res Function(RelationPatch_Layout) _then;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = freezed,}) {
  return _then(RelationPatch_Layout(
freezed == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as RelationLayout?,
  ));
}

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RelationLayoutCopyWith<$Res>? get field0 {
    if (_self.field0 == null) {
    return null;
  }

  return $RelationLayoutCopyWith<$Res>(_self.field0!, (value) {
    return _then(_self.copyWith(field0: value));
  });
}
}

/// @nodoc


class RelationPatch_Direction extends RelationPatch {
  const RelationPatch_Direction(this.field0): super._();
  

@override final  RelationDirection field0;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationPatch_DirectionCopyWith<RelationPatch_Direction> get copyWith => _$RelationPatch_DirectionCopyWithImpl<RelationPatch_Direction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationPatch_Direction&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'RelationPatch.direction(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $RelationPatch_DirectionCopyWith<$Res> implements $RelationPatchCopyWith<$Res> {
  factory $RelationPatch_DirectionCopyWith(RelationPatch_Direction value, $Res Function(RelationPatch_Direction) _then) = _$RelationPatch_DirectionCopyWithImpl;
@useResult
$Res call({
 RelationDirection field0
});




}
/// @nodoc
class _$RelationPatch_DirectionCopyWithImpl<$Res>
    implements $RelationPatch_DirectionCopyWith<$Res> {
  _$RelationPatch_DirectionCopyWithImpl(this._self, this._then);

  final RelationPatch_Direction _self;
  final $Res Function(RelationPatch_Direction) _then;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(RelationPatch_Direction(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as RelationDirection,
  ));
}


}

/// @nodoc


class RelationPatch_RoutingMode extends RelationPatch {
  const RelationPatch_RoutingMode(this.field0): super._();
  

@override final  RoutingMode field0;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationPatch_RoutingModeCopyWith<RelationPatch_RoutingMode> get copyWith => _$RelationPatch_RoutingModeCopyWithImpl<RelationPatch_RoutingMode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationPatch_RoutingMode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'RelationPatch.routingMode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $RelationPatch_RoutingModeCopyWith<$Res> implements $RelationPatchCopyWith<$Res> {
  factory $RelationPatch_RoutingModeCopyWith(RelationPatch_RoutingMode value, $Res Function(RelationPatch_RoutingMode) _then) = _$RelationPatch_RoutingModeCopyWithImpl;
@useResult
$Res call({
 RoutingMode field0
});


$RoutingModeCopyWith<$Res> get field0;

}
/// @nodoc
class _$RelationPatch_RoutingModeCopyWithImpl<$Res>
    implements $RelationPatch_RoutingModeCopyWith<$Res> {
  _$RelationPatch_RoutingModeCopyWithImpl(this._self, this._then);

  final RelationPatch_RoutingMode _self;
  final $Res Function(RelationPatch_RoutingMode) _then;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(RelationPatch_RoutingMode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as RoutingMode,
  ));
}

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoutingModeCopyWith<$Res> get field0 {
  
  return $RoutingModeCopyWith<$Res>(_self.field0, (value) {
    return _then(_self.copyWith(field0: value));
  });
}
}

/// @nodoc


class RelationPatch_PortSides extends RelationPatch {
  const RelationPatch_PortSides([this.field0, this.field1]): super._();
  

@override final  PortSide? field0;
 final  PortSide? field1;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationPatch_PortSidesCopyWith<RelationPatch_PortSides> get copyWith => _$RelationPatch_PortSidesCopyWithImpl<RelationPatch_PortSides>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationPatch_PortSides&&(identical(other.field0, field0) || other.field0 == field0)&&(identical(other.field1, field1) || other.field1 == field1));
}


@override
int get hashCode => Object.hash(runtimeType,field0,field1);

@override
String toString() {
  return 'RelationPatch.portSides(field0: $field0, field1: $field1)';
}


}

/// @nodoc
abstract mixin class $RelationPatch_PortSidesCopyWith<$Res> implements $RelationPatchCopyWith<$Res> {
  factory $RelationPatch_PortSidesCopyWith(RelationPatch_PortSides value, $Res Function(RelationPatch_PortSides) _then) = _$RelationPatch_PortSidesCopyWithImpl;
@useResult
$Res call({
 PortSide? field0, PortSide? field1
});




}
/// @nodoc
class _$RelationPatch_PortSidesCopyWithImpl<$Res>
    implements $RelationPatch_PortSidesCopyWith<$Res> {
  _$RelationPatch_PortSidesCopyWithImpl(this._self, this._then);

  final RelationPatch_PortSides _self;
  final $Res Function(RelationPatch_PortSides) _then;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = freezed,Object? field1 = freezed,}) {
  return _then(RelationPatch_PortSides(
freezed == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as PortSide?,freezed == field1 ? _self.field1 : field1 // ignore: cast_nullable_to_non_nullable
as PortSide?,
  ));
}


}

/// @nodoc
mixin _$TagOperation {

 TypedRecordId get field0;
/// Create a copy of TagOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagOperationCopyWith<TagOperation> get copyWith => _$TagOperationCopyWithImpl<TagOperation>(this as TagOperation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TagOperation&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'TagOperation(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $TagOperationCopyWith<$Res>  {
  factory $TagOperationCopyWith(TagOperation value, $Res Function(TagOperation) _then) = _$TagOperationCopyWithImpl;
@useResult
$Res call({
 TypedRecordId field0
});




}
/// @nodoc
class _$TagOperationCopyWithImpl<$Res>
    implements $TagOperationCopyWith<$Res> {
  _$TagOperationCopyWithImpl(this._self, this._then);

  final TagOperation _self;
  final $Res Function(TagOperation) _then;

/// Create a copy of TagOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field0 = null,}) {
  return _then(_self.copyWith(
field0: null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as TypedRecordId,
  ));
}

}


/// Adds pattern-matching-related methods to [TagOperation].
extension TagOperationPatterns on TagOperation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TagOperation_Add value)?  add,TResult Function( TagOperation_Remove value)?  remove,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TagOperation_Add() when add != null:
return add(_that);case TagOperation_Remove() when remove != null:
return remove(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TagOperation_Add value)  add,required TResult Function( TagOperation_Remove value)  remove,}){
final _that = this;
switch (_that) {
case TagOperation_Add():
return add(_that);case TagOperation_Remove():
return remove(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TagOperation_Add value)?  add,TResult? Function( TagOperation_Remove value)?  remove,}){
final _that = this;
switch (_that) {
case TagOperation_Add() when add != null:
return add(_that);case TagOperation_Remove() when remove != null:
return remove(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TypedRecordId field0)?  add,TResult Function( TypedRecordId field0)?  remove,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TagOperation_Add() when add != null:
return add(_that.field0);case TagOperation_Remove() when remove != null:
return remove(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TypedRecordId field0)  add,required TResult Function( TypedRecordId field0)  remove,}) {final _that = this;
switch (_that) {
case TagOperation_Add():
return add(_that.field0);case TagOperation_Remove():
return remove(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TypedRecordId field0)?  add,TResult? Function( TypedRecordId field0)?  remove,}) {final _that = this;
switch (_that) {
case TagOperation_Add() when add != null:
return add(_that.field0);case TagOperation_Remove() when remove != null:
return remove(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class TagOperation_Add extends TagOperation {
  const TagOperation_Add(this.field0): super._();
  

@override final  TypedRecordId field0;

/// Create a copy of TagOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagOperation_AddCopyWith<TagOperation_Add> get copyWith => _$TagOperation_AddCopyWithImpl<TagOperation_Add>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TagOperation_Add&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'TagOperation.add(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $TagOperation_AddCopyWith<$Res> implements $TagOperationCopyWith<$Res> {
  factory $TagOperation_AddCopyWith(TagOperation_Add value, $Res Function(TagOperation_Add) _then) = _$TagOperation_AddCopyWithImpl;
@override @useResult
$Res call({
 TypedRecordId field0
});




}
/// @nodoc
class _$TagOperation_AddCopyWithImpl<$Res>
    implements $TagOperation_AddCopyWith<$Res> {
  _$TagOperation_AddCopyWithImpl(this._self, this._then);

  final TagOperation_Add _self;
  final $Res Function(TagOperation_Add) _then;

/// Create a copy of TagOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(TagOperation_Add(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as TypedRecordId,
  ));
}


}

/// @nodoc


class TagOperation_Remove extends TagOperation {
  const TagOperation_Remove(this.field0): super._();
  

@override final  TypedRecordId field0;

/// Create a copy of TagOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagOperation_RemoveCopyWith<TagOperation_Remove> get copyWith => _$TagOperation_RemoveCopyWithImpl<TagOperation_Remove>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TagOperation_Remove&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'TagOperation.remove(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $TagOperation_RemoveCopyWith<$Res> implements $TagOperationCopyWith<$Res> {
  factory $TagOperation_RemoveCopyWith(TagOperation_Remove value, $Res Function(TagOperation_Remove) _then) = _$TagOperation_RemoveCopyWithImpl;
@override @useResult
$Res call({
 TypedRecordId field0
});




}
/// @nodoc
class _$TagOperation_RemoveCopyWithImpl<$Res>
    implements $TagOperation_RemoveCopyWith<$Res> {
  _$TagOperation_RemoveCopyWithImpl(this._self, this._then);

  final TagOperation_Remove _self;
  final $Res Function(TagOperation_Remove) _then;

/// Create a copy of TagOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(TagOperation_Remove(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as TypedRecordId,
  ));
}


}

// dart format on
