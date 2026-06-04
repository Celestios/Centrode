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
mixin _$Nodes {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nodes&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'Nodes(field0: $field0)';
}


}

/// @nodoc
class $NodesCopyWith<$Res>  {
$NodesCopyWith(Nodes _, $Res Function(Nodes) __);
}


/// Adds pattern-matching-related methods to [Nodes].
extension NodesPatterns on Nodes {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Nodes_INode value)?  iNode,TResult Function( Nodes_TaskNode value)?  taskNode,TResult Function( Nodes_InterNode value)?  interNode,TResult Function( Nodes_CommentNode value)?  commentNode,TResult Function( Nodes_DrawingNode value)?  drawingNode,TResult Function( Nodes_ShapeNode value)?  shapeNode,TResult Function( Nodes_FrameNode value)?  frameNode,TResult Function( Nodes_MediaNode value)?  mediaNode,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Nodes_INode() when iNode != null:
return iNode(_that);case Nodes_TaskNode() when taskNode != null:
return taskNode(_that);case Nodes_InterNode() when interNode != null:
return interNode(_that);case Nodes_CommentNode() when commentNode != null:
return commentNode(_that);case Nodes_DrawingNode() when drawingNode != null:
return drawingNode(_that);case Nodes_ShapeNode() when shapeNode != null:
return shapeNode(_that);case Nodes_FrameNode() when frameNode != null:
return frameNode(_that);case Nodes_MediaNode() when mediaNode != null:
return mediaNode(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Nodes_INode value)  iNode,required TResult Function( Nodes_TaskNode value)  taskNode,required TResult Function( Nodes_InterNode value)  interNode,required TResult Function( Nodes_CommentNode value)  commentNode,required TResult Function( Nodes_DrawingNode value)  drawingNode,required TResult Function( Nodes_ShapeNode value)  shapeNode,required TResult Function( Nodes_FrameNode value)  frameNode,required TResult Function( Nodes_MediaNode value)  mediaNode,}){
final _that = this;
switch (_that) {
case Nodes_INode():
return iNode(_that);case Nodes_TaskNode():
return taskNode(_that);case Nodes_InterNode():
return interNode(_that);case Nodes_CommentNode():
return commentNode(_that);case Nodes_DrawingNode():
return drawingNode(_that);case Nodes_ShapeNode():
return shapeNode(_that);case Nodes_FrameNode():
return frameNode(_that);case Nodes_MediaNode():
return mediaNode(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Nodes_INode value)?  iNode,TResult? Function( Nodes_TaskNode value)?  taskNode,TResult? Function( Nodes_InterNode value)?  interNode,TResult? Function( Nodes_CommentNode value)?  commentNode,TResult? Function( Nodes_DrawingNode value)?  drawingNode,TResult? Function( Nodes_ShapeNode value)?  shapeNode,TResult? Function( Nodes_FrameNode value)?  frameNode,TResult? Function( Nodes_MediaNode value)?  mediaNode,}){
final _that = this;
switch (_that) {
case Nodes_INode() when iNode != null:
return iNode(_that);case Nodes_TaskNode() when taskNode != null:
return taskNode(_that);case Nodes_InterNode() when interNode != null:
return interNode(_that);case Nodes_CommentNode() when commentNode != null:
return commentNode(_that);case Nodes_DrawingNode() when drawingNode != null:
return drawingNode(_that);case Nodes_ShapeNode() when shapeNode != null:
return shapeNode(_that);case Nodes_FrameNode() when frameNode != null:
return frameNode(_that);case Nodes_MediaNode() when mediaNode != null:
return mediaNode(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( INode field0)?  iNode,TResult Function( TaskNode field0)?  taskNode,TResult Function( InterNode field0)?  interNode,TResult Function( CommentNode field0)?  commentNode,TResult Function( DrawingNode field0)?  drawingNode,TResult Function( ShapeNode field0)?  shapeNode,TResult Function( FrameNode field0)?  frameNode,TResult Function( MediaNode field0)?  mediaNode,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Nodes_INode() when iNode != null:
return iNode(_that.field0);case Nodes_TaskNode() when taskNode != null:
return taskNode(_that.field0);case Nodes_InterNode() when interNode != null:
return interNode(_that.field0);case Nodes_CommentNode() when commentNode != null:
return commentNode(_that.field0);case Nodes_DrawingNode() when drawingNode != null:
return drawingNode(_that.field0);case Nodes_ShapeNode() when shapeNode != null:
return shapeNode(_that.field0);case Nodes_FrameNode() when frameNode != null:
return frameNode(_that.field0);case Nodes_MediaNode() when mediaNode != null:
return mediaNode(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( INode field0)  iNode,required TResult Function( TaskNode field0)  taskNode,required TResult Function( InterNode field0)  interNode,required TResult Function( CommentNode field0)  commentNode,required TResult Function( DrawingNode field0)  drawingNode,required TResult Function( ShapeNode field0)  shapeNode,required TResult Function( FrameNode field0)  frameNode,required TResult Function( MediaNode field0)  mediaNode,}) {final _that = this;
switch (_that) {
case Nodes_INode():
return iNode(_that.field0);case Nodes_TaskNode():
return taskNode(_that.field0);case Nodes_InterNode():
return interNode(_that.field0);case Nodes_CommentNode():
return commentNode(_that.field0);case Nodes_DrawingNode():
return drawingNode(_that.field0);case Nodes_ShapeNode():
return shapeNode(_that.field0);case Nodes_FrameNode():
return frameNode(_that.field0);case Nodes_MediaNode():
return mediaNode(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( INode field0)?  iNode,TResult? Function( TaskNode field0)?  taskNode,TResult? Function( InterNode field0)?  interNode,TResult? Function( CommentNode field0)?  commentNode,TResult? Function( DrawingNode field0)?  drawingNode,TResult? Function( ShapeNode field0)?  shapeNode,TResult? Function( FrameNode field0)?  frameNode,TResult? Function( MediaNode field0)?  mediaNode,}) {final _that = this;
switch (_that) {
case Nodes_INode() when iNode != null:
return iNode(_that.field0);case Nodes_TaskNode() when taskNode != null:
return taskNode(_that.field0);case Nodes_InterNode() when interNode != null:
return interNode(_that.field0);case Nodes_CommentNode() when commentNode != null:
return commentNode(_that.field0);case Nodes_DrawingNode() when drawingNode != null:
return drawingNode(_that.field0);case Nodes_ShapeNode() when shapeNode != null:
return shapeNode(_that.field0);case Nodes_FrameNode() when frameNode != null:
return frameNode(_that.field0);case Nodes_MediaNode() when mediaNode != null:
return mediaNode(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class Nodes_INode extends Nodes {
  const Nodes_INode(this.field0): super._();
  

@override final  INode field0;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Nodes_INodeCopyWith<Nodes_INode> get copyWith => _$Nodes_INodeCopyWithImpl<Nodes_INode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nodes_INode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Nodes.iNode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Nodes_INodeCopyWith<$Res> implements $NodesCopyWith<$Res> {
  factory $Nodes_INodeCopyWith(Nodes_INode value, $Res Function(Nodes_INode) _then) = _$Nodes_INodeCopyWithImpl;
@useResult
$Res call({
 INode field0
});




}
/// @nodoc
class _$Nodes_INodeCopyWithImpl<$Res>
    implements $Nodes_INodeCopyWith<$Res> {
  _$Nodes_INodeCopyWithImpl(this._self, this._then);

  final Nodes_INode _self;
  final $Res Function(Nodes_INode) _then;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Nodes_INode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as INode,
  ));
}


}

/// @nodoc


class Nodes_TaskNode extends Nodes {
  const Nodes_TaskNode(this.field0): super._();
  

@override final  TaskNode field0;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Nodes_TaskNodeCopyWith<Nodes_TaskNode> get copyWith => _$Nodes_TaskNodeCopyWithImpl<Nodes_TaskNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nodes_TaskNode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Nodes.taskNode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Nodes_TaskNodeCopyWith<$Res> implements $NodesCopyWith<$Res> {
  factory $Nodes_TaskNodeCopyWith(Nodes_TaskNode value, $Res Function(Nodes_TaskNode) _then) = _$Nodes_TaskNodeCopyWithImpl;
@useResult
$Res call({
 TaskNode field0
});




}
/// @nodoc
class _$Nodes_TaskNodeCopyWithImpl<$Res>
    implements $Nodes_TaskNodeCopyWith<$Res> {
  _$Nodes_TaskNodeCopyWithImpl(this._self, this._then);

  final Nodes_TaskNode _self;
  final $Res Function(Nodes_TaskNode) _then;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Nodes_TaskNode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as TaskNode,
  ));
}


}

/// @nodoc


class Nodes_InterNode extends Nodes {
  const Nodes_InterNode(this.field0): super._();
  

@override final  InterNode field0;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Nodes_InterNodeCopyWith<Nodes_InterNode> get copyWith => _$Nodes_InterNodeCopyWithImpl<Nodes_InterNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nodes_InterNode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Nodes.interNode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Nodes_InterNodeCopyWith<$Res> implements $NodesCopyWith<$Res> {
  factory $Nodes_InterNodeCopyWith(Nodes_InterNode value, $Res Function(Nodes_InterNode) _then) = _$Nodes_InterNodeCopyWithImpl;
@useResult
$Res call({
 InterNode field0
});




}
/// @nodoc
class _$Nodes_InterNodeCopyWithImpl<$Res>
    implements $Nodes_InterNodeCopyWith<$Res> {
  _$Nodes_InterNodeCopyWithImpl(this._self, this._then);

  final Nodes_InterNode _self;
  final $Res Function(Nodes_InterNode) _then;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Nodes_InterNode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as InterNode,
  ));
}


}

