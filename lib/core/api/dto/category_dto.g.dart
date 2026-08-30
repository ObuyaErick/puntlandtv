// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryDto _$CategoryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CategoryDto', json, ($checkedConvert) {
      final val = CategoryDto(
        slug: $checkedConvert('slug', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        isDefault: $checkedConvert('is_default', (v) => v as bool? ?? false),
      );
      return val;
    }, fieldKeyMap: const {'isDefault': 'is_default'});

Map<String, dynamic> _$CategoryDtoToJson(CategoryDto instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'name': instance.name,
      'is_default': instance.isDefault,
    };
