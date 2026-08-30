import 'package:dio/dio.dart';

/// Sends the active UI locale on every request.
///
/// The backend uses it to localise *chrome* — category names, programme
/// titles, the stream-offline message. It does not filter content: an article
/// published in Somali is returned to an English-UI reader too, tagged with
/// its own `content_locale`. Hiding content by UI language would empty the
/// feed for half the audience.
class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._languageTag);

  /// Read lazily so a language change takes effect on the next request without
  /// rebuilding the client.
  final String Function() _languageTag;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _languageTag();
    handler.next(options);
  }
}
