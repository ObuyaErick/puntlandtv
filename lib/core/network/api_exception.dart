import 'package:dio/dio.dart';

import '../error/failure.dart';

/// Translates `dio`'s exception vocabulary into our [Failure] vocabulary.
///
/// This is the only place in the app that is allowed to know what a
/// [DioException] is. Everything above the repository boundary sees a
/// [Failure], which is why swapping the HTTP client would not reach the UI.
abstract final class ApiExceptionMapper {
  static Failure map(Object error, StackTrace stackTrace) {
    if (error is Failure) return error;

    if (error is DioException) {
      final status = error.response?.statusCode;

      final kind = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout => FailureKind.timeout,
        DioExceptionType.connectionError => FailureKind.offline,
        DioExceptionType.badResponse when status == 404 => FailureKind.notFound,
        DioExceptionType.badResponse when status != null && status >= 500 =>
          FailureKind.server,
        DioExceptionType.badResponse => FailureKind.server,
        DioExceptionType.cancel => FailureKind.unknown,
        DioExceptionType.badCertificate => FailureKind.server,
        DioExceptionType.unknown => FailureKind.offline,
      };

      final code = switch (kind) {
        FailureKind.timeout => 'NETWORK_TIMEOUT',
        FailureKind.offline => 'NETWORK_UNREACHABLE',
        FailureKind.notFound => 'HTTP_404',
        FailureKind.server => 'HTTP_${status ?? 'ERR'}',
        _ => 'NETWORK_ERROR',
      };

      return Failure(
        kind: kind,
        code: code,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // A `CheckedFromJsonException` lands here: build.yaml sets `checked: true`
    // so the exception names the offending key instead of throwing a bare
    // null-cast error.
    if (error is TypeError || error.runtimeType.toString().contains('Json')) {
      return Failure(
        kind: FailureKind.malformedResponse,
        code: 'BAD_PAYLOAD',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return Failure(
      kind: FailureKind.unknown,
      code: 'UNKNOWN',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
