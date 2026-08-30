import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Retries transient failures with exponential backoff and jitter.
///
/// Not optional on the networks this app targets: a single dropped packet on a
/// congested 3G cell should not become an error screen. Only idempotent reads
/// are retried, and only for connection/timeout/5xx — a 404 is an answer, not
/// a failure to get one.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 400),
    // ignore: prefer_initializing_formals
  }) : _dio = dio;

  /// The same client the interceptor is attached to, used to re-issue the
  /// request. Held explicitly because `err.requestOptions` alone cannot resend.

  final Dio _dio;
  final int maxAttempts;
  final Duration baseDelay;
  final _random = Random();

  static const _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxAttempts - 1) {
      return handler.next(err);
    }

    // Full jitter: without it, every device in a cell that lost coverage
    // retries in lockstep the moment it returns.
    final backoff = baseDelay * pow(2, attempt).toDouble();
    final jittered = Duration(
      milliseconds: _random.nextInt(backoff.inMilliseconds + 1),
    );
    await Future<void>.delayed(jittered);

    options.extra[_attemptKey] = attempt + 1;

    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    final status = err.response?.statusCode;
    if (status != null) return status >= 500;
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.unknown => true,
      _ => false,
    };
  }
}