/// @nodoc


class Nodes_CommentNode extends Nodes {
  const Nodes_CommentNode(this.field0): super._();
  

@override final  CommentNode field0;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Nodes_CommentNodeCopyWith<Nodes_CommentNode> get copyWith => _$Nodes_CommentNodeCopyWithImpl<Nodes_CommentNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nodes_CommentNode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Nodes.commentNode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Nodes_CommentNodeCopyWith<$Res> implements $NodesCopyWith<$Res> {
  factory $Nodes_CommentNodeCopyWith(Nodes_CommentNode value, $Res Function(Nodes_CommentNode) _then) = _$Nodes_CommentNodeCopyWithImpl;
@useResult
$Res call({
 CommentNode field0
});




}
/// @nodoc
class _$Nodes_CommentNodeCopyWithImpl<$Res>
    implements $Nodes_CommentNodeCopyWith<$Res> {
  _$Nodes_CommentNodeCopyWithImpl(this._self, this._then);

  final Nodes_CommentNode _self;
  final $Res Function(Nodes_CommentNode) _then;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Nodes_CommentNode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as CommentNode,
  ));
}


}

/// @nodoc


class Nodes_DrawingNode extends Nodes {
  const Nodes_DrawingNode(this.field0): super._();
  

@override final  DrawingNode field0;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Nodes_DrawingNodeCopyWith<Nodes_DrawingNode> get copyWith => _$Nodes_DrawingNodeCopyWithImpl<Nodes_DrawingNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nodes_DrawingNode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Nodes.drawingNode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Nodes_DrawingNodeCopyWith<$Res> implements $NodesCopyWith<$Res> {
  factory $Nodes_DrawingNodeCopyWith(Nodes_DrawingNode value, $Res Function(Nodes_DrawingNode) _then) = _$Nodes_DrawingNodeCopyWithImpl;
@useResult
$Res call({
 DrawingNode field0
});




}
/// @nodoc
class _$Nodes_DrawingNodeCopyWithImpl<$Res>
    implements $Nodes_DrawingNodeCopyWith<$Res> {
  _$Nodes_DrawingNodeCopyWithImpl(this._self, this._then);

  final Nodes_DrawingNode _self;
  final $Res Function(Nodes_DrawingNode) _then;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Nodes_DrawingNode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as DrawingNode,
  ));
}


}

