import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'view/calendar_view.dart';
import 'view_model/calendar_view_model.dart';

final List<RouteBase> calendarRoutes = [
  GoRoute(
    path: '/calendar',
    name: 'calendar',
    builder: (context, state) {
      return ChangeNotifierProvider(
        create: (_){
          return CalendarViewModel();
        },
        child: const CalendarView(),
      );
    },
  ),
];