import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../error/failure.dart';
import 'dto/app_config_dto.dart';
import 'dto/article_dto.dart';
import 'dto/category_dto.dart';
import 'dto/live_dto.dart';
import 'dto/paged_dto.dart';
import 'dto/program_dto.dart';
import 'puntland_api.dart';

/// [PuntlandApi] backed by bundled JSON.
///
/// The backend does not exist yet, and the MVP plan calls for building against
/// fixtures until the contract is live. Because this satisfies the same
/// interface as [HttpPuntlandApi], every screen, repository, mapper and
/// provider above it is exercised for real — only the bytes' origin differs.
/// Switching to the live API is a one-line change in `api_providers.dart`.
///
/// It deliberately simulates the unpleasant parts of a real network:
/// latency, cursor pagination, and (optionally) failures.
///
/// This is the one file in the API layer that touches Flutter, and only for
/// `rootBundle`. If that ever becomes a problem for pure-Dart testing, inject
/// an asset-loading function instead.
class FixturePuntlandApi implements PuntlandApi {
  FixturePuntlandApi({
    required String Function() languageCode,
    this.latency = const Duration(milliseconds: 450),
    this.failureRate = 0,
    // ignore: prefer_initializing_formals
  }) : _languageCode = languageCode;

  /// Read on every call so a language change is picked up without rebuilding
  /// the client.
  final String Function() _languageCode;

  /// Simulated round-trip time. Roughly a good 3G connection — enough that
  /// skeleton states are actually visible during development, which is how
  /// they end up designed rather than forgotten.
  final Duration latency;

  /// 0–1. Set above zero to exercise error and retry states.
  final double failureRate;

  final _random = Random();
  final _cache = <String, Map<String, dynamic>>{};

  Future<Map<String, dynamic>> _load() async {
    final lang = _languageCode() == 'so' ? 'so' : 'en';
    final cached = _cache[lang];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/fixtures/$lang.json');
    final decoded = _resolveTimestamps(
      json.decode(raw) as Map<String, dynamic>,
    );
    _cache[lang] = decoded;
    return decoded;
  }

  Future<T> _respond<T>(T Function(Map<String, dynamic> data) build) async {
    await Future<void>.delayed(latency);
    if (failureRate > 0 && _random.nextDouble() < failureRate) {
      throw const Failure(kind: FailureKind.timeout, code: 'NETWORK_TIMEOUT');
    }
    return build(await _load());
  }

  @override
  Future<AppConfigDto> fetchConfig() => _respond(
    (d) => AppConfigDto.fromJson(d['config'] as Map<String, dynamic>),
  );

  @override
  Future<LiveStatusDto> fetchLiveStatus() => _respond(
    (d) => LiveStatusDto.fromJson(d['live'] as Map<String, dynamic>),
  );

  @override
  Future<RadioStatusDto> fetchRadioStatus() => _respond(
    (d) => RadioStatusDto.fromJson(d['radio'] as Map<String, dynamic>),
  );

