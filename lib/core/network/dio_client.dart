import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dead_porky/core/constants/app_constants.dart';
import 'package:dead_porky/core/errors/failures.dart';

/// API exception handler
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() =>
      'ApiException: $message (status: $statusCode, code: $code)';
}

/// Dio HTTP client configuration
class DioClient {
  late final Dio _dio;

  DioClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
        receiveTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
        sendTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[Dio] $obj'),
      ),
      _AuthInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}

/// Interceptor to add auth token
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: Get token from secure storage
    // final token = await SecureStorage.getToken();
    // if (token != null) {
    //   options.headers['Authorization'] = 'Bearer $token';
    // }
    handler.next(options);
  }
}

/// Interceptor to handle errors
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkFailure('Tiempo de conexión agotado'),
          ),
        );
        break;
      case DioExceptionType.connectionError:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkFailure('Sin conexión a internet'),
          ),
        );
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final message = _parseErrorMessage(err.response?.data);

        if (statusCode == 401) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: AuthFailure(
                message ?? 'No autorizado',
                code: 'UNAUTHORIZED',
              ),
            ),
          );
        } else if (statusCode == 403) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: PermissionFailure(
                message ?? 'Acceso denegado',
                code: 'FORBIDDEN',
              ),
            ),
          );
        } else if (statusCode == 404) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ServerFailure(
                message ?? 'No encontrado',
                code: 'NOT_FOUND',
              ),
            ),
          );
        } else if (statusCode == 429) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ServerFailure(
                message ?? 'Demasiadas solicitudes',
                code: 'RATE_LIMITED',
              ),
            ),
          );
        } else {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ServerFailure(
                message ?? 'Error del servidor',
                code: statusCode?.toString(),
              ),
            ),
          );
        }
        break;
      default:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: UnknownFailure(err.message ?? 'Error desconocido'),
          ),
        );
    }
  }

  String? _parseErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    if (data is String) return data;
    return null;
  }
}

/// Utility to handle Future with Either pattern
Future<T> handleApiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    throw e.error as Failure;
  } catch (e) {
    throw UnknownFailure(e.toString());
  }
}
