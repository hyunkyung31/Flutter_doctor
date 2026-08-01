import 'package:go_router/go_router.dart';

import 'view/home_view.dart';

final List<RouteBase> homeRoutes = [
  GoRoute(
    path: '/home',
    name: 'home',
    builder: (context, state) {
      return const HomeView();
    },
  ),
];