import 'package:flutter/foundation.dart';

import '../model/app_notification.dart';
import '../repository/notification_repository.dart';

final class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel({required this._notificationRepository});

  final NotificationRepository _notificationRepository;

  List<AppNotification> _notifications = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  int _unreadCount = 0;
  NotificationCategory _selectedCategory = NotificationCategory.all;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;
  NotificationCategory get selectedCategory => _selectedCategory;

  List<AppNotification> get visibleNotifications {
    if (_selectedCategory == NotificationCategory.all) {
      return List.unmodifiable(_notifications);
    }

    return List.unmodifiable(
      _notifications.where(
        (notification) => notification.category == _selectedCategory,
      ),
    );
  }

  bool get hasUnknownCategory => _notifications.any(
    (notification) => notification.category == NotificationCategory.other,
  );

  int unreadCountFor(NotificationCategory category) {
    if (category == NotificationCategory.all) {
      return _unreadCount;
    }

    return _notifications
        .where(
          (notification) =>
              !notification.isRead && notification.category == category,
        )
        .length;
  }

  int totalCountFor(NotificationCategory category) {
    if (category == NotificationCategory.all) {
      return _notifications.length;
    }

    return _notifications
        .where((notification) => notification.category == category)
        .length;
  }

  void selectCategory(NotificationCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadNotifications({bool force = false}) async {
    if (_isLoading || (!force && _hasLoaded)) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _notificationRepository.fetchNotifications();
      _notifications = response.results;
      _unreadCount = response.unreadCount;
      _hasLoaded = true;
    } on NotificationRepositoryException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '알림 목록을 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadNotifications(force: true);

  Future<bool> markAsRead(AppNotification notification) async {
    if (notification.isRead) return true;

    final index = _notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    if (index < 0) return false;

    _errorMessage = null;
    try {
      final updated = await _notificationRepository.markAsRead(notification.id);
      _notifications[index] =
          updated ??
          notification.copyWith(isRead: true, readAt: DateTime.now().toUtc());

      if (_unreadCount > 0) {
        _unreadCount -= 1;
      }

      notifyListeners();
      return true;
    } on NotificationRepositoryException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = '알림을 읽음 처리하지 못했습니다.';
      notifyListeners();
      return false;
    }
  }
}
