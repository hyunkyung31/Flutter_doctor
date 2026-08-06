import 'package:go_router/go_router.dart';

import 'view/notification_list_view.dart';

final List<RouteBase> notificationRoutes = [
  GoRoute(
    path: '/notifications',
    name: 'notifications',
    builder: (context, state) => const NotificationListView(),
  ),
];
