import 'package:json_annotation/json_annotation.dart';

import '../../restaurant/model/restaurant_model.dart';

part 'cursor_pagination_model.g.dart';

// CursorPagination이 CursorPaginationBase타입인지 확인을 했을 때 그 타입이 맞다고 나오는 것이 중요!
// CursorPagination 클래스를 두개의 상태를 나타내는 클래스로 나눈다 -> CursorPagination, CursorPaginationError

abstract class CursorPaginationBase {}

// 1. 에러일 때
class CursorPaginationError extends CursorPaginationBase {
  final String message;

  CursorPaginationError({
    required this.message,
  });
}

// 2. 로딩중일때
class CursorPaginationLoading extends CursorPaginationBase {}

// 3. 정상일 때
@JsonSerializable(
  genericArgumentFactories: true,
  //JsonSerializable을 생성할 때 genericArgument를 고려한 코드를 생성할 수 있다!
)
class CursorPagination<T> extends CursorPaginationBase {
  final CursorPaginationMeta meta;
  final List<T> data;

  CursorPagination({
    required this.meta,
    required this.data,
  });

  CursorPagination copyWith({
    CursorPaginationMeta? meta,
    List<T>? data,
  }) {
    return CursorPagination(
      meta: meta ?? this.meta,
      data: data ?? this.data,
    );
  }

  //T Function(Object? json) fromJsonT -> T타입이 어떻게 json으로부터 값을 받아오는지 정의를 해줘야 한다.
  //T가 어떤 타입으로 들어올지 모르기 때문에, 런타임에 정의를 해줘야 한다.. (그러면 빌드타임에 자동으로 fromjson을 생성해준다.)
  factory CursorPagination.fromJson(
          Map<String, dynamic> json, T Function(Object? json) fromJsonT) =>
      _$CursorPaginationFromJson(json, fromJsonT);
}

@JsonSerializable()
class CursorPaginationMeta {
  final int count;
  final bool hasMore;

  CursorPaginationMeta({
    required this.count,
    required this.hasMore,
  });

  CursorPaginationMeta copyWith({
    int? count,
    bool? hasMore,
  }) {
    return CursorPaginationMeta(
      count: count ?? this.count,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  factory CursorPaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$CursorPaginationMetaFromJson(json);
}

// 4. 새로고침 할때
class CursorPaginationRefetching<T> extends CursorPagination<T> {
  //이미 meta, data가 존재한다는 가정하에 사용하기 때문
  CursorPaginationRefetching({
    required super.meta,
    required super.data,
  });
}

// 5. 리스트의 맨 아래로 내려서 추가 데이터를 요청하는 중일때
class CursorPaginationFetchingMore<T> extends CursorPagination<T> {
  CursorPaginationFetchingMore({
    required super.meta,
    required super.data,
  });
}
