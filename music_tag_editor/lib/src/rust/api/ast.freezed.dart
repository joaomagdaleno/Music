// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ast.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Expr {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) literal,
    required TResult Function(String field0) placeholder,
    required TResult Function(Expr left, String op, Expr right) binary,
    required TResult Function(Expr cond, Expr thenBranch, Expr elseBranch) if_,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? literal,
    TResult? Function(String field0)? placeholder,
    TResult? Function(Expr left, String op, Expr right)? binary,
    TResult? Function(Expr cond, Expr thenBranch, Expr elseBranch)? if_,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? literal,
    TResult Function(String field0)? placeholder,
    TResult Function(Expr left, String op, Expr right)? binary,
    TResult Function(Expr cond, Expr thenBranch, Expr elseBranch)? if_,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Expr_Literal value) literal,
    required TResult Function(Expr_Placeholder value) placeholder,
    required TResult Function(Expr_Binary value) binary,
    required TResult Function(Expr_If value) if_,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Expr_Literal value)? literal,
    TResult? Function(Expr_Placeholder value)? placeholder,
    TResult? Function(Expr_Binary value)? binary,
    TResult? Function(Expr_If value)? if_,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Expr_Literal value)? literal,
    TResult Function(Expr_Placeholder value)? placeholder,
    TResult Function(Expr_Binary value)? binary,
    TResult Function(Expr_If value)? if_,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExprCopyWith<$Res> {
  factory $ExprCopyWith(Expr value, $Res Function(Expr) then) =
      _$ExprCopyWithImpl<$Res, Expr>;
}

/// @nodoc
class _$ExprCopyWithImpl<$Res, $Val extends Expr>
    implements $ExprCopyWith<$Res> {
  _$ExprCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$Expr_LiteralImplCopyWith<$Res> {
  factory _$$Expr_LiteralImplCopyWith(
          _$Expr_LiteralImpl value, $Res Function(_$Expr_LiteralImpl) then) =
      __$$Expr_LiteralImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$Expr_LiteralImplCopyWithImpl<$Res>
    extends _$ExprCopyWithImpl<$Res, _$Expr_LiteralImpl>
    implements _$$Expr_LiteralImplCopyWith<$Res> {
  __$$Expr_LiteralImplCopyWithImpl(
      _$Expr_LiteralImpl _value, $Res Function(_$Expr_LiteralImpl) _then)
      : super(_value, _then);

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Expr_LiteralImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$Expr_LiteralImpl extends Expr_Literal {
  const _$Expr_LiteralImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'Expr.literal(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Expr_LiteralImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Expr_LiteralImplCopyWith<_$Expr_LiteralImpl> get copyWith =>
      __$$Expr_LiteralImplCopyWithImpl<_$Expr_LiteralImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) literal,
    required TResult Function(String field0) placeholder,
    required TResult Function(Expr left, String op, Expr right) binary,
    required TResult Function(Expr cond, Expr thenBranch, Expr elseBranch) if_,
  }) {
    return literal(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? literal,
    TResult? Function(String field0)? placeholder,
    TResult? Function(Expr left, String op, Expr right)? binary,
    TResult? Function(Expr cond, Expr thenBranch, Expr elseBranch)? if_,
  }) {
    return literal?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? literal,
    TResult Function(String field0)? placeholder,
    TResult Function(Expr left, String op, Expr right)? binary,
    TResult Function(Expr cond, Expr thenBranch, Expr elseBranch)? if_,
    required TResult orElse(),
  }) {
    if (literal != null) {
      return literal(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Expr_Literal value) literal,
    required TResult Function(Expr_Placeholder value) placeholder,
    required TResult Function(Expr_Binary value) binary,
    required TResult Function(Expr_If value) if_,
  }) {
    return literal(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Expr_Literal value)? literal,
    TResult? Function(Expr_Placeholder value)? placeholder,
    TResult? Function(Expr_Binary value)? binary,
    TResult? Function(Expr_If value)? if_,
  }) {
    return literal?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Expr_Literal value)? literal,
    TResult Function(Expr_Placeholder value)? placeholder,
    TResult Function(Expr_Binary value)? binary,
    TResult Function(Expr_If value)? if_,
    required TResult orElse(),
  }) {
    if (literal != null) {
      return literal(this);
    }
    return orElse();
  }
}

