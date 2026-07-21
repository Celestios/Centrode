// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoutingMode {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingMode);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingMode()';
}


}

/// @nodoc
class $RoutingModeCopyWith<$Res>  {
$RoutingModeCopyWith(RoutingMode _, $Res Function(RoutingMode) __);
}


/// Adds pattern-matching-related methods to [RoutingMode].
extension RoutingModePatterns on RoutingMode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RoutingMode_Polyline value)?  polyline,TResult Function( RoutingMode_BSpline value)?  bSpline,TResult Function( RoutingMode_Orthogonal value)?  orthogonal,TResult Function( RoutingMode_Octilinear value)?  octilinear,TResult Function( RoutingMode_Bezier value)?  bezier,TResult Function( RoutingMode_SineWave value)?  sineWave,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RoutingMode_Polyline() when polyline != null:
return polyline(_that);case RoutingMode_BSpline() when bSpline != null:
return bSpline(_that);case RoutingMode_Orthogonal() when orthogonal != null:
return orthogonal(_that);case RoutingMode_Octilinear() when octilinear != null:
return octilinear(_that);case RoutingMode_Bezier() when bezier != null:
return bezier(_that);case RoutingMode_SineWave() when sineWave != null:
return sineWave(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RoutingMode_Polyline value)  polyline,required TResult Function( RoutingMode_BSpline value)  bSpline,required TResult Function( RoutingMode_Orthogonal value)  orthogonal,required TResult Function( RoutingMode_Octilinear value)  octilinear,required TResult Function( RoutingMode_Bezier value)  bezier,required TResult Function( RoutingMode_SineWave value)  sineWave,}){
final _that = this;
switch (_that) {
case RoutingMode_Polyline():
return polyline(_that);case RoutingMode_BSpline():
return bSpline(_that);case RoutingMode_Orthogonal():
return orthogonal(_that);case RoutingMode_Octilinear():
return octilinear(_that);case RoutingMode_Bezier():
return bezier(_that);case RoutingMode_SineWave():
return sineWave(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RoutingMode_Polyline value)?  polyline,TResult? Function( RoutingMode_BSpline value)?  bSpline,TResult? Function( RoutingMode_Orthogonal value)?  orthogonal,TResult? Function( RoutingMode_Octilinear value)?  octilinear,TResult? Function( RoutingMode_Bezier value)?  bezier,TResult? Function( RoutingMode_SineWave value)?  sineWave,}){
final _that = this;
switch (_that) {
case RoutingMode_Polyline() when polyline != null:
return polyline(_that);case RoutingMode_BSpline() when bSpline != null:
return bSpline(_that);case RoutingMode_Orthogonal() when orthogonal != null:
return orthogonal(_that);case RoutingMode_Octilinear() when octilinear != null:
return octilinear(_that);case RoutingMode_Bezier() when bezier != null:
return bezier(_that);case RoutingMode_SineWave() when sineWave != null:
return sineWave(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  polyline,TResult Function()?  bSpline,TResult Function()?  orthogonal,TResult Function()?  octilinear,TResult Function( Point? controlPoint1,  Point? controlPoint2)?  bezier,TResult Function( Point? controlPoint1,  Point? controlPoint2)?  sineWave,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RoutingMode_Polyline() when polyline != null:
return polyline();case RoutingMode_BSpline() when bSpline != null:
return bSpline();case RoutingMode_Orthogonal() when orthogonal != null:
return orthogonal();case RoutingMode_Octilinear() when octilinear != null:
return octilinear();case RoutingMode_Bezier() when bezier != null:
return bezier(_that.controlPoint1,_that.controlPoint2);case RoutingMode_SineWave() when sineWave != null:
return sineWave(_that.controlPoint1,_that.controlPoint2);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  polyline,required TResult Function()  bSpline,required TResult Function()  orthogonal,required TResult Function()  octilinear,required TResult Function( Point? controlPoint1,  Point? controlPoint2)  bezier,required TResult Function( Point? controlPoint1,  Point? controlPoint2)  sineWave,}) {final _that = this;
switch (_that) {
case RoutingMode_Polyline():
return polyline();case RoutingMode_BSpline():
return bSpline();case RoutingMode_Orthogonal():
return orthogonal();case RoutingMode_Octilinear():
return octilinear();case RoutingMode_Bezier():
return bezier(_that.controlPoint1,_that.controlPoint2);case RoutingMode_SineWave():
return sineWave(_that.controlPoint1,_that.controlPoint2);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  polyline,TResult? Function()?  bSpline,TResult? Function()?  orthogonal,TResult? Function()?  octilinear,TResult? Function( Point? controlPoint1,  Point? controlPoint2)?  bezier,TResult? Function( Point? controlPoint1,  Point? controlPoint2)?  sineWave,}) {final _that = this;
switch (_that) {
case RoutingMode_Polyline() when polyline != null:
return polyline();case RoutingMode_BSpline() when bSpline != null:
return bSpline();case RoutingMode_Orthogonal() when orthogonal != null:
return orthogonal();case RoutingMode_Octilinear() when octilinear != null:
return octilinear();case RoutingMode_Bezier() when bezier != null:
return bezier(_that.controlPoint1,_that.controlPoint2);case RoutingMode_SineWave() when sineWave != null:
return sineWave(_that.controlPoint1,_that.controlPoint2);case _:
  return null;

}
}

}