/// @nodoc


class Nodes_ShapeNode extends Nodes {
  const Nodes_ShapeNode(this.field0): super._();
  

@override final  ShapeNode field0;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Nodes_ShapeNodeCopyWith<Nodes_ShapeNode> get copyWith => _$Nodes_ShapeNodeCopyWithImpl<Nodes_ShapeNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nodes_ShapeNode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Nodes.shapeNode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Nodes_ShapeNodeCopyWith<$Res> implements $NodesCopyWith<$Res> {
  factory $Nodes_ShapeNodeCopyWith(Nodes_ShapeNode value, $Res Function(Nodes_ShapeNode) _then) = _$Nodes_ShapeNodeCopyWithImpl;
@useResult
$Res call({
 ShapeNode field0
});




}
/// @nodoc
class _$Nodes_ShapeNodeCopyWithImpl<$Res>
    implements $Nodes_ShapeNodeCopyWith<$Res> {
  _$Nodes_ShapeNodeCopyWithImpl(this._self, this._then);

  final Nodes_ShapeNode _self;
  final $Res Function(Nodes_ShapeNode) _then;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Nodes_ShapeNode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as ShapeNode,
  ));
}


}

/// @nodoc


class Nodes_FrameNode extends Nodes {
  const Nodes_FrameNode(this.field0): super._();
  

@override final  FrameNode field0;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Nodes_FrameNodeCopyWith<Nodes_FrameNode> get copyWith => _$Nodes_FrameNodeCopyWithImpl<Nodes_FrameNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nodes_FrameNode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Nodes.frameNode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Nodes_FrameNodeCopyWith<$Res> implements $NodesCopyWith<$Res> {
  factory $Nodes_FrameNodeCopyWith(Nodes_FrameNode value, $Res Function(Nodes_FrameNode) _then) = _$Nodes_FrameNodeCopyWithImpl;
@useResult
$Res call({
 FrameNode field0
});




}
/// @nodoc
class _$Nodes_FrameNodeCopyWithImpl<$Res>
    implements $Nodes_FrameNodeCopyWith<$Res> {
  _$Nodes_FrameNodeCopyWithImpl(this._self, this._then);

  final Nodes_FrameNode _self;
  final $Res Function(Nodes_FrameNode) _then;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Nodes_FrameNode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as FrameNode,
  ));
}


}

/// @nodoc


class Nodes_MediaNode extends Nodes {
  const Nodes_MediaNode(this.field0): super._();
  

@override final  MediaNode field0;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Nodes_MediaNodeCopyWith<Nodes_MediaNode> get copyWith => _$Nodes_MediaNodeCopyWithImpl<Nodes_MediaNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nodes_MediaNode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Nodes.mediaNode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Nodes_MediaNodeCopyWith<$Res> implements $NodesCopyWith<$Res> {
  factory $Nodes_MediaNodeCopyWith(Nodes_MediaNode value, $Res Function(Nodes_MediaNode) _then) = _$Nodes_MediaNodeCopyWithImpl;
@useResult
$Res call({
 MediaNode field0
});




}
/// @nodoc
class _$Nodes_MediaNodeCopyWithImpl<$Res>
    implements $Nodes_MediaNodeCopyWith<$Res> {
  _$Nodes_MediaNodeCopyWithImpl(this._self, this._then);

  final Nodes_MediaNode _self;
  final $Res Function(Nodes_MediaNode) _then;

/// Create a copy of Nodes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Nodes_MediaNode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as MediaNode,
  ));
}


}

// dart format on
