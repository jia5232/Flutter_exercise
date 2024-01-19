import 'package:actual/common/dio/dio.dart';
import 'package:actual/common/model/cursor_pagination_model.dart';
import 'package:actual/common/model/pagination_params.dart';
import 'package:actual/common/repository/base_pagination_repository.dart';
import 'package:actual/restaurant/model/restaurant_model.dart';
import 'package:dio/dio.dart' hide Headers;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/http.dart';

import '../../common/const/data.dart';
import '../model/restaurant_detail_model.dart';

part 'restaurant_repository.g.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>(
  (ref) {
    final dio = ref.watch(dioProvider);
    final repository = RestaurantRepository(dio, baseUrl: 'http://$ip/restaurant');
    return repository;
  },
);

//abstract 클래스이므로 함수의 바디는 지운다!
//어떤 값이 매개변수로 들어가야 하는지 + 어떤값이 반환되어야 하는지만 적어준다.
//실제로 api 요청이 들어오는 것과 완전히 똑같은 클래스를 반환값으로 넣어줘야 한다!
@RestApi()
abstract class RestaurantRepository implements IBasePaginationRepository<RestaurantModel>{
  //repository 클래스는 인스턴스화가 안되게 abstract로 선언해야 한다.
  // http://$ip/restaurant 까지는 baseUrl에 공통으로 넣어주고 나머지는 따로 입력
  factory RestaurantRepository(Dio dio, {String baseUrl}) =
      _RestaurantRepository;

  // http://$ip/restaurant/
  @GET('/')
  @Headers({
    'accessToken': 'true',
  })
  Future<CursorPagination<RestaurantModel>> paginate({
    @Queries() PaginationParams? paginationParams = const PaginationParams(),
    //@Queries() -> PaginationParams 클래스의 값들이 자동으로 쿼리로 변환되어서 요청할 때 들어감!
});

  // http://$ip/restaurant/id/
  @GET('/{id}')
  @Headers({
    'accessToken': 'true', //dio의 interceptor에서 accesstoken을 보내준다.
  })
  Future<RestaurantDetailModel> getRestaurantDetail({
    @Path() required String id,
  });
}
