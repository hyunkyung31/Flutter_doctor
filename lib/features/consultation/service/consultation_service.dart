import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/consultation_doctor.dart';
import '../model/consultation_request.dart';

final class ConsultationService {
  const ConsultationService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ConsultationDoctor>> fetchDoctors({
    required String accessToken,
  }) async {
    try {
      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.doctors,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final data = response.data;

      List<dynamic> doctorList;

      if (data is List<dynamic>) {
        doctorList = data;
      } else if (data is Map<String, dynamic>) {
        final results =
            data['results'] ?? data['doctors'] ?? data['data'];

        doctorList = results is List<dynamic>
            ? results
            : <dynamic>[];
      } else {
        doctorList = <dynamic>[];
      }

      return doctorList
          .whereType<Map<String, dynamic>>()
          .map(ConsultationDoctor.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ConsultationServiceException(
        _extractErrorMessage(
          error,
          defaultMessage: '의사 목록을 불러오지 못했습니다.',
        ),
      );
    } catch (_) {
      throw const ConsultationServiceException(
        '의사 목록을 불러오지 못했습니다.',
      );
    }
  }

  Future<void> createConsultation({
    required String accessToken,
    required String patientId,
    required String receiverId,
    required String reason,
    required String priority,
    required String memo,
    required List<String> referenceTypes,
    String? examId,
  }) async {
    try {
      await _apiClient.dio.post<dynamic>(
        ApiEndpoints.consultations,
        data: {
          'patient_id': patientId,
          'receiver_id': receiverId,
          'reason': reason,
          'priority': priority,
          'memo': memo,
          'reference_types': referenceTypes,
          'exam_id': examId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
    } on DioException catch (error) {
      throw ConsultationServiceException(
        _extractErrorMessage(
          error,
          defaultMessage: '협진 요청 전송에 실패했습니다.',
        ),
      );
    } catch (_) {
      throw const ConsultationServiceException(
        '협진 요청 전송에 실패했습니다.',
      );
    }
  }

  Future<List<ConsultationRequest>> fetchReceivedConsultations({
    required String accessToken,
  }) async {
    try {
      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.consultations,
        queryParameters: const {'receiver': 'me'},
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      final data = response.data;
      final dynamic items = data is List
          ? data
          : data is Map
          ? data['results'] ?? data['consultations'] ?? data['data']
          : null;

      if (items is! List) {
        return const <ConsultationRequest>[];
      }

      return items
          .whereType<Map>()
          .map(
            (item) => ConsultationRequest.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw ConsultationServiceException(
        _extractErrorMessage(
          error,
          defaultMessage: '받은 협진 요청을 불러오지 못했습니다.',
        ),
      );
    } catch (_) {
      throw const ConsultationServiceException(
        '받은 협진 요청을 불러오지 못했습니다.',
      );
    }
  }

  Future<ConsultationRequest> updateConsultationStatus({
    required String accessToken,
    required String consultationId,
    required String status,
  }) async {
    try {
      final response = await _apiClient.dio.patch<dynamic>(
        ApiEndpoints.consultationStatus(consultationId),
        data: {'status': status},
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.data is! Map) {
        throw const ConsultationServiceException(
          '협진 상태 응답 형식이 올바르지 않습니다.',
        );
      }

      return ConsultationRequest.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw ConsultationServiceException(
        _extractErrorMessage(
          error,
          defaultMessage: '협진 상태를 변경하지 못했습니다.',
        ),
      );
    } on ConsultationServiceException {
      rethrow;
    } catch (_) {
      throw const ConsultationServiceException(
        '협진 상태를 변경하지 못했습니다.',
      );
    }
  }

  String _extractErrorMessage(
    DioException error, {
    required String defaultMessage,
  }) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }

      final message = data['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }

    return defaultMessage;
  }
}

final class ConsultationServiceException implements Exception {
  const ConsultationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
