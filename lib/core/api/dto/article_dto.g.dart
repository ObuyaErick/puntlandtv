// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArticleSummaryDto _$ArticleSummaryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ArticleSummaryDto',
      json,
      ($checkedConvert) {
        final val = ArticleSummaryDto(
          slug: $checkedConvert('slug', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          categorySlug: $checkedConvert('category_slug', (v) => v as String),
          categoryName: $checkedConvert('category_name', (v) => v as String),
          publishedAt: $checkedConvert(
            'published_at',
            (v) => DateTime.parse(v as String),
          ),
          contentLocale: $checkedConvert('content_locale', (v) => v as String),
          excerpt: $checkedConvert('excerpt', (v) => v as String?),
          imageUrl: $checkedConvert('image_url', (v) => v as String?),
          readingMinutes: $checkedConvert(
            'reading_minutes',
            (v) => (v as num?)?.toInt(),
          ),
          isBreaking: $checkedConvert(
            'is_breaking',
            (v) => v as bool? ?? false,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'categorySlug': 'category_slug',
        'categoryName': 'category_name',
        'publishedAt': 'published_at',
        'contentLocale': 'content_locale',
        'imageUrl': 'image_url',
        'readingMinutes': 'reading_minutes',
        'isBreaking': 'is_breaking',
      },
    );

Map<String, dynamic> _$ArticleSummaryDtoToJson(ArticleSummaryDto instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'title': instance.title,
      'category_slug': instance.categorySlug,
      'category_name': instance.categoryName,
      'published_at': instance.publishedAt.toIso8601String(),
      'content_locale': instance.contentLocale,
      'excerpt': instance.excerpt,
      'image_url': instance.imageUrl,
      'reading_minutes': instance.readingMinutes,
      'is_breaking': instance.isBreaking,
    };

ArticleDetailDto _$ArticleDetailDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ArticleDetailDto',
      json,
      ($checkedConvert) {
        final val = ArticleDetailDto(
          slug: $checkedConvert('slug', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          categorySlug: $checkedConvert('category_slug', (v) => v as String),
          categoryName: $checkedConvert('category_name', (v) => v as String),
          publishedAt: $checkedConvert(
            'published_at',
            (v) => DateTime.parse(v as String),
          ),
          contentLocale: $checkedConvert('content_locale', (v) => v as String),
          bodyHtml: $checkedConvert('body_html', (v) => v as String),
          excerpt: $checkedConvert('excerpt', (v) => v as String?),
          imageUrl: $checkedConvert('image_url', (v) => v as String?),
          imageCaption: $checkedConvert('image_caption', (v) => v as String?),
          author: $checkedConvert('author', (v) => v as String?),
          readingMinutes: $checkedConvert(
            'reading_minutes',
            (v) => (v as num?)?.toInt(),
          ),
          relatedSlugs: $checkedConvert(
            'related_slugs',
            (v) =>
                (v as List<dynamic>?)?.map((e) => e as String).toList() ??
                const [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'categorySlug': 'category_slug',
        'categoryName': 'category_name',
        'publishedAt': 'published_at',
        'contentLocale': 'content_locale',
        'bodyHtml': 'body_html',
        'imageUrl': 'image_url',
        'imageCaption': 'image_caption',
        'readingMinutes': 'reading_minutes',
        'relatedSlugs': 'related_slugs',
      },
    );

Map<String, dynamic> _$ArticleDetailDtoToJson(ArticleDetailDto instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'title': instance.title,
      'category_slug': instance.categorySlug,
      'category_name': instance.categoryName,
      'published_at': instance.publishedAt.toIso8601String(),
      'content_locale': instance.contentLocale,
      'body_html': instance.bodyHtml,
      'excerpt': instance.excerpt,
      'image_url': instance.imageUrl,
      'image_caption': instance.imageCaption,
      'author': instance.author,
      'reading_minutes': instance.readingMinutes,
      'related_slugs': instance.relatedSlugs,
    };
