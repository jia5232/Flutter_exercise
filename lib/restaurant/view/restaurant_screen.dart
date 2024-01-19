import 'package:actual/common/dio/dio.dart';
import 'package:actual/common/model/cursor_pagination_model.dart';
import 'package:actual/restaurant/component/restaurant_card.dart';
import 'package:actual/restaurant/model/restaurant_model.dart';
import 'package:actual/restaurant/provider/restaurant_provider.dart';
import 'package:actual/restaurant/view/restaurant_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/const/data.dart';
import '../repository/restaurant_repository.dart';

class RestaurantScreen extends ConsumerStatefulWidget {
  const RestaurantScreen({super.key});

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> {
  final ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.addListener(scrollListener);
  }

  void scrollListener() {
    // 현재 길이가 최대 길이보다 조금 덜되는 위치까지 왔다면 새로운 데이터 추가 요청
    // controller.offset -> 스크롤 컨트롤러의 현재 위치
    if (controller.offset > controller.position.maxScrollExtent - 300) {
      ref.read(restaurantProvider.notifier).paginate(
            fetchMore: true,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(restaurantProvider);
    // restaurantProvider가 생성될때 RestaurantStateNotifier 생성자에서 paginate()실행함.

    // 완전 처음 로딩일 때
    if (data is CursorPaginationLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    // 에러가 났을 때
    if (data is CursorPaginationError) {
      return Center(
        child: Text(data.message),
      );
    }

    // CursorPagination
    // CursorPaginationFetchingMore
    // CursorPaginationRefetching

    final cp = data as CursorPagination;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.separated(
        controller: controller,
        itemCount: cp.data.length + 1, // 맨 밑으로 갔을때 하나 더 추가해주려고!
        itemBuilder: (_, index) {
          if (index == cp.data.length) {
            // 맨 마지막 아이템까지 갔으면
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Center(
                child: data is CursorPaginationFetchingMore
                    ? CircularProgressIndicator()
                    : Text("마지막 데이터입니다!"),
              ),
            );
          }

          final parsedItem = cp.data[index];
          return GestureDetector(
            child: RestaurantCard.fromModel(model: parsedItem),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RestaurantDetailScreen(
                    id: parsedItem.id,
                  ),
                ),
              );
            },
          );
        },
        separatorBuilder: (_, index) {
          //각각의 아이템 사이사이
          return SizedBox(height: 16.0);
        },
      ),
    );
  }
}
