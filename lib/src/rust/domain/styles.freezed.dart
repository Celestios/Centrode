// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'styles.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NodeStyle {

 int get bgColor; int get strokeColor; int get strokeWidth; String get fontFamily; double get fontSize; String get shape; int get width; int get height;
/// Create a copy of NodeStyle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeStyleCopyWith<NodeStyle> get copyWith => _$NodeStyleCopyWithImpl<NodeStyle>(this as NodeStyle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeStyle&&(identical(other.bgColor, bgColor) || other.bgColor == bgColor)&&(identical(other.strokeColor, strokeColor) || other.strokeColor == strokeColor)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,bgColor,strokeColor,strokeWidth,fontFamily,fontSize,shape,width,height);

@override
String toString() {
  return 'NodeStyle(bgColor: $bgColor, strokeColor: $strokeColor, strokeWidth: $strokeWidth, fontFamily: $fontFamily, fontSize: $fontSize, shape: $shape, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $NodeStyleCopyWith<$Res>  {
  factory $NodeStyleCopyWith(NodeStyle value, $Res Function(NodeStyle) _then) = _$NodeStyleCopyWithImpl;
@useResult
$Res call({
 int bgColor, int strokeColor, int strokeWidth, String fontFamily, double fontSize, String shape, int width, int height
});




}
/// @nodoc
class _$NodeStyleCopyWithImpl<$Res>
    implements $NodeStyleCopyWith<$Res> {
  _$NodeStyleCopyWithImpl(this._self, this._then);

  final NodeStyle _self;
  final $Res Function(NodeStyle) _then;

/// Create a copy of NodeStyle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bgColor = null,Object? strokeColor = null,Object? strokeWidth = null,Object? fontFamily = null,Object? fontSize = null,Object? shape = null,Object? width = null,Object? height = null,}) {
  return _then(_self.copyWith(
bgColor: null == bgColor ? _self.bgColor : bgColor // ignore: cast_nullable_to_non_nullable
as int,strokeColor: null == strokeColor ? _self.strokeColor : strokeColor // ignore: cast_nullable_to_non_nullable
as int,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as int,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NodeStyle].
extension NodeStylePatterns on NodeStyle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NodeStyle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NodeStyle() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NodeStyle value)  $default,){
final _that = this;
switch (_that) {
case _NodeStyle():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NodeStyle value)?  $default,){
final _that = this;
switch (_that) {
case _NodeStyle() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NodeStyle() when $default != null:
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _NodeStyle():
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.width,_that.height);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _NodeStyle() when $default != null:
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _NodeStyle implements NodeStyle {
  const _NodeStyle({required this.bgColor, required this.strokeColor, required this.strokeWidth, required this.fontFamily, required this.fontSize, required this.shape, required this.width, required this.height});
  

@override final  int bgColor;
@override final  int strokeColor;
@override final  int strokeWidth;
@override final  String fontFamily;
@override final  double fontSize;
@override final  String shape;
@override final  int width;
@override final  int height;

/// Create a copy of NodeStyle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NodeStyleCopyWith<_NodeStyle> get copyWith => __$NodeStyleCopyWithImpl<_NodeStyle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NodeStyle&&(identical(other.bgColor, bgColor) || other.bgColor == bgColor)&&(identical(other.strokeColor, strokeColor) || other.strokeColor == strokeColor)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,bgColor,strokeColor,strokeWidth,fontFamily,fontSize,shape,width,height);

@override
String toString() {
  return 'NodeStyle(bgColor: $bgColor, strokeColor: $strokeColor, strokeWidth: $strokeWidth, fontFamily: $fontFamily, fontSize: $fontSize, shape: $shape, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$NodeStyleCopyWith<$Res> implements $NodeStyleCopyWith<$Res> {
  factory _$NodeStyleCopyWith(_NodeStyle value, $Res Function(_NodeStyle) _then) = __$NodeStyleCopyWithImpl;
@override @useResult
$Res call({
 int bgColor, int strokeColor, int strokeWidth, String fontFamily, double fontSize, String shape, int width, int height
});




}
/// @nodoc
class __$NodeStyleCopyWithImpl<$Res>
    implements _$NodeStyleCopyWith<$Res> {
  __$NodeStyleCopyWithImpl(this._self, this._then);

  final _NodeStyle _self;
  final $Res Function(_NodeStyle) _then;

/// Create a copy of NodeStyle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bgColor = null,Object? strokeColor = null,Object? strokeWidth = null,Object? fontFamily = null,Object? fontSize = null,Object? shape = null,Object? width = null,Object? height = null,}) {
  return _then(_NodeStyle(
bgColor: null == bgColor ? _self.bgColor : bgColor // ignore: cast_nullable_to_non_nullable
as int,strokeColor: null == strokeColor ? _self.strokeColor : strokeColor // ignore: cast_nullable_to_non_nullable
as int,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as int,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$RelationStyle {

 int get bgColor; int get strokeColor; int get strokeWidth; String get fontFamily; double get fontSize; String get shape; String get arrowType; double get arrowSize; int get width; int get height;
/// Create a copy of RelationStyle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationStyleCopyWith<RelationStyle> get copyWith => _$RelationStyleCopyWithImpl<RelationStyle>(this as RelationStyle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationStyle&&(identical(other.bgColor, bgColor) || other.bgColor == bgColor)&&(identical(other.strokeColor, strokeColor) || other.strokeColor == strokeColor)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.arrowType, arrowType) || other.arrowType == arrowType)&&(identical(other.arrowSize, arrowSize) || other.arrowSize == arrowSize)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,bgColor,strokeColor,strokeWidth,fontFamily,fontSize,shape,arrowType,arrowSize,width,height);

@override
String toString() {
  return 'RelationStyle(bgColor: $bgColor, strokeColor: $strokeColor, strokeWidth: $strokeWidth, fontFamily: $fontFamily, fontSize: $fontSize, shape: $shape, arrowType: $arrowType, arrowSize: $arrowSize, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $RelationStyleCopyWith<$Res>  {
  factory $RelationStyleCopyWith(RelationStyle value, $Res Function(RelationStyle) _then) = _$RelationStyleCopyWithImpl;
@useResult
$Res call({
 int bgColor, int strokeColor, int strokeWidth, String fontFamily, double fontSize, String shape, String arrowType, double arrowSize, int width, int height
});




}
/// @nodoc
class _$RelationStyleCopyWithImpl<$Res>
    implements $RelationStyleCopyWith<$Res> {
  _$RelationStyleCopyWithImpl(this._self, this._then);

  final RelationStyle _self;
  final $Res Function(RelationStyle) _then;

/// Create a copy of RelationStyle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bgColor = null,Object? strokeColor = null,Object? strokeWidth = null,Object? fontFamily = null,Object? fontSize = null,Object? shape = null,Object? arrowType = null,Object? arrowSize = null,Object? width = null,Object? height = null,}) {
  return _then(_self.copyWith(
bgColor: null == bgColor ? _self.bgColor : bgColor // ignore: cast_nullable_to_non_nullable
as int,strokeColor: null == strokeColor ? _self.strokeColor : strokeColor // ignore: cast_nullable_to_non_nullable
as int,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as int,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as String,arrowType: null == arrowType ? _self.arrowType : arrowType // ignore: cast_nullable_to_non_nullable
as String,arrowSize: null == arrowSize ? _self.arrowSize : arrowSize // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RelationStyle].
extension RelationStylePatterns on RelationStyle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RelationStyle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RelationStyle() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RelationStyle value)  $default,){
final _that = this;
switch (_that) {
case _RelationStyle():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RelationStyle value)?  $default,){
final _that = this;
switch (_that) {
case _RelationStyle() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  String arrowType,  double arrowSize,  int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RelationStyle() when $default != null:
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.arrowType,_that.arrowSize,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  String arrowType,  double arrowSize,  int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _RelationStyle():
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.arrowType,_that.arrowSize,_that.width,_that.height);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  String arrowType,  double arrowSize,  int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _RelationStyle() when $default != null:
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.arrowType,_that.arrowSize,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _RelationStyle implements RelationStyle {
  const _RelationStyle({required this.bgColor, required this.strokeColor, required this.strokeWidth, required this.fontFamily, required this.fontSize, required this.shape, required this.arrowType, required this.arrowSize, required this.width, required this.height});
  

@override final  int bgColor;
@override final  int strokeColor;
@override final  int strokeWidth;
@override final  String fontFamily;
@override final  double fontSize;
@override final  String shape;
@override final  String arrowType;
@override final  double arrowSize;
@override final  int width;
@override final  int height;

/// Create a copy of RelationStyle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelationStyleCopyWith<_RelationStyle> get copyWith => __$RelationStyleCopyWithImpl<_RelationStyle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RelationStyle&&(identical(other.bgColor, bgColor) || other.bgColor == bgColor)&&(identical(other.strokeColor, strokeColor) || other.strokeColor == strokeColor)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.arrowType, arrowType) || other.arrowType == arrowType)&&(identical(other.arrowSize, arrowSize) || other.arrowSize == arrowSize)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,bgColor,strokeColor,strokeWidth,fontFamily,fontSize,shape,arrowType,arrowSize,width,height);

@override
String toString() {
  return 'RelationStyle(bgColor: $bgColor, strokeColor: $strokeColor, strokeWidth: $strokeWidth, fontFamily: $fontFamily, fontSize: $fontSize, shape: $shape, arrowType: $arrowType, arrowSize: $arrowSize, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$RelationStyleCopyWith<$Res> implements $RelationStyleCopyWith<$Res> {
  factory _$RelationStyleCopyWith(_RelationStyle value, $Res Function(_RelationStyle) _then) = __$RelationStyleCopyWithImpl;
@override @useResult
$Res call({
 int bgColor, int strokeColor, int strokeWidth, String fontFamily, double fontSize, String shape, String arrowType, double arrowSize, int width, int height
});




}
/// @nodoc
class __$RelationStyleCopyWithImpl<$Res>
    implements _$RelationStyleCopyWith<$Res> {
  __$RelationStyleCopyWithImpl(this._self, this._then);

  final _RelationStyle _self;
  final $Res Function(_RelationStyle) _then;

/// Create a copy of RelationStyle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bgColor = null,Object? strokeColor = null,Object? strokeWidth = null,Object? fontFamily = null,Object? fontSize = null,Object? shape = null,Object? arrowType = null,Object? arrowSize = null,Object? width = null,Object? height = null,}) {
  return _then(_RelationStyle(
bgColor: null == bgColor ? _self.bgColor : bgColor // ignore: cast_nullable_to_non_nullable
as int,strokeColor: null == strokeColor ? _self.strokeColor : strokeColor // ignore: cast_nullable_to_non_nullable
as int,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as int,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as String,arrowType: null == arrowType ? _self.arrowType : arrowType // ignore: cast_nullable_to_non_nullable
as String,arrowSize: null == arrowSize ? _self.arrowSize : arrowSize // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
