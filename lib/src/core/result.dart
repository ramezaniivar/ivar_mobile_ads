sealed class Result<T> {
  const Result();

  /// Creates an instance of Result containing a value
  factory Result.ok(T data) => Ok(data);

  /// Create an instance of Result containing an error
  factory Result.error(String error, {int statusCode = 400}) =>
      Error(error, statusCode: statusCode);

  /// Convenience method to cast to Ok
  Ok<T> get asOk => this as Ok<T>;

  /// Convenience method to cast to Error
  Error<T> get asError => this as Error<T>;

  ///check is OK
  bool get isOk => this is Ok<T>;

  ///check is error
  bool get isError => this is Error<T>;
}

/// Subclass of Result for values
final class Ok<T> extends Result<T> {
  const Ok(this.data);

  /// Returned value in result
  final T data;

  @override
  String toString() => 'Result<$T>.ok($data)';
}

/// Subclass of Result for errors
final class Error<T> extends Result<T> {
  const Error(this.error, {this.statusCode = 400});

  /// Returned error in result
  final String error;
  final int statusCode;

  @override
  String toString() => 'Result<$T>.error($error)';
}
