import 'package:dio/dio.dart';
import 'app_exception.dart';

class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    if (error is AppException) return error;
    return AppException(message: error.toString());
  }

  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException(message: 'Connection timed out');

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _readMessage(error.response?.data);

        if (statusCode == 401) return UnauthorizedException(message: message);
        if (statusCode == 404) return NotFoundException(message: message);
        return ServerException(message: message, statusCode: statusCode);

      default:
        return AppException(message: error.message ?? 'Unknown error');
    }
  }

  static String _readMessage(dynamic data) {
    if (data == null) return 'Server error';

    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['details'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      return 'Server error';
    }

    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return 'Server error';

      if (trimmed.startsWith('<')) {
        return 'Server returned an unexpected HTML response.';
      }

      return trimmed;
    }

    return data.toString();
  }
}
