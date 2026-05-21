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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NodePatch_Position value)?  position,TResult Function( NodePatch_Size value)?  size,TResult Function( NodePatch_Content value)?  content,TResult Function( NodePatch_IsExpanded value)?  isExpanded,TResult Function( NodePatch_Style value)?  style,TResult Function( NodePatch_Tags value)?  tags,TResult Function( NodePatch_Significance value)?  significance,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that);case NodePatch_Size() when size != null:
return size(_that);case NodePatch_Content() when content != null:
return content(_that);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that);case NodePatch_Style() when style != null:
return style(_that);case NodePatch_Tags() when tags != null:
return tags(_that);case NodePatch_Significance() when significance != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NodePatch_Position value)  position,required TResult Function( NodePatch_Size value)  size,required TResult Function( NodePatch_Content value)  content,required TResult Function( NodePatch_IsExpanded value)  isExpanded,required TResult Function( NodePatch_Style value)  style,required TResult Function( NodePatch_Tags value)  tags,required TResult Function( NodePatch_Significance value)  significance,}){
final _that = this;
switch (_that) {
case NodePatch_Position():
return position(_that);case NodePatch_Size():
return size(_that);case NodePatch_Content():
return content(_that);case NodePatch_IsExpanded():
return isExpanded(_that);case NodePatch_Style():
return style(_that);case NodePatch_Tags():
return tags(_that);case NodePatch_Significance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NodePatch_Position value)?  position,TResult? Function( NodePatch_Size value)?  size,TResult? Function( NodePatch_Content value)?  content,TResult? Function( NodePatch_IsExpanded value)?  isExpanded,TResult? Function( NodePatch_Style value)?  style,TResult? Function( NodePatch_Tags value)?  tags,TResult? Function( NodePatch_Significance value)?  significance,}){
final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that);case NodePatch_Size() when size != null:
return size(_that);case NodePatch_Content() when content != null:
return content(_that);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that);case NodePatch_Style() when style != null:
return style(_that);case NodePatch_Tags() when tags != null:
return tags(_that);case NodePatch_Significance() when significance != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Coordinates field0)?  position,TResult Function( Size field0)?  size,TResult Function( Content field0)?  content,TResult Function( bool field0)?  isExpanded,TResult Function( NodeStyle? field0)?  style,TResult Function( List<String> field0)?  tags,TResult Function( int field0)?  significance,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that.field0);case NodePatch_Size() when size != null:
return size(_that.field0);case NodePatch_Content() when content != null:
return content(_that.field0);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that.field0);case NodePatch_Style() when style != null:
return style(_that.field0);case NodePatch_Tags() when tags != null:
return tags(_that.field0);case NodePatch_Significance() when significance != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Coordinates field0)  position,required TResult Function( Size field0)  size,required TResult Function( Content field0)  content,required TResult Function( bool field0)  isExpanded,required TResult Function( NodeStyle? field0)  style,required TResult Function( List<String> field0)  tags,required TResult Function( int field0)  significance,}) {final _that = this;
switch (_that) {
case NodePatch_Position():
return position(_that.field0);case NodePatch_Size():
return size(_that.field0);case NodePatch_Content():
return content(_that.field0);case NodePatch_IsExpanded():
return isExpanded(_that.field0);case NodePatch_Style():
return style(_that.field0);case NodePatch_Tags():
return tags(_that.field0);case NodePatch_Significance():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Coordinates field0)?  position,TResult? Function( Size field0)?  size,TResult? Function( Content field0)?  content,TResult? Function( bool field0)?  isExpanded,TResult? Function( NodeStyle? field0)?  style,TResult? Function( List<String> field0)?  tags,TResult? Function( int field0)?  significance,}) {final _that = this;
switch (_that) {
case NodePatch_Position() when position != null:
return position(_that.field0);case NodePatch_Size() when size != null:
return size(_that.field0);case NodePatch_Content() when content != null:
return content(_that.field0);case NodePatch_IsExpanded() when isExpanded != null:
return isExpanded(_that.field0);case NodePatch_Style() when style != null:
return style(_that.field0);case NodePatch_Tags() when tags != null:
return tags(_that.field0);case NodePatch_Significance() when significance != null:
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


class NodePatch_Tags extends NodePatch {
  const NodePatch_Tags(final  List<String> field0): _field0 = field0,super._();
  

 final  List<String> _field0;
@override List<String> get field0 {
  if (_field0 is EqualUnmodifiableListView) return _field0;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_field0);
}


/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePatch_TagsCopyWith<NodePatch_Tags> get copyWith => _$NodePatch_TagsCopyWithImpl<NodePatch_Tags>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePatch_Tags&&const DeepCollectionEquality().equals(other._field0, _field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_field0));

@override
String toString() {
  return 'NodePatch.tags(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $NodePatch_TagsCopyWith<$Res> implements $NodePatchCopyWith<$Res> {
  factory $NodePatch_TagsCopyWith(NodePatch_Tags value, $Res Function(NodePatch_Tags) _then) = _$NodePatch_TagsCopyWithImpl;
@useResult
$Res call({
 List<String> field0
});




}
/// @nodoc
class _$NodePatch_TagsCopyWithImpl<$Res>
    implements $NodePatch_TagsCopyWith<$Res> {
  _$NodePatch_TagsCopyWithImpl(this._self, this._then);

  final NodePatch_Tags _self;
  final $Res Function(NodePatch_Tags) _then;

/// Create a copy of NodePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(NodePatch_Tags(
null == field0 ? _self._field0 : field0 // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Nodes_INode value)?  iNode,TResult Function( Nodes_TaskNode value)?  taskNode,TResult Function( Nodes_InterNode value)?  interNode,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Nodes_INode() when iNode != null:
return iNode(_that);case Nodes_TaskNode() when taskNode != null:
return taskNode(_that);case Nodes_InterNode() when interNode != null:
return interNode(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Nodes_INode value)  iNode,required TResult Function( Nodes_TaskNode value)  taskNode,required TResult Function( Nodes_InterNode value)  interNode,}){
final _that = this;
switch (_that) {
case Nodes_INode():
return iNode(_that);case Nodes_TaskNode():
return taskNode(_that);case Nodes_InterNode():
return interNode(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Nodes_INode value)?  iNode,TResult? Function( Nodes_TaskNode value)?  taskNode,TResult? Function( Nodes_InterNode value)?  interNode,}){
final _that = this;
switch (_that) {
case Nodes_INode() when iNode != null:
return iNode(_that);case Nodes_TaskNode() when taskNode != null:
return taskNode(_that);case Nodes_InterNode() when interNode != null:
return interNode(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( INode field0)?  iNode,TResult Function( TaskNode field0)?  taskNode,TResult Function( InterNode field0)?  interNode,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Nodes_INode() when iNode != null:
return iNode(_that.field0);case Nodes_TaskNode() when taskNode != null:
return taskNode(_that.field0);case Nodes_InterNode() when interNode != null:
return interNode(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( INode field0)  iNode,required TResult Function( TaskNode field0)  taskNode,required TResult Function( InterNode field0)  interNode,}) {final _that = this;
switch (_that) {
case Nodes_INode():
return iNode(_that.field0);case Nodes_TaskNode():
return taskNode(_that.field0);case Nodes_InterNode():
return interNode(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( INode field0)?  iNode,TResult? Function( TaskNode field0)?  taskNode,TResult? Function( InterNode field0)?  interNode,}) {final _that = this;
switch (_that) {
case Nodes_INode() when iNode != null:
return iNode(_that.field0);case Nodes_TaskNode() when taskNode != null:
return taskNode(_that.field0);case Nodes_InterNode() when interNode != null:
return interNode(_that.field0);case _:
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

// dart format on
