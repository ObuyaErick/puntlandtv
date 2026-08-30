import 'package:json_annotation/json_annotation.dart';

part 'paged_dto.g.dart';

/// The pagination envelope every list endpoint returns.
///
/// Cursor-based rather than offset-based: a news feed has items inserted at
/// the head constantly, and offset pagination duplicates or skips rows every
/// time that happens mid-scroll.
@JsonSerializable(genericArgumentFactories: true)
class PagedDto<T> {
  const PagedDto({required this.data, this.nextCursor});

  factory PagedDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PagedDtoFromJson(json, fromJsonT);

  final List<T> data;

  /// Null when this is the last page.
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PagedDtoToJson(this, toJsonT);
}
