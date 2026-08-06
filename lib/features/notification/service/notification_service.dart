import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/app_notification.dart';
import '../model/notification_list_response.dart';

final class NotificationService {
  const NotificationService(this._apiClient);

  final ApiClient _apiClient;

  Options _options(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  Future<NotificationListResponse> fetchNotifications(
    String token, {
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.notifications,
        queryParameters: unreadOnly ? const {'unread': true} : null,
        options: _options(token),
      );

      final data = response.data;
      if (data is! Map) {
        throw const NotificationServiceException('알림 목록 응답 형식이 올바르지 않습니다.');
      }

      return NotificationListResponse.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw NotificationServiceException(
        _messageFromDioException(error, '알림 목록을 불러오지 못했습니다.'),
      );
    } on NotificationServiceException {
      rethrow;
    } catch (_) {
      throw const NotificationServiceException('알림 목록을 불러오지 못했습니다.');
    }
  }

  Future<AppNotification?> markAsRead(String token, int notificationId) async {
    try {
      final response = await _apiClient.dio.patch<dynamic>(
        ApiEndpoints.notificationRead(notificationId),
        options: _options(token),
      );

      final data = response.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final nested = map['notification'] ?? map['data'] ?? map['result'];
        if (nested is Map) {
          return AppNotification.fromJson(Map<String, dynamic>.from(nested));
        }
        if (map.containsKey('id')) {
          return AppNotification.fromJson(map);
        }
      }

      return null;
    } on DioException catch (error) {
      throw NotificationServiceException(
        _messageFromDioException(error, '알림을 읽음 처리하지 못했습니다.'),
      );
    } catch (_) {
      throw const NotificationServiceException('알림을 읽음 처리하지 못했습니다.');
    }
  }

  String _messageFromDioException(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => '서버 응답 시간이 초과되었습니다.',
      DioExceptionType.connectionError => '서버에 연결할 수 없습니다.',
      DioExceptionType.cancel => '알림 요청이 취소되었습니다.',
      _ => fallback,
    };
  }
}

final class NotificationServiceException implements Exception {
  const NotificationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
