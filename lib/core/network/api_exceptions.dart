import 'package:dio/dio.dart';

/// Base class for all Voxora API exceptions.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => '$runtimeType(statusCode: $statusCode, message: $message)';
}

/// Thrown when there is no internet connection or the request timed out.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection. Please check your network.',
    super.statusCode,
    super.data,
  });
}

/// Thrown when the server returns 401 / 403.
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Your session has expired. Please sign in again.',
    super.statusCode = 401,
    super.data,
  });
}

/// Thrown when the server returns 5xx.
class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error. Please try again later.',
    super.statusCode,
    super.data,
  });
}

/// Thrown when the server returns 404.
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.statusCode = 404,
    super.data,
  });
}

/// Thrown when the server returns 400 / 422.
class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    super.message = 'Please check your input and try again.',
    super.statusCode = 422,
    super.data,
    this.errors,
  });
}

/// Thrown when the request is cancelled.
class RequestCancelledException extends AppException {
  const RequestCancelledException({
    super.message = 'Request was cancelled.',
    super.statusCode,
    super.data,
  });
}

/// Thrown for any other unexpected error.
class UnknownException extends AppException {
  const UnknownException({
    super.message = 'Something went wrong. Please try again.',
    super.statusCode,
    super.data,
  });
}

/// Factory that converts a [DioException] into a typed [AppException].
class ApiExceptionMapper {
  ApiExceptionMapper._();

  static AppException fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Request timed out. Please try again.',
        );

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.cancel:
        return const RequestCancelledException();

      case DioExceptionType.badResponse:
        return _fromResponse(error.response);

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'SSL certificate error. Please check your connection.',
        );

      case DioExceptionType.unknown:
      default:
        if (error.message?.contains('SocketException') == true ||
            error.message?.contains('Connection refused') == true) {
          return const NetworkException();
        }
        return UnknownException(message: error.message ?? 'Unknown error');
    }
  }

  static AppException _fromResponse(Response? response) {
    if (response == null) {
      return const UnknownException(message: 'Empty response from server.');
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;
    final serverMessage = _extractMessage(data);

    switch (statusCode) {
      case 400:
        return ValidationException(
          message: serverMessage ?? 'Bad request.',
          statusCode: statusCode,
          data: data,
        );
      case 401:
        return UnauthorizedException(
          message: serverMessage ?? 'Unauthorized.',
          statusCode: statusCode,
          data: data,
        );
      case 403:
        return UnauthorizedException(
          message: serverMessage ?? 'Forbidden.',
          statusCode: statusCode,
          data: data,
        );
      case 404:
        return NotFoundException(
          message: serverMessage ?? 'Resource not found.',
          statusCode: statusCode,
          data: data,
        );
      case 422:
        return ValidationException(
          message: serverMessage ?? 'Validation failed.',
          statusCode: statusCode,
          data: data,
          errors: _extractErrors(data),
        );
      default:
        if (statusCode >= 500) {
          return ServerException(
            message: serverMessage ?? 'Internal server error.',
            statusCode: statusCode,
            data: data,
          );
        }
        return UnknownException(
          message: serverMessage ?? 'Unexpected error.',
          statusCode: statusCode,
          data: data,
        );
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? data['detail'])?.toString();
    }
    return null;
  }

  static Map<String, List<String>>? _extractErrors(dynamic data) {
    if (data is Map && data['errors'] is Map) {
      final raw = data['errors'] as Map;
      return raw.map((key, value) {
        if (value is List) {
          return MapEntry(key.toString(), value.map((e) => e.toString()).toList());
        }
        return MapEntry(key.toString(), [value.toString()]);
      });
    }
    return null;
  }
}
