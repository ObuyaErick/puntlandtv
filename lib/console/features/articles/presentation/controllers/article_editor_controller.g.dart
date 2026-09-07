// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The article the editor is working on.
///
/// A provider of its own rather than a lookup in the list: the editor is a URL
/// an editor can be sent, so it has to be able to load one story without the
/// list ever having been fetched.

@ProviderFor(articleById)
final articleByIdProvider = ArticleByIdFamily._();

/// The article the editor is working on.
///
/// A provider of its own rather than a lookup in the list: the editor is a URL
/// an editor can be sent, so it has to be able to load one story without the
/// list ever having been fetched.

final class ArticleByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdminArticleDto>,
          AdminArticleDto,
          FutureOr<AdminArticleDto>
        >
    with $FutureModifier<AdminArticleDto>, $FutureProvider<AdminArticleDto> {
  /// The article the editor is working on.
  ///
  /// A provider of its own rather than a lookup in the list: the editor is a URL
  /// an editor can be sent, so it has to be able to load one story without the
  /// list ever having been fetched.
  ArticleByIdProvider._({
    required ArticleByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'articleByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$articleByIdHash();

  @override
  String toString() {
    return r'articleByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AdminArticleDto> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdminArticleDto> create(Ref ref) {
    final argument = this.argument as String;
    return articleById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ArticleByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$articleByIdHash() => r'6ced2dd060f1bd0c44f3cd9e5bfa8673953b6ef2';

/// The article the editor is working on.
///
/// A provider of its own rather than a lookup in the list: the editor is a URL
/// an editor can be sent, so it has to be able to load one story without the
/// list ever having been fetched.

final class ArticleByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AdminArticleDto>, String> {
  ArticleByIdFamily._()
    : super(
        retry: null,
        name: r'articleByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The article the editor is working on.
  ///
  /// A provider of its own rather than a lookup in the list: the editor is a URL
  /// an editor can be sent, so it has to be able to load one story without the
  /// list ever having been fetched.

  ArticleByIdProvider call(String id) =>
      ArticleByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'articleByIdProvider';
}
