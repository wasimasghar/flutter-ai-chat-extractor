/// Single error type for the whole app.
/// Network layer throws it, Bloc catches it and shows `message` to the user.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
