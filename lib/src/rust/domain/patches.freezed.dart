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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NodePatch_Position value)?  position,TResult Function( NodePatch_Size value)?  size,TResult Function( NodePatch_Content value)?  content,TResult Function( NodePatch_IsExpanded value)?  isExpanded,TResult Function( NodePatch_Style value)?  style,TResult Function( NodePatch_TagOp value)?  tagOp,TResult Function( NodePatch_Significance value)?  significance,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that);case NodePatch_Size() when size != null:
return size(_that);case NodePatch_Content() when content != null:
return content(_that);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that);case NodePatch_Style() when style != null:
return style(_that);case NodePatch_TagOp() when tagOp != null:
return tagOp(_that);case NodePatch_Significance() when significance != null:
return significance(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NodePatch_Position value)  position,required TResult Function( NodePatch_Size value)  size,required TResult Function( NodePatch_Content value)  content,required TResult Function( NodePatch_IsExpanded value)  isExpanded,required TResult Function( NodePatch_Style value)  style,required TResult Function( NodePatch_TagOp value)  tagOp,required TResult Function( NodePatch_Significance value)  significance,}){
final _that = this;
switch (_that) {
case NodePatch_Position():
return position(_that);case NodePatch_Size():
return size(_that);case NodePatch_Content():
return content(_that);case NodePatch_IsExpanded():
return isExpanded(_that);case NodePatch_Style():
return style(_that);case NodePatch_TagOp():
return tagOp(_that);case NodePatch_Significance():
return significance(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NodePatch_Position value)?  position,TResult? Function( NodePatch_Size value)?  size,TResult? Function( NodePatch_Content value)?  content,TResult? Function( NodePatch_IsExpanded value)?  isExpanded,TResult? Function( NodePatch_Style value)?  style,TResult? Function( NodePatch_TagOp value)?  tagOp,TResult? Function( NodePatch_Significance value)?  significance,}){
final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that);case NodePatch_Size() when size != null:
return size(_that);case NodePatch_Content() when content != null:
return content(_that);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that);case NodePatch_Style() when style != null:
return style(_that);case NodePatch_TagOp() when tagOp != null:
return tagOp(_that);case NodePatch_Significance() when significance != null:
return significance(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Coordinates field0)?  position,TResult Function( Size field0)?  size,TResult Function( Content field0)?  content,TResult Function( bool field0)?  isExpanded,TResult Function( NodeStyle? field0)?  style,TResult Function( TagOperation field0)?  tagOp,TResult Function( int field0)?  significance,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that.field0);case NodePatch_Size() when size != null:
return size(_that.field0);case NodePatch_Content() when content != null:
return content(_that.field0);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that.field0);case NodePatch_Style() when style != null:
return style(_that.field0);case NodePatch_TagOp() when tagOp != null:
return tagOp(_that.field0);case NodePatch_Significance() when significance != null:
return significance(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Coordinates field0)  position,required TResult Function( Size field0)  size,required TResult Function( Content field0)  content,required TResult Function( bool field0)  isExpanded,required TResult Function( NodeStyle? field0)  style,required TResult Function( TagOperation field0)  tagOp,required TResult Function( int field0)  significance,}) {final _that = this;
switch (_that) {
case NodePatch_Position():
return position(_that.field0);case NodePatch_Size():
return size(_that.field0);case NodePatch_Content():
return content(_that.field0);case NodePatch_IsExpanded():
return isExpanded(_that.field0);case NodePatch_Style():
return style(_that.field0);case NodePatch_TagOp():
return tagOp(_that.field0);case NodePatch_Significance():
return significance(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Coordinates field0)?  position,TResult? Function( Size field0)?  size,TResult? Function( Content field0)?  content,TResult? Function( bool field0)?  isExpanded,TResult? Function( NodeStyle? field0)?  style,TResult? Function( TagOperation field0)?  tagOp,TResult? Function( int field0)?  significance,}) {final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that.field0);case NodePatch_Size() when size != null:
return size(_that.field0);case NodePatch_Content() when content != null:
return content(_that.field0);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that.field0);case NodePatch_Style() when style != null:
return style(_that.field0);case NodePatch_TagOp() when tagOp != null:
return tagOp(_that.field0);case NodePatch_Significance() when significance != null:
return significance(_that.field0);case _:
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RelationPatch_Verb value)?  verb,TResult Function( RelationPatch_Style value)?  style,TResult Function( RelationPatch_Layout value)?  layout,TResult Function( RelationPatch_Directionless value)?  directionless,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RelationPatch_Verb() when verb != null:
return verb(_that);case RelationPatch_Style() when style != null:
return style(_that);case RelationPatch_Layout() when layout != null:
return layout(_that);case RelationPatch_Directionless() when directionless != null:
return directionless(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RelationPatch_Verb value)  verb,required TResult Function( RelationPatch_Style value)  style,required TResult Function( RelationPatch_Layout value)  layout,required TResult Function( RelationPatch_Directionless value)  directionless,}){
final _that = this;
switch (_that) {
case RelationPatch_Verb():
return verb(_that);case RelationPatch_Style():
return style(_that);case RelationPatch_Layout():
return layout(_that);case RelationPatch_Directionless():
return directionless(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RelationPatch_Verb value)?  verb,TResult? Function( RelationPatch_Style value)?  style,TResult? Function( RelationPatch_Layout value)?  layout,TResult? Function( RelationPatch_Directionless value)?  directionless,}){
final _that = this;
switch (_that) {
case RelationPatch_Verb() when verb != null:
return verb(_that);case RelationPatch_Style() when style != null:
return style(_that);case RelationPatch_Layout() when layout != null:
return layout(_that);case RelationPatch_Directionless() when directionless != null:
return directionless(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field0)?  verb,TResult Function( RelationStyle? field0)?  style,TResult Function( RelationLayout? field0)?  layout,TResult Function( bool field0)?  directionless,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RelationPatch_Verb() when verb != null:
return verb(_that.field0);case RelationPatch_Style() when style != null:
return style(_that.field0);case RelationPatch_Layout() when layout != null:
return layout(_that.field0);case RelationPatch_Directionless() when directionless != null:
return directionless(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field0)  verb,required TResult Function( RelationStyle? field0)  style,required TResult Function( RelationLayout? field0)  layout,required TResult Function( bool field0)  directionless,}) {final _that = this;
switch (_that) {
case RelationPatch_Verb():
return verb(_that.field0);case RelationPatch_Style():
return style(_that.field0);case RelationPatch_Layout():
return layout(_that.field0);case RelationPatch_Directionless():
return directionless(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field0)?  verb,TResult? Function( RelationStyle? field0)?  style,TResult? Function( RelationLayout? field0)?  layout,TResult? Function( bool field0)?  directionless,}) {final _that = this;
switch (_that) {
case RelationPatch_Verb() when verb != null:
return verb(_that.field0);case RelationPatch_Style() when style != null:
return style(_that.field0);case RelationPatch_Layout() when layout != null:
return layout(_that.field0);case RelationPatch_Directionless() when directionless != null:
return directionless(_that.field0);case _:
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


class RelationPatch_Directionless extends RelationPatch {
  const RelationPatch_Directionless(this.field0): super._();
  

@override final  bool field0;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationPatch_DirectionlessCopyWith<RelationPatch_Directionless> get copyWith => _$RelationPatch_DirectionlessCopyWithImpl<RelationPatch_Directionless>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationPatch_Directionless&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'RelationPatch.directionless(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $RelationPatch_DirectionlessCopyWith<$Res> implements $RelationPatchCopyWith<$Res> {
  factory $RelationPatch_DirectionlessCopyWith(RelationPatch_Directionless value, $Res Function(RelationPatch_Directionless) _then) = _$RelationPatch_DirectionlessCopyWithImpl;
@useResult
$Res call({
 bool field0
});




}
/// @nodoc
class _$RelationPatch_DirectionlessCopyWithImpl<$Res>
    implements $RelationPatch_DirectionlessCopyWith<$Res> {
  _$RelationPatch_DirectionlessCopyWithImpl(this._self, this._then);

  final RelationPatch_Directionless _self;
  final $Res Function(RelationPatch_Directionless) _then;

/// Create a copy of RelationPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(RelationPatch_Directionless(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$TagOperation {

 String get field0;
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
 String field0
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
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field0)?  add,TResult Function( String field0)?  remove,required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field0)  add,required TResult Function( String field0)  remove,}) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field0)?  add,TResult? Function( String field0)?  remove,}) {final _that = this;
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
  

@override final  String field0;

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
 String field0
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
as String,
  ));
}


}

/// @nodoc


class TagOperation_Remove extends TagOperation {
  const TagOperation_Remove(this.field0): super._();
  

@override final  String field0;

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
 String field0
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
as String,
  ));
}


}

// dart format on
