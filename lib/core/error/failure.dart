/// A transport- and format-independent description of "the request did not
/// produce data".
///
/// The UI switches on [FailureKind], never on a `DioException` or an HTTP
/// status code — that is what keeps the presentation layer from growing a
/// dependency on the networking stack.
enum FailureKind {
  /// No route to the host: airplane mode, no signal, captive portal.
  offline,

  /// The request took too long. Common on the 3G connections this app targets,
  /// and worth distinguishing from [offline] because retrying is more likely
  /// to work.
  timeout,

  /// 5xx, or a gateway that returned something that is not our API.
  server,

  /// 4xx that is not auth — a bad slug, a removed article.
  notFound,

  /// The response parsed as JSON but did not match the contract. Almost always
  /// a backend deploy that changed a field.
  malformedResponse,

  /// Anything we did not anticipate.
  unknown,
}

/// The error type crossing the repository boundary.
class Failure implements Exception {
  const Failure({
    required this.kind,
    required this.code,
    this.cause,
    this.stackTrace,
  });

  final FailureKind kind;

  /// A short, stable, loggable identifier — `NETWORK_TIMEOUT`, `HTTP_503`.
  /// The canvas shows this verbatim under the error message, so it is part of
  /// the UI contract, not just a debugging aid.
  final String code;

  final Object? cause;
  final StackTrace? stackTrace;

  /// True when retrying the same request could plausibly succeed.
  bool get isRetryable =>
      kind == FailureKind.offline ||
      kind == FailureKind.timeout ||
      kind == FailureKind.server;

  @override
  String toString() => 'Failure($code, $kind)';
}
