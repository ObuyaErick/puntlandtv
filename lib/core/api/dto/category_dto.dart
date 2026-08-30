import 'package:json_annotation/json_annotation.dart';

part 'category_dto.g.dart';

@JsonSerializable()
class CategoryDto {
  const CategoryDto({
    required this.slug,
    required this.name,
    this.isDefault = false,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryDtoFromJson(json);

  /// Stable machine identifier. The app keys off this, never off [name] —
  /// [name] is localised and changes with `Accept-Language`.
  final String slug;

  /// Display name, already localised by the backend.
  final String name;

  @JsonKey(name: 'is_default')
  final bool isDefault;

  Map<String, dynamic> toJson() => _$CategoryDtoToJson(this);
}
