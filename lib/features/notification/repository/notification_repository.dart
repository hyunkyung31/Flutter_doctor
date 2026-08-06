import '../../../core/storage/secure_storage.dart';
import '../model/app_notification.dart';
import '../model/notification_list_response.dart';
import '../service/notification_service.dart';

final class NotificationRepository {
  const NotificationRepository({
    required NotificationService notificationService,
    required SecureStorage secureStorage,
  }) : _notificationService = notificationService,
       _secureStorage = secureStorage;

  final NotificationService _notificationService;
  final SecureStorage _secureStorage;

  Future<NotificationListResponse> fetchNotifications({
    bool unreadOnly = false,
  }) {
    return _call(
      (token) => _notificationService.fetchNotifications(
        token,
        unreadOnly: unreadOnly,
      ),
    );
  }

  Future<AppNotification?> markAsRead(int notificationId) {
    return _call(
      (token) => _notificationService.markAsRead(token, notificationId),
    );
  }

  Future<T> _call<T>(Future<T> Function(String token) action) async {
    final token = await _secureStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const NotificationRepositoryException('로그인 정보가 없습니다. 다시 로그인해 주세요.');
    }

    try {
      return await action(token);
    } on NotificationServiceException catch (error) {
      throw NotificationRepositoryException(error.message);
    }
  }
}

final class NotificationRepositoryException implements Exception {
  const NotificationRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
