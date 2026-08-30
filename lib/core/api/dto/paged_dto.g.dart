// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paged_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PagedDto<T> _$PagedDtoFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => $checkedCreate('PagedDto', json, ($checkedConvert) {
  final val = PagedDto<T>(
    data: $checkedConvert(
      'data',
      (v) => (v as List<dynamic>).map(fromJsonT).toList(),
    ),
    nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$PagedDtoToJson<T>(
  PagedDto<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'data': instance.data.map(toJsonT).toList(),
  'next_cursor': instance.nextCursor,
};
