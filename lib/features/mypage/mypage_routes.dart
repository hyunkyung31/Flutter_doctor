import 'package:go_router/go_router.dart';

import 'view/mypage_view.dart';

final List<RouteBase> myPageRoutes = [
  GoRoute(
    path: '/mypage',
    name: 'mypage',
    builder: (context, state) {
      return const MyPageView();
    },
  ),
];
