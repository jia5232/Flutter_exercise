import 'package:actual/common/model/cursor_pagination_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/restaurant_rating_repository.dart';

final restaurantRatingProvider = StateNotifierProvider.family<RestaurantRatingStateNotifier, CursorPaginationBase, String>((ref, id){
  final repository = ref.watch(restaurantRatingRepositoryProvider(id));
  return RestaurantRatingStateNotifier(repository: repository);
});

class RestaurantRatingStateNotifier
    extends StateNotifier<CursorPaginationBase> {
  final RestaurantRatingRepository repository;

  RestaurantRatingStateNotifier({
    required this.repository,
  }) : super(
          CursorPaginationLoading(),
        );
}
