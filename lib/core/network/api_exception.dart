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

      // A refusal the backend can name: `MEDIA_ASSET_IN_USE`,
      // `STAFF_LAST_ADMIN`, `CONFIG_FLOOR_ABOVE_RELEASE`. The API puts `code`
      // at the top level of the error body for exactly this, and the console's
      // screens switch on those constants — deriving a code from the status
      // alone would collapse every domain rule into one `HTTP_409` the UI
      // cannot tell apart, and the fixtures would be the only implementation
      // the console could show a specific message for.
      final declared = _declaredCode(error.response?.data);
      if (declared != null) {
        return Failure(
          kind: _kindForStatus(status),
          code: declared,
          cause: error,
          stackTrace: stackTrace,
        );
      }

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

  /// The refusal code the response body names, if it names one.
  ///
  /// Only a non-empty string counts. A gateway error page or an HTML 502 parses
  /// to something without this key, and must keep falling through to the
  /// status-derived codes below rather than becoming a `Failure` claiming the
  /// backend refused something.
  static String? _declaredCode(Object? data) {
    if (data is! Map) return null;
    final code = data['code'];
    return code is String && code.isNotEmpty ? code : null;
  }

  /// The kind a coded refusal reports.
  ///
  /// A domain refusal arrives as 409 and maps to [FailureKind.unknown], which
  /// is what the fixtures throw for the same rules — so a screen behaves the
  /// same against either implementation, and `isRetryable` stays false for a
  /// refusal that retrying cannot change.
  static FailureKind _kindForStatus(int? status) => switch (status) {
    404 => FailureKind.notFound,
    final int s when s >= 500 => FailureKind.server,
    _ => FailureKind.unknown,
  };
}