abstract class Expr_Literal extends Expr {
  const factory Expr_Literal(final String field0) = _$Expr_LiteralImpl;
  const Expr_Literal._() : super._();

  String get field0;

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Expr_LiteralImplCopyWith<_$Expr_LiteralImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Expr_PlaceholderImplCopyWith<$Res> {
  factory _$$Expr_PlaceholderImplCopyWith(_$Expr_PlaceholderImpl value,
          $Res Function(_$Expr_PlaceholderImpl) then) =
      __$$Expr_PlaceholderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$Expr_PlaceholderImplCopyWithImpl<$Res>
    extends _$ExprCopyWithImpl<$Res, _$Expr_PlaceholderImpl>
    implements _$$Expr_PlaceholderImplCopyWith<$Res> {
  __$$Expr_PlaceholderImplCopyWithImpl(_$Expr_PlaceholderImpl _value,
      $Res Function(_$Expr_PlaceholderImpl) _then)
      : super(_value, _then);

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Expr_PlaceholderImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$Expr_PlaceholderImpl extends Expr_Placeholder {
  const _$Expr_PlaceholderImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'Expr.placeholder(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Expr_PlaceholderImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Expr_PlaceholderImplCopyWith<_$Expr_PlaceholderImpl> get copyWith =>
      __$$Expr_PlaceholderImplCopyWithImpl<_$Expr_PlaceholderImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) literal,
    required TResult Function(String field0) placeholder,
    required TResult Function(Expr left, String op, Expr right) binary,
    required TResult Function(Expr cond, Expr thenBranch, Expr elseBranch) if_,
  }) {
    return placeholder(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? literal,
    TResult? Function(String field0)? placeholder,
    TResult? Function(Expr left, String op, Expr right)? binary,
    TResult? Function(Expr cond, Expr thenBranch, Expr elseBranch)? if_,
  }) {
    return placeholder?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? literal,
    TResult Function(String field0)? placeholder,
    TResult Function(Expr left, String op, Expr right)? binary,
    TResult Function(Expr cond, Expr thenBranch, Expr elseBranch)? if_,
    required TResult orElse(),
  }) {
    if (placeholder != null) {
      return placeholder(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Expr_Literal value) literal,
    required TResult Function(Expr_Placeholder value) placeholder,
    required TResult Function(Expr_Binary value) binary,
    required TResult Function(Expr_If value) if_,
  }) {
    return placeholder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Expr_Literal value)? literal,
    TResult? Function(Expr_Placeholder value)? placeholder,
    TResult? Function(Expr_Binary value)? binary,
    TResult? Function(Expr_If value)? if_,
  }) {
    return placeholder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Expr_Literal value)? literal,
    TResult Function(Expr_Placeholder value)? placeholder,
    TResult Function(Expr_Binary value)? binary,
    TResult Function(Expr_If value)? if_,
    required TResult orElse(),
  }) {
    if (placeholder != null) {
      return placeholder(this);
    }
    return orElse();
  }
}

abstract class Expr_Placeholder extends Expr {
  const factory Expr_Placeholder(final String field0) = _$Expr_PlaceholderImpl;
  const Expr_Placeholder._() : super._();

  String get field0;

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Expr_PlaceholderImplCopyWith<_$Expr_PlaceholderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Expr_BinaryImplCopyWith<$Res> {
  factory _$$Expr_BinaryImplCopyWith(
          _$Expr_BinaryImpl value, $Res Function(_$Expr_BinaryImpl) then) =
      __$$Expr_BinaryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Expr left, String op, Expr right});

  $ExprCopyWith<$Res> get left;
  $ExprCopyWith<$Res> get right;
}

