import 'package:actual/common/model/cursor_pagination_model.dart';
import 'package:actual/common/model/model_with_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/pagination_params.dart';
import '../repository/base_pagination_repository.dart';

// T -> paginate() 함수를 통해 가져오는 값들의 실제 데이터 타입. (모델의 타입)
// U -> PaginationProvider는 IBasePaginationRepository를 상속한 어떤 타입(U)을 받는다! (리포지토리의 타입)

// 페이지네이션에 사용할 모델의 타입과 리포지토리의 타입을 제너릭에 넣어주기만 하면
// PaginationProvider 클래스를 extend하는 모든 함수에 paginate()가 생긴다.
class PaginationProvider<T extends IModelWithId, U extends IBasePaginationRepository<T>>
    extends StateNotifier<CursorPaginationBase> {
  final U repository;

  PaginationProvider({
    required this.repository,
  }) : super(CursorPaginationLoading());

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
        final pState = state as CursorPagination<T>;

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
          final pState = state as CursorPagination<T>;

          state = CursorPaginationRefetching<T>(
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
        final pState = state as CursorPaginationFetchingMore<T>;
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
}
