import 'package:dio/dio.dart';
import 'api_endpoints.dart';

// Django REST API 와 통신할 때 사용하는 공통 HTTP 클라이언트
final class ApiClient {
  ApiClient({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiEndpoints.baseUrl, // Django 서버 기본 주소
              connectTimeout: const Duration(seconds: 10), // 서버 연결 허용 최대 시간
              sendTimeout: const Duration(
                seconds: 15,
              ), // 요청 데이터 서버로 보내는 데 허용 시간
              receiveTimeout: const Duration(seconds: 15), // 서버 응답 받는 데 허용 시간
              responseType: ResponseType
                  .json, // Django REST API가 json을 반환하면 Dio가 응답 데이터를 Map 형태로 처리
              receiveDataWhenStatusError: true,
              headers: const {
                // 모든 API 요청에서 공통으로 사용할 HTTP 헤더
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );
  final Dio dio;
}
