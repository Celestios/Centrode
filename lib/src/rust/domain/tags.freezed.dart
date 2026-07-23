// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tags.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TagEdge {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TagEdge&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'TagEdge(field0: $field0)';
}


}

/// @nodoc
class $TagEdgeCopyWith<$Res>  {
$TagEdgeCopyWith(TagEdge _, $Res Function(TagEdge) __);
}


/// Adds pattern-matching-related methods to [TagEdge].
extension TagEdgePatterns on TagEdge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TagEdge_Hydrated value)?  hydrated,TResult Function( TagEdge_Pointer value)?  pointer,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TagEdge_Hydrated() when hydrated != null:
return hydrated(_that);case TagEdge_Pointer() when pointer != null:
return pointer(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TagEdge_Hydrated value)  hydrated,required TResult Function( TagEdge_Pointer value)  pointer,}){
final _that = this;
switch (_that) {
case TagEdge_Hydrated():
return hydrated(_that);case TagEdge_Pointer():
return pointer(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TagEdge_Hydrated value)?  hydrated,TResult? Function( TagEdge_Pointer value)?  pointer,}){
final _that = this;
switch (_that) {
case TagEdge_Hydrated() when hydrated != null:
return hydrated(_that);case TagEdge_Pointer() when pointer != null:
return pointer(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Tag field0)?  hydrated,TResult Function( TypedRecordId field0)?  pointer,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TagEdge_Hydrated() when hydrated != null:
return hydrated(_that.field0);case TagEdge_Pointer() when pointer != null:
return pointer(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Tag field0)  hydrated,required TResult Function( TypedRecordId field0)  pointer,}) {final _that = this;
switch (_that) {
case TagEdge_Hydrated():
return hydrated(_that.field0);case TagEdge_Pointer():
return pointer(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Tag field0)?  hydrated,TResult? Function( TypedRecordId field0)?  pointer,}) {final _that = this;
switch (_that) {
case TagEdge_Hydrated() when hydrated != null:
return hydrated(_that.field0);case TagEdge_Pointer() when pointer != null:
return pointer(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class TagEdge_Hydrated extends TagEdge {
  const TagEdge_Hydrated(this.field0): super._();
  

@override final  Tag field0;

/// Create a copy of TagEdge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagEdge_HydratedCopyWith<TagEdge_Hydrated> get copyWith => _$TagEdge_HydratedCopyWithImpl<TagEdge_Hydrated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TagEdge_Hydrated&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'TagEdge.hydrated(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $TagEdge_HydratedCopyWith<$Res> implements $TagEdgeCopyWith<$Res> {
  factory $TagEdge_HydratedCopyWith(TagEdge_Hydrated value, $Res Function(TagEdge_Hydrated) _then) = _$TagEdge_HydratedCopyWithImpl;
@useResult
$Res call({
 Tag field0
});




}
/// @nodoc
class _$TagEdge_HydratedCopyWithImpl<$Res>
    implements $TagEdge_HydratedCopyWith<$Res> {
  _$TagEdge_HydratedCopyWithImpl(this._self, this._then);

  final TagEdge_Hydrated _self;
  final $Res Function(TagEdge_Hydrated) _then;

/// Create a copy of TagEdge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(TagEdge_Hydrated(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Tag,
  ));
}


}

/// @nodoc


class TagEdge_Pointer extends TagEdge {
  const TagEdge_Pointer(this.field0): super._();
  

@override final  TypedRecordId field0;

/// Create a copy of TagEdge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagEdge_PointerCopyWith<TagEdge_Pointer> get copyWith => _$TagEdge_PointerCopyWithImpl<TagEdge_Pointer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TagEdge_Pointer&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'TagEdge.pointer(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $TagEdge_PointerCopyWith<$Res> implements $TagEdgeCopyWith<$Res> {
  factory $TagEdge_PointerCopyWith(TagEdge_Pointer value, $Res Function(TagEdge_Pointer) _then) = _$TagEdge_PointerCopyWithImpl;
@useResult
$Res call({
 TypedRecordId field0
});




}
/// @nodoc
class _$TagEdge_PointerCopyWithImpl<$Res>
    implements $TagEdge_PointerCopyWith<$Res> {
  _$TagEdge_PointerCopyWithImpl(this._self, this._then);

  final TagEdge_Pointer _self;
  final $Res Function(TagEdge_Pointer) _then;

/// Create a copy of TagEdge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(TagEdge_Pointer(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as TypedRecordId,
  ));
}


}

// dart format on
