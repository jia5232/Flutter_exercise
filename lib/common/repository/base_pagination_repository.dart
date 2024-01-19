import 'package:actual/common/model/model_with_dart.dart';

import '../model/cursor_pagination_model.dart';
import '../model/pagination_params.dart';

// 페이지네이션할 때, 해당 Repository가 동일한 형태의 paginate 함수를 사용한다는 것을 보장하기 위한 인터페이스
abstract class IBasePaginationRepository<T extends IModelWithId>{
  Future<CursorPagination<T>> paginate({
    PaginationParams? paginationParams = const PaginationParams(),
  });
}