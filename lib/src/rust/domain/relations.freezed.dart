// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relations.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
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

// dart format on
