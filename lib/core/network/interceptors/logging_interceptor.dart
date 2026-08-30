import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Request logging, debug builds only.
///
/// Deliberately terse — method, path, status, elapsed. Full body logging on a
/// news feed floods the console and hides the one line worth seeing.
class LoggingInterceptor extends Interceptor {
  final _started = <RequestOptions, DateTime>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _started[options] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, response.statusCode?.toString() ?? '???');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      err.requestOptions,
      'ERR ${err.response?.statusCode ?? err.type.name}',
    );
    handler.next(err);
  }

  void _log(RequestOptions options, String outcome) {
    final start = _started.remove(options);
    final ms = start == null
        ? '?'
        : DateTime.now().difference(start).inMilliseconds.toString();
    developer.log(
      '${options.method} ${options.path} → $outcome (${ms}ms)',
      name: 'api',
    );
  }
}