/// @nodoc
class __$$Expr_BinaryImplCopyWithImpl<$Res>
    extends _$ExprCopyWithImpl<$Res, _$Expr_BinaryImpl>
    implements _$$Expr_BinaryImplCopyWith<$Res> {
  __$$Expr_BinaryImplCopyWithImpl(
      _$Expr_BinaryImpl _value, $Res Function(_$Expr_BinaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? left = null,
    Object? op = null,
    Object? right = null,
  }) {
    return _then(_$Expr_BinaryImpl(
      left: null == left
          ? _value.left
          : left // ignore: cast_nullable_to_non_nullable
              as Expr,
      op: null == op
          ? _value.op
          : op // ignore: cast_nullable_to_non_nullable
              as String,
      right: null == right
          ? _value.right
          : right // ignore: cast_nullable_to_non_nullable
              as Expr,
    ));
  }

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExprCopyWith<$Res> get left {
    return $ExprCopyWith<$Res>(_value.left, (value) {
      return _then(_value.copyWith(left: value));
    });
  }

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExprCopyWith<$Res> get right {
    return $ExprCopyWith<$Res>(_value.right, (value) {
      return _then(_value.copyWith(right: value));
    });
  }
}

/// @nodoc

class _$Expr_BinaryImpl extends Expr_Binary {
  const _$Expr_BinaryImpl(
      {required this.left, required this.op, required this.right})
      : super._();

  @override
  final Expr left;
  @override
  final String op;
  @override
  final Expr right;

  @override
  String toString() {
    return 'Expr.binary(left: $left, op: $op, right: $right)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Expr_BinaryImpl &&
            (identical(other.left, left) || other.left == left) &&
            (identical(other.op, op) || other.op == op) &&
            (identical(other.right, right) || other.right == right));
  }

  @override
  int get hashCode => Object.hash(runtimeType, left, op, right);

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Expr_BinaryImplCopyWith<_$Expr_BinaryImpl> get copyWith =>
      __$$Expr_BinaryImplCopyWithImpl<_$Expr_BinaryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) literal,
    required TResult Function(String field0) placeholder,
    required TResult Function(Expr left, String op, Expr right) binary,
    required TResult Function(Expr cond, Expr thenBranch, Expr elseBranch) if_,
  }) {
    return binary(left, op, right);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? literal,
    TResult? Function(String field0)? placeholder,
    TResult? Function(Expr left, String op, Expr right)? binary,
    TResult? Function(Expr cond, Expr thenBranch, Expr elseBranch)? if_,
  }) {
    return binary?.call(left, op, right);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? literal,
    TResult Function(String field0)? placeholder,
    TResult Function(Expr left, String op, Expr right)? binary,
    TResult Function(Expr cond, Expr thenBranch, Expr elseBranch)? if_,
    required TResult orElse(),
  }) {
    if (binary != null) {
      return binary(left, op, right);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Expr_Literal value) literal,
    required TResult Function(Expr_Placeholder value) placeholder,
    required TResult Function(Expr_Binary value) binary,
    required TResult Function(Expr_If value) if_,
  }) {
    return binary(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Expr_Literal value)? literal,
    TResult? Function(Expr_Placeholder value)? placeholder,
    TResult? Function(Expr_Binary value)? binary,
    TResult? Function(Expr_If value)? if_,
  }) {
    return binary?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Expr_Literal value)? literal,
    TResult Function(Expr_Placeholder value)? placeholder,
    TResult Function(Expr_Binary value)? binary,
    TResult Function(Expr_If value)? if_,
    required TResult orElse(),
  }) {
    if (binary != null) {
      return binary(this);
    }
    return orElse();
  }
}

abstract class Expr_Binary extends Expr {
  const factory Expr_Binary(
      {required final Expr left,
      required final String op,
      required final Expr right}) = _$Expr_BinaryImpl;
  const Expr_Binary._() : super._();

  Expr get left;
  String get op;
  Expr get right;

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Expr_BinaryImplCopyWith<_$Expr_BinaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Expr_IfImplCopyWith<$Res> {
  factory _$$Expr_IfImplCopyWith(
          _$Expr_IfImpl value, $Res Function(_$Expr_IfImpl) then) =
      __$$Expr_IfImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Expr cond, Expr thenBranch, Expr elseBranch});

  $ExprCopyWith<$Res> get cond;
  $ExprCopyWith<$Res> get thenBranch;
  $ExprCopyWith<$Res> get elseBranch;
}

