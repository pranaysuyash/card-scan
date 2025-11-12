/// Functional programming Either type for error handling
/// Left = Failure, Right = Success
abstract class Either<L, R> {
  const Either();

  bool get isLeft;
  bool get isRight;

  L get left;
  R get right;

  T fold<T>(T Function(L left) fnL, T Function(R right) fnR);

  Either<L, T> map<T>(T Function(R right) fn);
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) fn);
}

class Left<L, R> extends Either<L, R> {
  final L _value;

  const Left(this._value);

  @override
  bool get isLeft => true;

  @override
  bool get isRight => false;

  @override
  L get left => _value;

  @override
  R get right => throw Exception('Cannot get right value from Left');

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnL(_value);

  @override
  Either<L, T> map<T>(T Function(R right) fn) => Left(_value);

  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) fn) => Left(_value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Left<L, R> && other._value == _value;
  }

  @override
  int get hashCode => _value.hashCode;
}

class Right<L, R> extends Either<L, R> {
  final R _value;

  const Right(this._value);

  @override
  bool get isLeft => false;

  @override
  bool get isRight => true;

  @override
  L get left => throw Exception('Cannot get left value from Right');

  @override
  R get right => _value;

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnR(_value);

  @override
  Either<L, T> map<T>(T Function(R right) fn) => Right(fn(_value));

  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) fn) => fn(_value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Right<L, R> && other._value == _value;
  }

  @override
  int get hashCode => _value.hashCode;
}
