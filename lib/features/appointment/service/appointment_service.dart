import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/appointment.dart';

final class AppointmentService {
  const AppointmentService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Appointment>> fetchAppointments({
    required String accessToken,
    String? status,
    String? date,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        query['status'] = status;
      }
      if (date != null && date.isNotEmpty) {
        query['date'] = date;
      }

      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.appointments,
        queryParameters: query.isEmpty ? null : query,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return _parseList(response.data);
    } on DioException catch (error) {
      throw AppointmentServiceException(
        _extractErrorMessage(
          error,
          defaultMessage: '예약 목록을 불러오지 못했습니다.',
        ),
      );
    } catch (_) {
      throw const AppointmentServiceException(
        '예약 목록을 불러오지 못했습니다.',
      );
    }
  }

  Future<Appointment> updateStatus({
    required String accessToken,
    required String appointmentId,
    required AppointmentStatus status,
  }) async {
    return _patch(
      accessToken: accessToken,
      appointmentId: appointmentId,
      data: {'status': status.name},
      defaultMessage: '예약 상태 변경에 실패했습니다.',
    );
  }

  Future<Appointment> _patch({
    required String accessToken,
    required String appointmentId,
    required Map<String, dynamic> data,
    required String defaultMessage,
  }) async {
    try {
      final response = await _apiClient.dio.patch<dynamic>(
        ApiEndpoints.appointmentDetail(appointmentId),
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      final body = response.data;
      if (body is! Map) {
        throw AppointmentServiceException(defaultMessage);
      }

      return Appointment.fromJson(Map<String, dynamic>.from(body));
    } on DioException catch (error) {
      throw AppointmentServiceException(
        _extractErrorMessage(error, defaultMessage: defaultMessage),
      );
    } on AppointmentServiceException {
      rethrow;
    } catch (_) {
      throw AppointmentServiceException(defaultMessage);
    }
  }

  List<Appointment> _parseList(dynamic data) {
    List<dynamic> raw;
    if (data is Map && data['results'] is List) {
      raw = data['results'] as List<dynamic>;
    } else if (data is List) {
      raw = data;
    } else {
      raw = const <dynamic>[];
    }

    final list = raw
        .whereType<Map>()
        .map((e) => Appointment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  String _extractErrorMessage(
    DioException error, {
    required String defaultMessage,
  }) {
    final data = error.response?.data;

    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return defaultMessage;
  }
}

final class AppointmentServiceException implements Exception {
  const AppointmentServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