/// @nodoc
class __$$Expr_IfImplCopyWithImpl<$Res>
    extends _$ExprCopyWithImpl<$Res, _$Expr_IfImpl>
    implements _$$Expr_IfImplCopyWith<$Res> {
  __$$Expr_IfImplCopyWithImpl(
      _$Expr_IfImpl _value, $Res Function(_$Expr_IfImpl) _then)
      : super(_value, _then);

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cond = null,
    Object? thenBranch = null,
    Object? elseBranch = null,
  }) {
    return _then(_$Expr_IfImpl(
      cond: null == cond
          ? _value.cond
          : cond // ignore: cast_nullable_to_non_nullable
              as Expr,
      thenBranch: null == thenBranch
          ? _value.thenBranch
          : thenBranch // ignore: cast_nullable_to_non_nullable
              as Expr,
      elseBranch: null == elseBranch
          ? _value.elseBranch
          : elseBranch // ignore: cast_nullable_to_non_nullable
              as Expr,
    ));
  }

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExprCopyWith<$Res> get cond {
    return $ExprCopyWith<$Res>(_value.cond, (value) {
      return _then(_value.copyWith(cond: value));
    });
  }

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExprCopyWith<$Res> get thenBranch {
    return $ExprCopyWith<$Res>(_value.thenBranch, (value) {
      return _then(_value.copyWith(thenBranch: value));
    });
  }

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExprCopyWith<$Res> get elseBranch {
    return $ExprCopyWith<$Res>(_value.elseBranch, (value) {
      return _then(_value.copyWith(elseBranch: value));
    });
  }
}

/// @nodoc

class _$Expr_IfImpl extends Expr_If {
  const _$Expr_IfImpl(
      {required this.cond, required this.thenBranch, required this.elseBranch})
      : super._();

  @override
  final Expr cond;
  @override
  final Expr thenBranch;
  @override
  final Expr elseBranch;

  @override
  String toString() {
    return 'Expr.if_(cond: $cond, thenBranch: $thenBranch, elseBranch: $elseBranch)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Expr_IfImpl &&
            (identical(other.cond, cond) || other.cond == cond) &&
            (identical(other.thenBranch, thenBranch) ||
                other.thenBranch == thenBranch) &&
            (identical(other.elseBranch, elseBranch) ||
                other.elseBranch == elseBranch));
  }

  @override
  int get hashCode => Object.hash(runtimeType, cond, thenBranch, elseBranch);

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Expr_IfImplCopyWith<_$Expr_IfImpl> get copyWith =>
      __$$Expr_IfImplCopyWithImpl<_$Expr_IfImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) literal,
    required TResult Function(String field0) placeholder,
    required TResult Function(Expr left, String op, Expr right) binary,
    required TResult Function(Expr cond, Expr thenBranch, Expr elseBranch) if_,
  }) {
    return if_(cond, thenBranch, elseBranch);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? literal,
    TResult? Function(String field0)? placeholder,
    TResult? Function(Expr left, String op, Expr right)? binary,
    TResult? Function(Expr cond, Expr thenBranch, Expr elseBranch)? if_,
  }) {
    return if_?.call(cond, thenBranch, elseBranch);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? literal,
    TResult Function(String field0)? placeholder,
    TResult Function(Expr left, String op, Expr right)? binary,
    TResult Function(Expr cond, Expr thenBranch, Expr elseBranch)? if_,
    required TResult orElse(),
  }) {
    if (if_ != null) {
      return if_(cond, thenBranch, elseBranch);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Expr_Literal value) literal,
    required TResult Function(Expr_Placeholder value) placeholder,
    required TResult Function(Expr_Binary value) binary,
    required TResult Function(Expr_If value) if_,
  }) {
    return if_(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Expr_Literal value)? literal,
    TResult? Function(Expr_Placeholder value)? placeholder,
    TResult? Function(Expr_Binary value)? binary,
    TResult? Function(Expr_If value)? if_,
  }) {
    return if_?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Expr_Literal value)? literal,
    TResult Function(Expr_Placeholder value)? placeholder,
    TResult Function(Expr_Binary value)? binary,
    TResult Function(Expr_If value)? if_,
    required TResult orElse(),
  }) {
    if (if_ != null) {
      return if_(this);
    }
    return orElse();
  }
}

abstract class Expr_If extends Expr {
  const factory Expr_If(
      {required final Expr cond,
      required final Expr thenBranch,
      required final Expr elseBranch}) = _$Expr_IfImpl;
  const Expr_If._() : super._();

  Expr get cond;
  Expr get thenBranch;
  Expr get elseBranch;

  /// Create a copy of Expr
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Expr_IfImplCopyWith<_$Expr_IfImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
