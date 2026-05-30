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
mixin _$NodeLayout {

 String get strategyType;
/// Create a copy of NodeLayout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeLayoutCopyWith<NodeLayout> get copyWith => _$NodeLayoutCopyWithImpl<NodeLayout>(this as NodeLayout, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeLayout&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType));
}


@override
int get hashCode => Object.hash(runtimeType,strategyType);

@override
String toString() {
  return 'NodeLayout(strategyType: $strategyType)';
}


}

/// @nodoc
abstract mixin class $NodeLayoutCopyWith<$Res>  {
  factory $NodeLayoutCopyWith(NodeLayout value, $Res Function(NodeLayout) _then) = _$NodeLayoutCopyWithImpl;
@useResult
$Res call({
 String strategyType
});




}
/// @nodoc
class _$NodeLayoutCopyWithImpl<$Res>
    implements $NodeLayoutCopyWith<$Res> {
  _$NodeLayoutCopyWithImpl(this._self, this._then);

  final NodeLayout _self;
  final $Res Function(NodeLayout) _then;

/// Create a copy of NodeLayout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? strategyType = null,}) {
  return _then(_self.copyWith(
strategyType: null == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NodeLayout].
extension NodeLayoutPatterns on NodeLayout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NodeLayout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NodeLayout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NodeLayout value)  $default,){
final _that = this;
switch (_that) {
case _NodeLayout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NodeLayout value)?  $default,){
final _that = this;
switch (_that) {
case _NodeLayout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String strategyType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NodeLayout() when $default != null:
return $default(_that.strategyType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String strategyType)  $default,) {final _that = this;
switch (_that) {
case _NodeLayout():
return $default(_that.strategyType);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String strategyType)?  $default,) {final _that = this;
switch (_that) {
case _NodeLayout() when $default != null:
return $default(_that.strategyType);case _:
  return null;

}
}

}

/// @nodoc


class _NodeLayout implements NodeLayout {
  const _NodeLayout({required this.strategyType});
  

@override final  String strategyType;

/// Create a copy of NodeLayout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NodeLayoutCopyWith<_NodeLayout> get copyWith => __$NodeLayoutCopyWithImpl<_NodeLayout>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NodeLayout&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType));
}


@override
int get hashCode => Object.hash(runtimeType,strategyType);

@override
String toString() {
  return 'NodeLayout(strategyType: $strategyType)';
}


}

