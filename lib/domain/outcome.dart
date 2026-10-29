/// Result of a domain operation: either a value or a user-presentable error.
sealed class Outcome<T> {
  const Outcome();

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  String? get errorOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final message) => message,
      };
}

final class Ok<T> extends Outcome<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Outcome<T> {
  const Err(this.message);
  final String message;
}