  @override
  Future<List<CategoryDto>> fetchCategories() => _respond(
    (d) => (d['categories'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CategoryDto.fromJson)
        .toList(growable: false),
  );

  @override
  Future<PagedDto<ArticleSummaryDto>> fetchArticles({
    String? categorySlug,
    String? cursor,
    int limit = 20,
  }) => _respond((d) {
    var rows = (d['articles'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList();

    if (categorySlug != null && categorySlug != 'top') {
      rows = rows
          .where((r) => r['category_slug'] == categorySlug)
          .toList(growable: false);
    }

    // Cursor is the index of the first item of the next page. Opaque to
    // the client by contract, which is exactly how the real API will
    // behave — the app must never do arithmetic on it.
    final start = int.tryParse(cursor ?? '0') ?? 0;
    final end = min(start + limit, rows.length);
    final page = rows.sublist(min(start, rows.length), end);

    return PagedDto<ArticleSummaryDto>(
      data: page.map(ArticleSummaryDto.fromJson).toList(growable: false),
      nextCursor: end < rows.length ? end.toString() : null,
    );
  });

  @override
  Future<ArticleDetailDto> fetchArticle(String slug) => _respond((d) {
    final summary = (d['articles'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (r) => r['slug'] == slug,
          orElse: () =>
              throw const Failure(kind: FailureKind.notFound, code: 'HTTP_404'),
        );

    final bodies = d['article_bodies'] as Map<String, dynamic>;
    // Articles without authored fixture bodies fall back to the one full
    // body, so every article in the feed opens to something readable.
    final body = (bodies[slug] ?? bodies.values.first) as Map<String, dynamic>;

    return ArticleDetailDto.fromJson({
      ...summary,
      'body_html': body['body_html'],
      'author': body['author'],
      'image_caption': body['image_caption'],
      'related_slugs': (body['related_slugs'] as List<dynamic>)
          .where((s) => s != slug)
          .toList(),
    });
  });

  @override
  Future<List<ArticleSummaryDto>> fetchArticlesBySlugs(List<String> slugs) =>
      _respond((d) {
        final bySlug = {
          for (final r
              in (d['articles'] as List<dynamic>).cast<Map<String, dynamic>>())
            r['slug'] as String: r,
        };
        return slugs
            .map((s) => bySlug[s])
            .whereType<Map<String, dynamic>>()
            .map(ArticleSummaryDto.fromJson)
            .toList(growable: false);
      });

  @override
  Future<List<ProgramDto>> fetchPrograms() => _respond(
    (d) => (d['programs'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ProgramDto.fromJson)
        .toList(growable: false),
  );

  @override
  Future<PagedDto<EpisodeDto>> fetchEpisodes({
    String? programId,
    String? cursor,
    int limit = 20,
  }) => _respond((d) {
    var rows = (d['episodes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList();
    if (programId != null) {
      rows = rows
          .where((r) => r['program_id'] == programId)
          .toList(growable: false);
    }
    final start = int.tryParse(cursor ?? '0') ?? 0;
    final end = min(start + limit, rows.length);
    return PagedDto<EpisodeDto>(
      data: rows
          .sublist(min(start, rows.length), end)
          .map(EpisodeDto.fromJson)
          .toList(growable: false),
      nextCursor: end < rows.length ? end.toString() : null,
    );
  });

  @override
  Future<void> registerDevice({
    required String token,
    required String languageCode,
    required List<String> topics,
  }) async {
    await Future<void>.delayed(latency);
  }

  /// Rewrites `{{now-2h}}` / `{{today 21:00}}` tokens into real ISO-8601
  /// timestamps at load time.
  ///
  /// Fixtures with hard-coded dates rot: within a week every story reads
  /// "6 months ago" and the relative-time formatting stops being testable.
  Map<String, dynamic> _resolveTimestamps(Map<String, dynamic> root) {
    final now = DateTime.now();

    Object? walk(Object? node) {
      if (node is Map<String, dynamic>) {
        return node.map((k, v) => MapEntry(k, walk(v)));
      }
      if (node is List) return node.map(walk).toList();
      if (node is! String) return node;

      final relative = RegExp(r'^\{\{now-(\d+)([mhd])\}\}$').firstMatch(node);
      if (relative != null) {
        final n = int.parse(relative.group(1)!);
        final delta = switch (relative.group(2)) {
          'm' => Duration(minutes: n),
          'h' => Duration(hours: n),
          _ => Duration(days: n),
        };
        return now.subtract(delta).toUtc().toIso8601String();
      }

      final clock = RegExp(r'^\{\{today (\d{2}):(\d{2})\}\}$').firstMatch(node);
      if (clock != null) {
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(clock.group(1)!),
          int.parse(clock.group(2)!),
        ).toUtc().toIso8601String();
      }

      return node;
    }

    return walk(root)! as Map<String, dynamic>;
  }
}
