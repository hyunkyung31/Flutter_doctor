import 'package:dio/dio.dart';

import 'api_endpoints.dart';

// Django REST API와 통신할 때 사용하는 공통 HTTP 클라이언트
final class ApiClient {
  ApiClient({Dio? dio})
      : dio = dio ??
            Dio(
              BaseOptions(
                // Django 서버 기본 주소
                baseUrl: ApiEndpoints.baseUrl,
                // 서버 연결 허용 최대 시간
                connectTimeout: const Duration(seconds: 10),
                // 요청 데이터를 서버로 보내는 데 허용되는 최대 시간
                sendTimeout: const Duration(seconds: 15),
                // 서버 응답을 받는 데 허용되는 최대 시간
                receiveTimeout: const Duration(seconds: 15),
                // Django REST API의 JSON 응답을 Map/List 형태로 변환
                responseType: ResponseType.json,
                // 400, 401, 500 등의 오류 응답 데이터도 받을 수 있도록 설정
                receiveDataWhenStatusError: true,
                // 모든 API 요청에서 공통으로 사용할 HTTP 헤더
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    // 요청과 응답 내용을 Flutter 실행 터미널에서 확인하기 위한 로그 설정
    this.dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (object) {
          print(object);
        },
      ),
    );
  }

  final Dio dio;
}