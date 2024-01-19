import 'package:actual/common/dio/dio.dart';
import 'package:actual/common/repository/base_pagination_repository.dart';
import 'package:actual/rating/model/rating_model.dart';
import 'package:dio/dio.dart' hide Headers; //레트로핏에서 가져오는 헤더 클래스를 써야한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/http.dart';

import '../../common/const/data.dart';
import '../../common/model/cursor_pagination_model.dart';
import '../../common/model/pagination_params.dart';

part 'restaurant_rating_repository.g.dart';

final restaurantRatingRepositoryProvider =
    Provider.family<RestaurantRatingRepository, String>((ref, id) {
      final dio = ref.watch(dioProvider);
      return RestaurantRatingRepository(dio, baseUrl: 'http://$ip/restaurant/$id/rating');
    });

// http://ip/restaurant/:rid/rating
@RestApi()
abstract class RestaurantRatingRepository implements IBasePaginationRepository<RatingModel>{
  factory RestaurantRatingRepository(Dio dio, {String baseUrl}) =
      _RestaurantRatingRepository;

  @GET('/')
  @Headers({
    'accessToken': 'true',
  })
  Future<CursorPagination<RatingModel>> paginate({
    @Queries() PaginationParams? paginationParams = const PaginationParams(),
    //@Queries() -> PaginationParams 클래스의 값들이 자동으로 쿼리로 변환되어서 요청할 때 들어감!
  });
}
