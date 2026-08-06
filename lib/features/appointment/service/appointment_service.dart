import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/appointment.dart';

final class AppointmentService {
  const AppointmentService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Appointment>> fetchAppointments({
    required String accessToken,
    String? date,
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (date != null && date.trim().isNotEmpty) {
        queryParameters['date'] = date.trim();
      }

      if (status != null && status.trim().isNotEmpty) {
        queryParameters['status'] = status.trim();
      }

      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.appointments,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return _parseAppointmentList(response.data);
    } on DioException catch (error) {
      throw AppointmentServiceException(
        _messageFromDioException(
          error,
          defaultMessage: '예약 목록을 불러오지 못했습니다.',
          notFoundMessage: '예약 목록 API 주소를 찾을 수 없습니다.',
        ),
      );
    } on AppointmentServiceException {
      rethrow;
    } catch (_) {
      throw const AppointmentServiceException(
        '예약 목록을 불러오는 중 오류가 발생했습니다.',
      );
    }
  }

  Future<Appointment> updateAppointmentStatus({
    required String accessToken,
    required int appointmentId,
    required String status,
  }) async {
    try {
      final response = await _apiClient.dio.patch<dynamic>(
        ApiEndpoints.appointmentDetail(appointmentId),
        data: {
          'status': status.trim(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data;

      if (data is! Map) {
        throw const AppointmentServiceException(
          '예약 상태 변경 응답 형식이 올바르지 않습니다.',
        );
      }

      return Appointment.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw AppointmentServiceException(
        _messageFromDioException(
          error,
          defaultMessage: '예약 상태를 변경하지 못했습니다.',
          notFoundMessage: '예약을 찾을 수 없습니다.',
        ),
      );
    } on AppointmentServiceException {
      rethrow;
    } catch (_) {
      throw const AppointmentServiceException(
        '예약 상태를 변경하는 중 오류가 발생했습니다.',
      );
    }
  }

  List<Appointment> _parseAppointmentList(dynamic responseData) {
    if (responseData is List) {
      return responseData
          .whereType<Map>()
          .map(
            (json) => Appointment.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    }

    if (responseData is! Map) {
      throw const AppointmentServiceException(
        '예약 목록 응답 형식이 올바르지 않습니다.',
      );
    }

    final responseMap = Map<String, dynamic>.from(responseData);
    final results =
        responseMap['results'] ??
        responseMap['appointments'] ??
        responseMap['data'];

    if (results is! List) {
      throw const AppointmentServiceException(
        '예약 목록 응답에 예약 배열이 없습니다.',
      );
    }

    return results
        .whereType<Map>()
        .map(
          (json) => Appointment.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }

  String _messageFromDioException(
    DioException error, {
    required String defaultMessage,
    required String notFoundMessage,
  }) {
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

        if (statusCode == 400) {
          return '잘못된 요청입니다.';
        }

        if (statusCode == 401 || statusCode == 403) {
          return '로그인 정보가 만료되었습니다. 다시 로그인해 주세요.';
        }

        if (statusCode == 404) {
          return notFoundMessage;
        }

        if (statusCode != null && statusCode >= 500) {
          return '서버 내부 오류가 발생했습니다.';
        }

        return defaultMessage;

      case DioExceptionType.cancel:
        return '요청이 취소되었습니다.';

      case DioExceptionType.badCertificate:
        return '서버 인증서를 확인할 수 없습니다.';

      case DioExceptionType.unknown:
        return '네트워크 오류가 발생했습니다.';
    }
  }
}

final class AppointmentServiceException implements Exception {
  const AppointmentServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
