import 'package:actual/common/const/data.dart';
import 'package:actual/common/secure_storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  
  final storage = ref.watch(secureStorageProvider);

  dio.interceptors.add(
    CustomInterceptor(storage: storage),
  );

  return dio;
});

class CustomInterceptor extends Interceptor {
  final FlutterSecureStorage storage;

  CustomInterceptor({
    required this.storage,
  });

  // 1) 요청을 보낼 때 -> CustomInterceptor가 적용된 모든 dio에서 요청을 보낼 때 마다 실행됨
  // 요청이 보내질때마다
  // 만약에 요청의 Header에 accessToken: true라는 값이 있다면
  // 실제 토큰을 storage에서 가져와서
  // 'authorization': 'Bearer $token'로 헤더를 변경한다.
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    print('[REQ] [${options.method}] [${options.uri}]');
    //options.method : 요청 메소드

    //options.headers -> 내가 이제 보내려는 요청의 헤더!
    if (options.headers['accessToken'] == 'true') {
      options.headers.remove('accessToken');

      final token = await storage.read(key: ACCESS_TOKEN_KEY);

      options.headers.addAll({
        'authorization': 'Bearer $token',
      });
    }

    if (options.headers['refreshToken'] == 'true') {
      options.headers.remove('refreshToken');

      final token = await storage.read(key: REFRESH_TOKEN_KEY);

      options.headers.addAll({
        'authorization': 'Bearer $token',
      });
    }

    return super.onRequest(options, handler); //요청은 여기서 보내진다!
  }

  // 2) 응답을 받을 떄 (정상)
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print(
        '[RES] [${response.requestOptions.method}] [${response.requestOptions.uri}]');

    super.onResponse(response, handler);
  }

  // 3) 에러가 났을 때
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401에러 (토큰에서 문제가 있는 경우)
    // 토큰을 재발급받는 시도를 하고, 토큰이 재발급되면 다시 새로운 토큰으로 요청한다.
    print('[ERR] [${err.requestOptions.method}] [${err.requestOptions.uri}]');

    final refreshToken = await storage.read(key: REFRESH_TOKEN_KEY);

    // refreshToken이 아예 없으면 에러를 던진다.
    if (refreshToken == null) {
      // 에러를 던질때는 handler.reject를 사용한다.
      return handler.reject(err);
    }

    // 현재 오류가 401 오류인지.
    final isStatus401 = err.response?.statusCode == 401;

    // 현재 오류가 토큰을 리프레쉬하다가 난 에러인지.
    final isPathRefresh = err.requestOptions.path == '/auth/token';

    if (isStatus401 && !isPathRefresh) {
      //토큰 리프레쉬하려던게 아닌데 오류가 남 -> 액세스 토큰 만료, 다시 발급받자
      final dio = Dio();

      try {
        final resp = await dio.post(
          'http://$ip/auth/token',
          options: Options(headers: {
            'authorization': 'Bearer $refreshToken',
          }),
        );

        final accessToken = resp.data['accessToken'];

        //이 에러를 발생시킨 요청과 관련된 모든 옵션들을 담아둔다.
        final options = err.requestOptions;

        options.headers.addAll({
          'authorization': 'Bearer $accessToken',
        });
        await storage.write(key: ACCESS_TOKEN_KEY, value: accessToken);

        //이 에러를 발생시킨 요청과 관련된 모든 옵션들에서 헤더의 토큰만 바꾼 다음 요청 재전송
        final response = await dio.fetch(options);

        //handler.resolve -> 새로보낸 요청의 응답을 반환해준다. (요청이 성공했다!)
        return handler.resolve(response);
      } on DioException catch (e) {
        //handler.reject -> 그대로 에러를 반환해준다.
        return handler.reject(e);
      }
    }

    super.onError(err, handler);
  }
}
