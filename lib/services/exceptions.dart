class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? responseBody;

  ApiException({
    required this.message,
    required this.statusCode,
    this.responseBody,
  });

  @override
  String toString() {
    if (responseBody != null) {
      return 'ApiException: $message (Status: $statusCode)\nResponse: $responseBody';
    }
    return 'ApiException: $message (Status: $statusCode)';
  }
}
class NetworkException implements Exception {
  final String? message;

  NetworkException({this.message});
}