/// @nodoc


class RoutingMode_Polyline extends RoutingMode {
  const RoutingMode_Polyline(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingMode_Polyline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingMode.polyline()';
}


}




/// @nodoc


class RoutingMode_BSpline extends RoutingMode {
  const RoutingMode_BSpline(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingMode_BSpline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingMode.bSpline()';
}


}




/// @nodoc


class RoutingMode_Orthogonal extends RoutingMode {
  const RoutingMode_Orthogonal(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingMode_Orthogonal);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingMode.orthogonal()';
}


}




/// @nodoc


class RoutingMode_Octilinear extends RoutingMode {
  const RoutingMode_Octilinear(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingMode_Octilinear);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingMode.octilinear()';
}


}




/// @nodoc


class RoutingMode_Bezier extends RoutingMode {
  const RoutingMode_Bezier({this.controlPoint1, this.controlPoint2}): super._();
  

 final  Point? controlPoint1;
 final  Point? controlPoint2;

/// Create a copy of RoutingMode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingMode_BezierCopyWith<RoutingMode_Bezier> get copyWith => _$RoutingMode_BezierCopyWithImpl<RoutingMode_Bezier>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingMode_Bezier&&(identical(other.controlPoint1, controlPoint1) || other.controlPoint1 == controlPoint1)&&(identical(other.controlPoint2, controlPoint2) || other.controlPoint2 == controlPoint2));
}


@override
int get hashCode => Object.hash(runtimeType,controlPoint1,controlPoint2);

@override
String toString() {
  return 'RoutingMode.bezier(controlPoint1: $controlPoint1, controlPoint2: $controlPoint2)';
}


}

/// @nodoc
abstract mixin class $RoutingMode_BezierCopyWith<$Res> implements $RoutingModeCopyWith<$Res> {
  factory $RoutingMode_BezierCopyWith(RoutingMode_Bezier value, $Res Function(RoutingMode_Bezier) _then) = _$RoutingMode_BezierCopyWithImpl;
@useResult
$Res call({
 Point? controlPoint1, Point? controlPoint2
});




}
/// @nodoc
class _$RoutingMode_BezierCopyWithImpl<$Res>
    implements $RoutingMode_BezierCopyWith<$Res> {
  _$RoutingMode_BezierCopyWithImpl(this._self, this._then);

  final RoutingMode_Bezier _self;
  final $Res Function(RoutingMode_Bezier) _then;

/// Create a copy of RoutingMode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? controlPoint1 = freezed,Object? controlPoint2 = freezed,}) {
  return _then(RoutingMode_Bezier(
controlPoint1: freezed == controlPoint1 ? _self.controlPoint1 : controlPoint1 // ignore: cast_nullable_to_non_nullable
as Point?,controlPoint2: freezed == controlPoint2 ? _self.controlPoint2 : controlPoint2 // ignore: cast_nullable_to_non_nullable
as Point?,
  ));
}


}

/// @nodoc


class RoutingMode_SineWave extends RoutingMode {
  const RoutingMode_SineWave({this.controlPoint1, this.controlPoint2}): super._();
  

 final  Point? controlPoint1;
 final  Point? controlPoint2;

/// Create a copy of RoutingMode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingMode_SineWaveCopyWith<RoutingMode_SineWave> get copyWith => _$RoutingMode_SineWaveCopyWithImpl<RoutingMode_SineWave>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingMode_SineWave&&(identical(other.controlPoint1, controlPoint1) || other.controlPoint1 == controlPoint1)&&(identical(other.controlPoint2, controlPoint2) || other.controlPoint2 == controlPoint2));
}


@override
int get hashCode => Object.hash(runtimeType,controlPoint1,controlPoint2);

@override
String toString() {
  return 'RoutingMode.sineWave(controlPoint1: $controlPoint1, controlPoint2: $controlPoint2)';
}


}

/// @nodoc
abstract mixin class $RoutingMode_SineWaveCopyWith<$Res> implements $RoutingModeCopyWith<$Res> {
  factory $RoutingMode_SineWaveCopyWith(RoutingMode_SineWave value, $Res Function(RoutingMode_SineWave) _then) = _$RoutingMode_SineWaveCopyWithImpl;
@useResult
$Res call({
 Point? controlPoint1, Point? controlPoint2
});




}
/// @nodoc
class _$RoutingMode_SineWaveCopyWithImpl<$Res>
    implements $RoutingMode_SineWaveCopyWith<$Res> {
  _$RoutingMode_SineWaveCopyWithImpl(this._self, this._then);

  final RoutingMode_SineWave _self;
  final $Res Function(RoutingMode_SineWave) _then;

/// Create a copy of RoutingMode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? controlPoint1 = freezed,Object? controlPoint2 = freezed,}) {
  return _then(RoutingMode_SineWave(
controlPoint1: freezed == controlPoint1 ? _self.controlPoint1 : controlPoint1 // ignore: cast_nullable_to_non_nullable
as Point?,controlPoint2: freezed == controlPoint2 ? _self.controlPoint2 : controlPoint2 // ignore: cast_nullable_to_non_nullable
as Point?,
  ));
}


}

// dart format on
