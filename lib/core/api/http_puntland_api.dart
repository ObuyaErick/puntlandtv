import 'package:dio/dio.dart';

import '../error/failure.dart';
import '../network/api_exception.dart';
import 'dto/app_config_dto.dart';
import 'dto/article_dto.dart';
import 'dto/category_dto.dart';
import 'dto/live_dto.dart';
import 'dto/paged_dto.dart';
import 'dto/program_dto.dart';
import 'puntland_api.dart';

/// [PuntlandApi] over HTTP.
///
/// The only thing this class does beyond calling `dio` is convert every thrown
/// object into a [Failure]. That single rule is what lets the repositories
/// above it have no `try/catch` on `DioException` — and therefore no reason to
/// import `dio` at all.
class HttpPuntlandApi implements PuntlandApi {
  HttpPuntlandApi(this._dio);

  final Dio _dio;

  @override
  Future<AppConfigDto> fetchConfig() =>
      _get('/v1/config', AppConfigDto.fromJson);

  @override
  Future<LiveStatusDto> fetchLiveStatus() =>
      _get('/v1/live', LiveStatusDto.fromJson);

  @override
  Future<RadioStatusDto> fetchRadioStatus() =>
      _get('/v1/radio', RadioStatusDto.fromJson);

  @override
  Future<List<CategoryDto>> fetchCategories() =>
      _getList('/v1/categories', CategoryDto.fromJson);

  @override
  Future<PagedDto<ArticleSummaryDto>> fetchArticles({
    String? categorySlug,
    String? cursor,
    int limit = 20,
  }) => _getPaged(
    '/v1/articles',
    ArticleSummaryDto.fromJson,
    query: {'category': ?categorySlug, 'cursor': ?cursor, 'limit': limit},
  );

  @override
  Future<ArticleDetailDto> fetchArticle(String slug) =>
      _get('/v1/articles/$slug', ArticleDetailDto.fromJson);

  @override
  Future<List<ArticleSummaryDto>> fetchArticlesBySlugs(List<String> slugs) {
    if (slugs.isEmpty) return Future.value(const []);
    return _getList(
      '/v1/articles',
      ArticleSummaryDto.fromJson,
      query: {'slugs': slugs.join(',')},
    );
  }

  @override
  Future<List<ProgramDto>> fetchPrograms() =>
      _getList('/v1/programs', ProgramDto.fromJson);

  @override
  Future<PagedDto<EpisodeDto>> fetchEpisodes({
    String? programId,
    String? cursor,
    int limit = 20,
  }) => _getPaged(
    '/v1/videos',
    EpisodeDto.fromJson,
    query: {'program': ?programId, 'cursor': ?cursor, 'limit': limit},
  );

  @override
  Future<void> registerDevice({
    required String token,
    required String languageCode,
    required List<String> topics,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/v1/devices',
        data: {
          'token': token,
          'language': languageCode,
          // Topics are language-suffixed by the caller: `breaking_so`.
          'topics': topics,
        },
      );
    } catch (e, st) {
      throw ApiExceptionMapper.map(e, st);
    }
  }

  Future<T> _get<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      final body = res.data;
      if (body == null) {
        throw const Failure(
          kind: FailureKind.malformedResponse,
          code: 'EMPTY_BODY',
        );
      }
      return parse(body);
    } catch (e, st) {
      throw ApiExceptionMapper.map(e, st);
    }
  }

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<dynamic>(path, queryParameters: query);
      final body = res.data;
      // Tolerate both a bare array and a `{data: [...]}` envelope; list
      // endpoints in the contract use the envelope, but a proxy that unwraps
      // it should not take the app down.
      final rows = switch (body) {
        List<dynamic>() => body,
        Map<String, dynamic>() => body['data'] as List<dynamic>? ?? const [],
        _ => const <dynamic>[],
      };
      return rows
          .cast<Map<String, dynamic>>()
          .map(parse)
          .toList(growable: false);
    } catch (e, st) {
      throw ApiExceptionMapper.map(e, st);
    }
  }

  Future<PagedDto<T>> _getPaged<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      final body = res.data;
      if (body == null) {
        throw const Failure(
          kind: FailureKind.malformedResponse,
          code: 'EMPTY_BODY',
        );
      }
      return PagedDto<T>.fromJson(
        body,
        (json) => parse(json! as Map<String, dynamic>),
      );
    } catch (e, st) {
      throw ApiExceptionMapper.map(e, st);
    }
  }
}
