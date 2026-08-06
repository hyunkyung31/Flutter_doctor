import 'app_notification.dart';

final class NotificationListResponse {
  const NotificationListResponse({
    required this.count,
    required this.unreadCount,
    required this.results,
  });

  final int count;
  final int unreadCount;
  final List<AppNotification> results;

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final results = rawResults is List
        ? rawResults
              .whereType<Map>()
              .map(
                (item) =>
                    AppNotification.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : const <AppNotification>[];

    return NotificationListResponse(
      count: _integer(json['count'], fallback: results.length),
      unreadCount: _integer(
        json['unread_count'],
        fallback: results.where((item) => !item.isRead).length,
      ),
      results: results,
    );
  }
}

int _integer(dynamic value, {required int fallback}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
