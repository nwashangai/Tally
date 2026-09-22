import 'package:dio/dio.dart';
import '../error/app_error.dart';
import '../result/result.dart';

/// Abstract port for HTTP API communication.
/// Insulates repositories from concrete HTTP client implementations (Dio, HTTP, etc.).
abstract interface class ApiClient {
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });

  Future<Result<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });

  Future<Result<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });
}

/// Production ApiClient backed by Dio with error translation.
class DioApiClient implements ApiClient {
  final Dio _dio;

  DioApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? '',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  @override
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      if (response.data == null) {
        return const Failure(StorageError('Received null response data'));
      }
      return Success(response.data as T);
    } catch (e, st) {
      return Failure(_mapDioError(e), stackTrace: st);
    }
  }

  @override
  Future<Result<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      if (response.data == null) {
        return const Failure(StorageError('Received null response data'));
      }
      return Success(response.data as T);
    } catch (e, st) {
      return Failure(_mapDioError(e), stackTrace: st);
    }
  }

  @override
  Future<Result<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      if (response.data == null) {
        return const Failure(StorageError('Received null response data'));
      }
      return Success(response.data as T);
    } catch (e, st) {
      return Failure(_mapDioError(e), stackTrace: st);
    }
  }

  AppError _mapDioError(Object error) {
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          NetworkError('Connection timed out or network unavailable',
              cause: error),
        DioExceptionType.badResponse => NetworkError(
            'Server responded with error',
            statusCode: error.response?.statusCode,
            cause: error),
        DioExceptionType.cancel => const NetworkError('Request was cancelled'),
        _ => NetworkError(error.message ?? 'Unknown network failure',
            cause: error),
      };
    }
    return UnknownError(error.toString(), cause: error);
  }
}
