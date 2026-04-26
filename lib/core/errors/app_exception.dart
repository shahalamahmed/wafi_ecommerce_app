class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const AppException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException({super.message = 'No internet connection'});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({super.message = 'Unauthorized', super.statusCode = 401});
}

class ServerException extends AppException {
  const ServerException({required super.message, super.statusCode});
}

class NotFoundException extends AppException {
  const NotFoundException({super.message = 'Resource not found', super.statusCode = 404});
}