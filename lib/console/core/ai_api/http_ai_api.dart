import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/api_exception.dart';
import '../admin_api/console_credentials.dart';
import 'dto/ai_suggestion_dto.dart';
import 'puntland_ai_api.dart';

/// [PuntlandAiApi] over HTTP.
///
/// Built like `HttpAdminApi` — hand-written request bodies, lower-camel
/// parameter names out, snake-free DTOs in, every error through
/// [ApiExceptionMapper] — with two deliberate differences.
///
/// It runs on **its own dio**, because a whole-article translation routinely
/// takes longer than the twenty seconds the console's shared client allows, and
/// widening that would slow the failure of every ordinary request to match the
/// slowest thing anyone can ask for.
///
/// And it **does not renew the session itself**. The backend rotates the
/// refresh token on every use and revokes the one presented, so a second
/// independent renewer would race the first and spend a token that had already
/// been thrown away. On a `401` it asks [renewSession] — which is
/// `HttpAdminApi`'s single-flight renewal — and retries once.
class HttpAiApi implements PuntlandAiApi {
  HttpAiApi(this._dio, this._credentials, this.renewSession);

  final Dio _dio;
  final ConsoleCredentials _credentials;

  /// The one renewal path this console has. See the class doc.
  final Future<bool> Function() renewSession;

  @override
  Future<AiCapabilitiesDto> fetchCapabilities() async {
    // Never throws, by contract: not knowing whether assistance exists has to
    // read as "it does not", so the console renders nothing rather than
    // offering a button on a guess.
    try {
      return await _get(
        '/v1/admin/ai/capabilities',
        AiCapabilitiesDto.fromJson,
      );
    } catch (_) {
      return AiCapabilitiesDto.disabled;
    }
  }

  @override
  Future<ArticleTranslationSuggestion> translateArticle({
    required String articleId,
    required String from,
    required String to,
    List<String>? fields,
  }) => _post(
    '/v1/admin/ai/articles/$articleId/translate',
    ArticleTranslationSuggestion.fromJson,
    body: {'from': from, 'to': to, 'fields': ?fields},
  );

  @override
  Future<ExcerptSuggestion> suggestExcerpt({
    required String articleId,
    required String locale,
  }) => _post(
    '/v1/admin/ai/articles/$articleId/excerpt',
    ExcerptSuggestion.fromJson,
    body: {'locale': locale},
  );

  @override
  Future<HeadlineSuggestion> suggestHeadlines({
    required String articleId,
    required String locale,
    int count = 3,
  }) => _post(
    '/v1/admin/ai/articles/$articleId/headlines',
    HeadlineSuggestion.fromJson,
    body: {'locale': locale, 'count': count},
  );

  @override
  Future<LocalisedSuggestion> suggestAltText({
    required String assetId,
    List<String>? locales,
  }) => _post(
    '/v1/admin/ai/media/$assetId/alt',
    (json) =>
        LocalisedSuggestion.fromJson(json, idKey: 'assetId', valueKey: 'alt'),
    body: {'locales': ?locales},
  );

  @override
  Future<LocalisedSuggestion> suggestSynopsis({
    required String programId,
    List<String>? locales,
  }) => _post(
    '/v1/admin/ai/programs/$programId/synopsis',
    (json) => LocalisedSuggestion.fromJson(
      json,
      idKey: 'programId',
      valueKey: 'synopses',
    ),
    body: {'locales': ?locales},
  );

  // ---- Transport ----

  Future<T> _get<T>(String path, T Function(Map<String, dynamic>) parse) async {
    try {
      final res = await _request('GET', path);
      return parse(_requireBody(res.data));
    } catch (e, st) {
      throw ApiExceptionMapper.map(e, st);
    }
  }

  Future<T> _post<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final res = await _request('POST', path, body: body);
      return parse(_requireBody(res.data));
    } catch (e, st) {
      throw ApiExceptionMapper.map(e, st);
    }
  }

  Future<Response<dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _dio.request<dynamic>(
        path,
        data: body,
        options: Options(method: method, headers: _headers()),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
      if (!await renewSession()) rethrow;

      return await _dio.request<dynamic>(
        path,
        data: body,
        options: Options(method: method, headers: _headers()),
      );
    }
  }

  /// The browser build usually has no token to attach — the backend set an
  /// httpOnly cookie the client cannot read, which is the point — and the
  /// cookie rides along because `withCredentials` is set on this dio too.
  Map<String, dynamic>? _headers() {
    final token = _credentials.accessToken;
    return token == null ? null : {'Authorization': 'Bearer $token'};
  }

  static Map<String, dynamic> _requireBody(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    throw const Failure(
      kind: FailureKind.malformedResponse,
      code: 'EMPTY_BODY',
    );
  }
}
