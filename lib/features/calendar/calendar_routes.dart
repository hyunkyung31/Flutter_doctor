import 'package:go_router/go_router.dart';

import 'view/calendar_view.dart';

final List<RouteBase> calendarRoutes = [
  GoRoute(
    path: '/calendar',
    name: 'calendar',
    builder: (context, state) {
      return const CalendarView();
    },
  ),
];