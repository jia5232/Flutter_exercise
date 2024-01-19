// 캐시를 관리하는 모든 provider들은 전부 다 state notifier provider로 만든다.
import 'package:actual/common/model/cursor_pagination_model.dart';
import 'package:actual/common/model/pagination_params.dart';
import 'package:actual/restaurant/model/restaurant_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/restaurant_repository.dart';

/* restaurantDetailProvider */

// Provider.family<RestaurantModel, String>
// provider에서 받아오는 값은 RestaurantModel인데 family로 입력하는 값은 id(String)이다.
final restaurantDetailProvider =
    Provider.family<RestaurantModel?, String>((ref, id) {
  final state = ref.watch(restaurantProvider);
  // restaurantProvider가 변경되면 restaurantDetailProvider를 계속 새로 만들 수 있다.

  if (state is! CursorPagination) { //
    //CursorPagination이 아니라는 것은 데이터가 restaurantProvider에 없다는 뜻이다.
    return null;
  }

  return state.data.firstWhere((element) => element.id == id);
});

/* restaurantProvider */

final restaurantProvider =
    StateNotifierProvider<RestaurantStateNotifier, CursorPaginationBase>((ref) {
  final repository = ref.watch(restaurantRepositoryProvider);
  final notifier = RestaurantStateNotifier(repository: repository);
  return notifier;
});

class RestaurantStateNotifier extends StateNotifier<CursorPaginationBase> {
  final RestaurantRepository repository;

  RestaurantStateNotifier({
    required this.repository,
  }) : super(CursorPaginationLoading()) {
    //생성자 안에서 바로 paginate()실행 -> RestaurantStateNotifier가 생성이 되는 순간에 paginate()가 실행됨.
    paginate();
  }

  Future<void> paginate({
    int fetchCount = 20,
    // fetchMore -> 앱의 스크롤이 맨 아래까지 가서 추가로 더 가져와야 함.
    bool fetchMore = false,
    // forceRefetch -> 강제로 다시 로딩함.
    bool forceRefetch = false,
  }) async {
    try {
      // 5가지 가능성 (state의 상태)
      // 1) CursorPagination - 정상적으로 데이터가 있는 상태
      // 2) CursorPaginationLoading - 데이터가 로딩중인 상태 (현재 캐시 없음)
      // 3) CursorPaginationError - 에러가 있는 상태
      // 4) CursorPaginationRefetching - 첫번째 페이지부터 다시 데이터를 가져올 때
      // 5) CursorPaginationFetchMore - 추가 데이터를 paginate 해오라는 요청을 받았을 때

      // 바로 반환하는 상황
      // 1) hasMore = false (기존 상태에서 이미 다음 데이터가 없다는 값을 들고 있다면)
      if (state is CursorPagination && !forceRefetch) {
        //CursorPagination 타입인 것들만 들어오므로 Loading, Error는 상관이 없다!
        final pState = state as CursorPagination;

        if (!pState.meta.hasMore) {
          //hasMore=false이면 바로 리턴.
          return;
        }
      }

      // 2) 로딩중 = fetchMore: true
      // but 로딩중인데 fetchMore: false이면 새로고침의 의도가 있을 수 있다., 함수로직을 그대로 실행한다.
      final isLoading = state is CursorPaginationLoading;
      final isRefetching = state is CursorPaginationRefetching;
      final isFetchingMore = state is CursorPaginationFetchingMore;

      if (fetchMore && (isLoading || isRefetching || isFetchingMore)) {
        return;
      }

      // PaginationParams 생성
      PaginationParams paginationParams = PaginationParams(
        count: fetchCount,
      );

      // fetchMore -> 데이터를 추가로 더 가져오는 상황
      // fetchMore: true라는건 데이터가 있는 상황에서 더 가져오려고 하는 것이므로 무조건 CursorPagination을 extend한 state이다.
      if (fetchMore) {
        final pState = state as CursorPagination;

        state = CursorPaginationFetchingMore(
          meta: pState.meta,
          data: pState.data,
        );

        paginationParams = paginationParams.copyWith(
          after: pState.data.last.id,
        );
      }
      // 데이터를 처음부터 가져오는 상황
      else {
        // 만약 데이터가 있는 상황이면 기존 데이터 유지한 채로 API 요청을 진행.
        if (state is CursorPagination && !forceRefetch) {
          final pState = state as CursorPagination;

          state = CursorPaginationRefetching(
            //데이터는 있는데 새로고침중이다!
            meta: pState.meta,
            data: pState.data,
          );
        } else {
          // 나머지 상황
          state = CursorPaginationLoading();
        }
      }

      final resp = await repository.paginate(
        paginationParams: paginationParams,
      );

      if (state is CursorPaginationFetchingMore) {
        final pState = state as CursorPaginationFetchingMore;
        // 기존 데이터에 새로운 데이터 추가
        state = resp.copyWith(data: [
          ...pState.data, //기존에 있던 데이터
          ...resp.data, //새로운 데이터
        ]);
      } else {
        //fetchMore이 아닐 경우에는 paginationParams가 변경되지 않으므로, resp가 맨 처음 그대로다!
        state = resp;
      }
    } catch (e) {
      state = CursorPaginationError(message: '데이터를 가져오지 못했습니다.');
    }
  }

  void getDetail({
    required String id,
  }) async {
    // 아직 데이터가 하나도 없는 상태라면 state가 CursorPagination이 아니라면
    // 데이터를 가져오는 시도를 한다.
    if (state is! CursorPagination) {
      await this.paginate();
    }

    // state가 Cursorpagination이 아닐때, 그냥 리턴
    if (state is! CursorPagination) {
      return;
    }

    // 이제 state는 무조건 CursorPagination 이다.
    // pState -> RestaurantModel의 리스트
    final pState = state as CursorPagination;

    // resp -> RestaurantDetailModel의 리스트
    final resp = await repository.getRestaurantDetail(id: id);

    state = pState.copyWith( // 우리가 요청한 id의 요소만 RestaurantDetailModel로 바뀌어 들어간다.
      data: pState.data.map<RestaurantModel>((e) => e.id == id ? resp : e).toList(),
    );

  }
}
