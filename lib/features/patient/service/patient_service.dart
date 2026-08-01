import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/patient.dart';

final class PatientService {
  PatientService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Patient>> fetchPatients({
    required String accessToken,
  }) async {
    try {
      final response =
          await _apiClient.dio.get<dynamic>(
        ApiEndpoints.patients,
        options: Options(
          headers: {
            'Authorization':
                'Bearer $accessToken',
          },
        ),
      );

      print(
        '환자 목록 상태 코드: ${response.statusCode}',
      );

      print(
        '환자 목록 응답 데이터: ${response.data}',
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw const PatientServiceException(
          '환자 목록 응답 형식이 올바르지 않습니다.',
        );
      }

      final responseMap =
          Map<String, dynamic>.from(
        responseData,
      );

      final results = responseMap['results'];

      if (results is! List) {
        throw const PatientServiceException(
          '환자 목록 응답에 results가 없습니다.',
        );
      }

      return results
          .whereType<Map>()
          .map(
            (json) => Patient.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } on DioException catch (error) {
      print(
        '환자 API 오류 상태: '
        '${error.response?.statusCode}',
      );

      print(
        '환자 API 오류 응답: '
        '${error.response?.data}',
      );

      throw PatientServiceException(
        _messageFromDioException(error),
      );
    } on PatientServiceException {
      rethrow;
    } on TypeError {
      throw const PatientServiceException(
        '환자 데이터 형식이 올바르지 않습니다.',
      );
    } on Exception catch (error) {
      print('환자 목록 알 수 없는 오류: $error');

      throw const PatientServiceException(
        '환자 목록을 불러오는 중 오류가 발생했습니다.',
      );
    }
  }

String _messageFromDioException(
  DioException error,
  ) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return '서버 응답 시간이 초과되었습니다.';

    case DioExceptionType.connectionError:
      return '서버에 연결할 수 없습니다.';

    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        return '로그인 정보가 만료되었습니다. 다시 로그인해 주세요.';
      }

      if (statusCode == 404) {
        return '환자 목록 API 주소를 찾을 수 없습니다.';
      }

      if (statusCode == 500) {
        return '서버 내부 오류가 발생했습니다.';
      }

      return '환자 목록을 불러오지 못했습니다.';

    case DioExceptionType.cancel:
      return '환자 목록 요청이 취소되었습니다.';

    case DioExceptionType.badCertificate:
      return '서버 인증서를 확인할 수 없습니다.';

    case DioExceptionType.unknown:
      return '네트워크 오류가 발생했습니다.';
    }
  }
}

final class PatientServiceException
    implements Exception {
  const PatientServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}