/// @nodoc
abstract mixin class _$NodeLayoutCopyWith<$Res> implements $NodeLayoutCopyWith<$Res> {
  factory _$NodeLayoutCopyWith(_NodeLayout value, $Res Function(_NodeLayout) _then) = __$NodeLayoutCopyWithImpl;
@override @useResult
$Res call({
 String strategyType
});




}
/// @nodoc
class __$NodeLayoutCopyWithImpl<$Res>
    implements _$NodeLayoutCopyWith<$Res> {
  __$NodeLayoutCopyWithImpl(this._self, this._then);

  final _NodeLayout _self;
  final $Res Function(_NodeLayout) _then;

/// Create a copy of NodeLayout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? strategyType = null,}) {
  return _then(_NodeLayout(
strategyType: null == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$NodeStyle {

 int get bgColor; int get strokeColor; int get strokeWidth; String get fontFamily; double get fontSize; String get shape; int get width; int get height; int get textColor; double get borderRadius; double get padding; int get shadowColor; double get shadowBlur; double get shadowSpread; double get shadowOffsetX; double get shadowOffsetY; String get strategyType;
/// Create a copy of NodeStyle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeStyleCopyWith<NodeStyle> get copyWith => _$NodeStyleCopyWithImpl<NodeStyle>(this as NodeStyle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeStyle&&(identical(other.bgColor, bgColor) || other.bgColor == bgColor)&&(identical(other.strokeColor, strokeColor) || other.strokeColor == strokeColor)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.borderRadius, borderRadius) || other.borderRadius == borderRadius)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.shadowColor, shadowColor) || other.shadowColor == shadowColor)&&(identical(other.shadowBlur, shadowBlur) || other.shadowBlur == shadowBlur)&&(identical(other.shadowSpread, shadowSpread) || other.shadowSpread == shadowSpread)&&(identical(other.shadowOffsetX, shadowOffsetX) || other.shadowOffsetX == shadowOffsetX)&&(identical(other.shadowOffsetY, shadowOffsetY) || other.shadowOffsetY == shadowOffsetY)&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType));
}


@override
int get hashCode => Object.hash(runtimeType,bgColor,strokeColor,strokeWidth,fontFamily,fontSize,shape,width,height,textColor,borderRadius,padding,shadowColor,shadowBlur,shadowSpread,shadowOffsetX,shadowOffsetY,strategyType);

@override
String toString() {
  return 'NodeStyle(bgColor: $bgColor, strokeColor: $strokeColor, strokeWidth: $strokeWidth, fontFamily: $fontFamily, fontSize: $fontSize, shape: $shape, width: $width, height: $height, textColor: $textColor, borderRadius: $borderRadius, padding: $padding, shadowColor: $shadowColor, shadowBlur: $shadowBlur, shadowSpread: $shadowSpread, shadowOffsetX: $shadowOffsetX, shadowOffsetY: $shadowOffsetY, strategyType: $strategyType)';
}


}

/// @nodoc
abstract mixin class $NodeStyleCopyWith<$Res>  {
  factory $NodeStyleCopyWith(NodeStyle value, $Res Function(NodeStyle) _then) = _$NodeStyleCopyWithImpl;
@useResult
$Res call({
 int bgColor, int strokeColor, int strokeWidth, String fontFamily, double fontSize, String shape, int width, int height, int textColor, double borderRadius, double padding, int shadowColor, double shadowBlur, double shadowSpread, double shadowOffsetX, double shadowOffsetY, String strategyType
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
@pragma('vm:prefer-inline') @override $Res call({Object? bgColor = null,Object? strokeColor = null,Object? strokeWidth = null,Object? fontFamily = null,Object? fontSize = null,Object? shape = null,Object? width = null,Object? height = null,Object? textColor = null,Object? borderRadius = null,Object? padding = null,Object? shadowColor = null,Object? shadowBlur = null,Object? shadowSpread = null,Object? shadowOffsetX = null,Object? shadowOffsetY = null,Object? strategyType = null,}) {
  return _then(_self.copyWith(
bgColor: null == bgColor ? _self.bgColor : bgColor // ignore: cast_nullable_to_non_nullable
as int,strokeColor: null == strokeColor ? _self.strokeColor : strokeColor // ignore: cast_nullable_to_non_nullable
as int,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as int,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as int,borderRadius: null == borderRadius ? _self.borderRadius : borderRadius // ignore: cast_nullable_to_non_nullable
as double,padding: null == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as double,shadowColor: null == shadowColor ? _self.shadowColor : shadowColor // ignore: cast_nullable_to_non_nullable
as int,shadowBlur: null == shadowBlur ? _self.shadowBlur : shadowBlur // ignore: cast_nullable_to_non_nullable
as double,shadowSpread: null == shadowSpread ? _self.shadowSpread : shadowSpread // ignore: cast_nullable_to_non_nullable
as double,shadowOffsetX: null == shadowOffsetX ? _self.shadowOffsetX : shadowOffsetX // ignore: cast_nullable_to_non_nullable
as double,shadowOffsetY: null == shadowOffsetY ? _self.shadowOffsetY : shadowOffsetY // ignore: cast_nullable_to_non_nullable
as double,strategyType: null == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  int width,  int height,  int textColor,  double borderRadius,  double padding,  int shadowColor,  double shadowBlur,  double shadowSpread,  double shadowOffsetX,  double shadowOffsetY,  String strategyType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NodeStyle() when $default != null:
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.width,_that.height,_that.textColor,_that.borderRadius,_that.padding,_that.shadowColor,_that.shadowBlur,_that.shadowSpread,_that.shadowOffsetX,_that.shadowOffsetY,_that.strategyType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  int width,  int height,  int textColor,  double borderRadius,  double padding,  int shadowColor,  double shadowBlur,  double shadowSpread,  double shadowOffsetX,  double shadowOffsetY,  String strategyType)  $default,) {final _that = this;
switch (_that) {
case _NodeStyle():
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.width,_that.height,_that.textColor,_that.borderRadius,_that.padding,_that.shadowColor,_that.shadowBlur,_that.shadowSpread,_that.shadowOffsetX,_that.shadowOffsetY,_that.strategyType);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  int width,  int height,  int textColor,  double borderRadius,  double padding,  int shadowColor,  double shadowBlur,  double shadowSpread,  double shadowOffsetX,  double shadowOffsetY,  String strategyType)?  $default,) {final _that = this;
switch (_that) {
case _NodeStyle() when $default != null:
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.width,_that.height,_that.textColor,_that.borderRadius,_that.padding,_that.shadowColor,_that.shadowBlur,_that.shadowSpread,_that.shadowOffsetX,_that.shadowOffsetY,_that.strategyType);case _:
  return null;

}
}

}

/// @nodoc


class _NodeStyle implements NodeStyle {
  const _NodeStyle({required this.bgColor, required this.strokeColor, required this.strokeWidth, required this.fontFamily, required this.fontSize, required this.shape, required this.width, required this.height, required this.textColor, required this.borderRadius, required this.padding, required this.shadowColor, required this.shadowBlur, required this.shadowSpread, required this.shadowOffsetX, required this.shadowOffsetY, required this.strategyType});
  

@override final  int bgColor;
@override final  int strokeColor;
@override final  int strokeWidth;
@override final  String fontFamily;
@override final  double fontSize;
@override final  String shape;
@override final  int width;
@override final  int height;
@override final  int textColor;
@override final  double borderRadius;
@override final  double padding;
@override final  int shadowColor;
@override final  double shadowBlur;
@override final  double shadowSpread;
@override final  double shadowOffsetX;
@override final  double shadowOffsetY;
@override final  String strategyType;

/// Create a copy of NodeStyle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NodeStyleCopyWith<_NodeStyle> get copyWith => __$NodeStyleCopyWithImpl<_NodeStyle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NodeStyle&&(identical(other.bgColor, bgColor) || other.bgColor == bgColor)&&(identical(other.strokeColor, strokeColor) || other.strokeColor == strokeColor)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.borderRadius, borderRadius) || other.borderRadius == borderRadius)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.shadowColor, shadowColor) || other.shadowColor == shadowColor)&&(identical(other.shadowBlur, shadowBlur) || other.shadowBlur == shadowBlur)&&(identical(other.shadowSpread, shadowSpread) || other.shadowSpread == shadowSpread)&&(identical(other.shadowOffsetX, shadowOffsetX) || other.shadowOffsetX == shadowOffsetX)&&(identical(other.shadowOffsetY, shadowOffsetY) || other.shadowOffsetY == shadowOffsetY)&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType));
}


@override
int get hashCode => Object.hash(runtimeType,bgColor,strokeColor,strokeWidth,fontFamily,fontSize,shape,width,height,textColor,borderRadius,padding,shadowColor,shadowBlur,shadowSpread,shadowOffsetX,shadowOffsetY,strategyType);

@override
String toString() {
  return 'NodeStyle(bgColor: $bgColor, strokeColor: $strokeColor, strokeWidth: $strokeWidth, fontFamily: $fontFamily, fontSize: $fontSize, shape: $shape, width: $width, height: $height, textColor: $textColor, borderRadius: $borderRadius, padding: $padding, shadowColor: $shadowColor, shadowBlur: $shadowBlur, shadowSpread: $shadowSpread, shadowOffsetX: $shadowOffsetX, shadowOffsetY: $shadowOffsetY, strategyType: $strategyType)';
}


}

/// @nodoc
abstract mixin class _$NodeStyleCopyWith<$Res> implements $NodeStyleCopyWith<$Res> {
  factory _$NodeStyleCopyWith(_NodeStyle value, $Res Function(_NodeStyle) _then) = __$NodeStyleCopyWithImpl;
@override @useResult
$Res call({
 int bgColor, int strokeColor, int strokeWidth, String fontFamily, double fontSize, String shape, int width, int height, int textColor, double borderRadius, double padding, int shadowColor, double shadowBlur, double shadowSpread, double shadowOffsetX, double shadowOffsetY, String strategyType
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
@override @pragma('vm:prefer-inline') $Res call({Object? bgColor = null,Object? strokeColor = null,Object? strokeWidth = null,Object? fontFamily = null,Object? fontSize = null,Object? shape = null,Object? width = null,Object? height = null,Object? textColor = null,Object? borderRadius = null,Object? padding = null,Object? shadowColor = null,Object? shadowBlur = null,Object? shadowSpread = null,Object? shadowOffsetX = null,Object? shadowOffsetY = null,Object? strategyType = null,}) {
  return _then(_NodeStyle(
bgColor: null == bgColor ? _self.bgColor : bgColor // ignore: cast_nullable_to_non_nullable
as int,strokeColor: null == strokeColor ? _self.strokeColor : strokeColor // ignore: cast_nullable_to_non_nullable
as int,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as int,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as int,borderRadius: null == borderRadius ? _self.borderRadius : borderRadius // ignore: cast_nullable_to_non_nullable
as double,padding: null == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as double,shadowColor: null == shadowColor ? _self.shadowColor : shadowColor // ignore: cast_nullable_to_non_nullable
as int,shadowBlur: null == shadowBlur ? _self.shadowBlur : shadowBlur // ignore: cast_nullable_to_non_nullable
as double,shadowSpread: null == shadowSpread ? _self.shadowSpread : shadowSpread // ignore: cast_nullable_to_non_nullable
as double,shadowOffsetX: null == shadowOffsetX ? _self.shadowOffsetX : shadowOffsetX // ignore: cast_nullable_to_non_nullable
as double,shadowOffsetY: null == shadowOffsetY ? _self.shadowOffsetY : shadowOffsetY // ignore: cast_nullable_to_non_nullable
as double,strategyType: null == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RelationLayout {

 String get fromSide; String get toSide; String get strategyType;
/// Create a copy of RelationLayout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationLayoutCopyWith<RelationLayout> get copyWith => _$RelationLayoutCopyWithImpl<RelationLayout>(this as RelationLayout, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationLayout&&(identical(other.fromSide, fromSide) || other.fromSide == fromSide)&&(identical(other.toSide, toSide) || other.toSide == toSide)&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType));
}


@override
int get hashCode => Object.hash(runtimeType,fromSide,toSide,strategyType);

@override
String toString() {
  return 'RelationLayout(fromSide: $fromSide, toSide: $toSide, strategyType: $strategyType)';
}


}

/// @nodoc
abstract mixin class $RelationLayoutCopyWith<$Res>  {
  factory $RelationLayoutCopyWith(RelationLayout value, $Res Function(RelationLayout) _then) = _$RelationLayoutCopyWithImpl;
@useResult
$Res call({
 String fromSide, String toSide, String strategyType
});




}
/// @nodoc
class _$RelationLayoutCopyWithImpl<$Res>
    implements $RelationLayoutCopyWith<$Res> {
  _$RelationLayoutCopyWithImpl(this._self, this._then);

  final RelationLayout _self;
  final $Res Function(RelationLayout) _then;

/// Create a copy of RelationLayout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fromSide = null,Object? toSide = null,Object? strategyType = null,}) {
  return _then(_self.copyWith(
fromSide: null == fromSide ? _self.fromSide : fromSide // ignore: cast_nullable_to_non_nullable
as String,toSide: null == toSide ? _self.toSide : toSide // ignore: cast_nullable_to_non_nullable
as String,strategyType: null == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RelationLayout].
extension RelationLayoutPatterns on RelationLayout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RelationLayout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RelationLayout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RelationLayout value)  $default,){
final _that = this;
switch (_that) {
case _RelationLayout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RelationLayout value)?  $default,){
final _that = this;
switch (_that) {
case _RelationLayout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fromSide,  String toSide,  String strategyType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RelationLayout() when $default != null:
return $default(_that.fromSide,_that.toSide,_that.strategyType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fromSide,  String toSide,  String strategyType)  $default,) {final _that = this;
switch (_that) {
case _RelationLayout():
return $default(_that.fromSide,_that.toSide,_that.strategyType);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fromSide,  String toSide,  String strategyType)?  $default,) {final _that = this;
switch (_that) {
case _RelationLayout() when $default != null:
return $default(_that.fromSide,_that.toSide,_that.strategyType);case _:
  return null;

}
}

}

/// @nodoc


class _RelationLayout implements RelationLayout {
  const _RelationLayout({required this.fromSide, required this.toSide, required this.strategyType});
  

@override final  String fromSide;
@override final  String toSide;
@override final  String strategyType;

/// Create a copy of RelationLayout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelationLayoutCopyWith<_RelationLayout> get copyWith => __$RelationLayoutCopyWithImpl<_RelationLayout>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RelationLayout&&(identical(other.fromSide, fromSide) || other.fromSide == fromSide)&&(identical(other.toSide, toSide) || other.toSide == toSide)&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType));
}


@override
int get hashCode => Object.hash(runtimeType,fromSide,toSide,strategyType);

@override
String toString() {
  return 'RelationLayout(fromSide: $fromSide, toSide: $toSide, strategyType: $strategyType)';
}


}

/// @nodoc
abstract mixin class _$RelationLayoutCopyWith<$Res> implements $RelationLayoutCopyWith<$Res> {
  factory _$RelationLayoutCopyWith(_RelationLayout value, $Res Function(_RelationLayout) _then) = __$RelationLayoutCopyWithImpl;
@override @useResult
$Res call({
 String fromSide, String toSide, String strategyType
});




}
/// @nodoc
class __$RelationLayoutCopyWithImpl<$Res>
    implements _$RelationLayoutCopyWith<$Res> {
  __$RelationLayoutCopyWithImpl(this._self, this._then);

  final _RelationLayout _self;
  final $Res Function(_RelationLayout) _then;

/// Create a copy of RelationLayout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fromSide = null,Object? toSide = null,Object? strategyType = null,}) {
  return _then(_RelationLayout(
fromSide: null == fromSide ? _self.fromSide : fromSide // ignore: cast_nullable_to_non_nullable
as String,toSide: null == toSide ? _self.toSide : toSide // ignore: cast_nullable_to_non_nullable
as String,strategyType: null == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RelationStyle {

 int get bgColor; int get strokeColor; int get strokeWidth; String get fontFamily; double get fontSize; String get shape; String get arrowType; double get arrowSize; int get width; int get height; int get textColor; int get shadowColor; double get shadowBlur; double get shadowOffsetX; double get shadowOffsetY; String get strategyType; String get strokePattern;
/// Create a copy of RelationStyle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationStyleCopyWith<RelationStyle> get copyWith => _$RelationStyleCopyWithImpl<RelationStyle>(this as RelationStyle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationStyle&&(identical(other.bgColor, bgColor) || other.bgColor == bgColor)&&(identical(other.strokeColor, strokeColor) || other.strokeColor == strokeColor)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.arrowType, arrowType) || other.arrowType == arrowType)&&(identical(other.arrowSize, arrowSize) || other.arrowSize == arrowSize)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.shadowColor, shadowColor) || other.shadowColor == shadowColor)&&(identical(other.shadowBlur, shadowBlur) || other.shadowBlur == shadowBlur)&&(identical(other.shadowOffsetX, shadowOffsetX) || other.shadowOffsetX == shadowOffsetX)&&(identical(other.shadowOffsetY, shadowOffsetY) || other.shadowOffsetY == shadowOffsetY)&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType)&&(identical(other.strokePattern, strokePattern) || other.strokePattern == strokePattern));
}


@override
int get hashCode => Object.hash(runtimeType,bgColor,strokeColor,strokeWidth,fontFamily,fontSize,shape,arrowType,arrowSize,width,height,textColor,shadowColor,shadowBlur,shadowOffsetX,shadowOffsetY,strategyType,strokePattern);

@override
String toString() {
  return 'RelationStyle(bgColor: $bgColor, strokeColor: $strokeColor, strokeWidth: $strokeWidth, fontFamily: $fontFamily, fontSize: $fontSize, shape: $shape, arrowType: $arrowType, arrowSize: $arrowSize, width: $width, height: $height, textColor: $textColor, shadowColor: $shadowColor, shadowBlur: $shadowBlur, shadowOffsetX: $shadowOffsetX, shadowOffsetY: $shadowOffsetY, strategyType: $strategyType, strokePattern: $strokePattern)';
}


}

/// @nodoc
abstract mixin class $RelationStyleCopyWith<$Res>  {
  factory $RelationStyleCopyWith(RelationStyle value, $Res Function(RelationStyle) _then) = _$RelationStyleCopyWithImpl;
@useResult
$Res call({
 int bgColor, int strokeColor, int strokeWidth, String fontFamily, double fontSize, String shape, String arrowType, double arrowSize, int width, int height, int textColor, int shadowColor, double shadowBlur, double shadowOffsetX, double shadowOffsetY, String strategyType, String strokePattern
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
@pragma('vm:prefer-inline') @override $Res call({Object? bgColor = null,Object? strokeColor = null,Object? strokeWidth = null,Object? fontFamily = null,Object? fontSize = null,Object? shape = null,Object? arrowType = null,Object? arrowSize = null,Object? width = null,Object? height = null,Object? textColor = null,Object? shadowColor = null,Object? shadowBlur = null,Object? shadowOffsetX = null,Object? shadowOffsetY = null,Object? strategyType = null,Object? strokePattern = null,}) {
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
as int,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as int,shadowColor: null == shadowColor ? _self.shadowColor : shadowColor // ignore: cast_nullable_to_non_nullable
as int,shadowBlur: null == shadowBlur ? _self.shadowBlur : shadowBlur // ignore: cast_nullable_to_non_nullable
as double,shadowOffsetX: null == shadowOffsetX ? _self.shadowOffsetX : shadowOffsetX // ignore: cast_nullable_to_non_nullable
as double,shadowOffsetY: null == shadowOffsetY ? _self.shadowOffsetY : shadowOffsetY // ignore: cast_nullable_to_non_nullable
as double,strategyType: null == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as String,strokePattern: null == strokePattern ? _self.strokePattern : strokePattern // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  String arrowType,  double arrowSize,  int width,  int height,  int textColor,  int shadowColor,  double shadowBlur,  double shadowOffsetX,  double shadowOffsetY,  String strategyType,  String strokePattern)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RelationStyle() when $default != null:
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.arrowType,_that.arrowSize,_that.width,_that.height,_that.textColor,_that.shadowColor,_that.shadowBlur,_that.shadowOffsetX,_that.shadowOffsetY,_that.strategyType,_that.strokePattern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  String arrowType,  double arrowSize,  int width,  int height,  int textColor,  int shadowColor,  double shadowBlur,  double shadowOffsetX,  double shadowOffsetY,  String strategyType,  String strokePattern)  $default,) {final _that = this;
switch (_that) {
case _RelationStyle():
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.arrowType,_that.arrowSize,_that.width,_that.height,_that.textColor,_that.shadowColor,_that.shadowBlur,_that.shadowOffsetX,_that.shadowOffsetY,_that.strategyType,_that.strokePattern);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int bgColor,  int strokeColor,  int strokeWidth,  String fontFamily,  double fontSize,  String shape,  String arrowType,  double arrowSize,  int width,  int height,  int textColor,  int shadowColor,  double shadowBlur,  double shadowOffsetX,  double shadowOffsetY,  String strategyType,  String strokePattern)?  $default,) {final _that = this;
switch (_that) {
case _RelationStyle() when $default != null:
return $default(_that.bgColor,_that.strokeColor,_that.strokeWidth,_that.fontFamily,_that.fontSize,_that.shape,_that.arrowType,_that.arrowSize,_that.width,_that.height,_that.textColor,_that.shadowColor,_that.shadowBlur,_that.shadowOffsetX,_that.shadowOffsetY,_that.strategyType,_that.strokePattern);case _:
  return null;

}
}

}

/// @nodoc


class _RelationStyle implements RelationStyle {
  const _RelationStyle({required this.bgColor, required this.strokeColor, required this.strokeWidth, required this.fontFamily, required this.fontSize, required this.shape, required this.arrowType, required this.arrowSize, required this.width, required this.height, required this.textColor, required this.shadowColor, required this.shadowBlur, required this.shadowOffsetX, required this.shadowOffsetY, required this.strategyType, required this.strokePattern});
  

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
@override final  int textColor;
@override final  int shadowColor;
@override final  double shadowBlur;
@override final  double shadowOffsetX;
@override final  double shadowOffsetY;
@override final  String strategyType;
@override final  String strokePattern;

/// Create a copy of RelationStyle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelationStyleCopyWith<_RelationStyle> get copyWith => __$RelationStyleCopyWithImpl<_RelationStyle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RelationStyle&&(identical(other.bgColor, bgColor) || other.bgColor == bgColor)&&(identical(other.strokeColor, strokeColor) || other.strokeColor == strokeColor)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.arrowType, arrowType) || other.arrowType == arrowType)&&(identical(other.arrowSize, arrowSize) || other.arrowSize == arrowSize)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.shadowColor, shadowColor) || other.shadowColor == shadowColor)&&(identical(other.shadowBlur, shadowBlur) || other.shadowBlur == shadowBlur)&&(identical(other.shadowOffsetX, shadowOffsetX) || other.shadowOffsetX == shadowOffsetX)&&(identical(other.shadowOffsetY, shadowOffsetY) || other.shadowOffsetY == shadowOffsetY)&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType)&&(identical(other.strokePattern, strokePattern) || other.strokePattern == strokePattern));
}


@override
int get hashCode => Object.hash(runtimeType,bgColor,strokeColor,strokeWidth,fontFamily,fontSize,shape,arrowType,arrowSize,width,height,textColor,shadowColor,shadowBlur,shadowOffsetX,shadowOffsetY,strategyType,strokePattern);

@override
String toString() {
  return 'RelationStyle(bgColor: $bgColor, strokeColor: $strokeColor, strokeWidth: $strokeWidth, fontFamily: $fontFamily, fontSize: $fontSize, shape: $shape, arrowType: $arrowType, arrowSize: $arrowSize, width: $width, height: $height, textColor: $textColor, shadowColor: $shadowColor, shadowBlur: $shadowBlur, shadowOffsetX: $shadowOffsetX, shadowOffsetY: $shadowOffsetY, strategyType: $strategyType, strokePattern: $strokePattern)';
}


}

/// @nodoc
abstract mixin class _$RelationStyleCopyWith<$Res> implements $RelationStyleCopyWith<$Res> {
  factory _$RelationStyleCopyWith(_RelationStyle value, $Res Function(_RelationStyle) _then) = __$RelationStyleCopyWithImpl;
@override @useResult
$Res call({
 int bgColor, int strokeColor, int strokeWidth, String fontFamily, double fontSize, String shape, String arrowType, double arrowSize, int width, int height, int textColor, int shadowColor, double shadowBlur, double shadowOffsetX, double shadowOffsetY, String strategyType, String strokePattern
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
@override @pragma('vm:prefer-inline') $Res call({Object? bgColor = null,Object? strokeColor = null,Object? strokeWidth = null,Object? fontFamily = null,Object? fontSize = null,Object? shape = null,Object? arrowType = null,Object? arrowSize = null,Object? width = null,Object? height = null,Object? textColor = null,Object? shadowColor = null,Object? shadowBlur = null,Object? shadowOffsetX = null,Object? shadowOffsetY = null,Object? strategyType = null,Object? strokePattern = null,}) {
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
as int,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as int,shadowColor: null == shadowColor ? _self.shadowColor : shadowColor // ignore: cast_nullable_to_non_nullable
as int,shadowBlur: null == shadowBlur ? _self.shadowBlur : shadowBlur // ignore: cast_nullable_to_non_nullable
as double,shadowOffsetX: null == shadowOffsetX ? _self.shadowOffsetX : shadowOffsetX // ignore: cast_nullable_to_non_nullable
as double,shadowOffsetY: null == shadowOffsetY ? _self.shadowOffsetY : shadowOffsetY // ignore: cast_nullable_to_non_nullable
as double,strategyType: null == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as String,strokePattern: null == strokePattern ? _self.strokePattern : strokePattern // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
