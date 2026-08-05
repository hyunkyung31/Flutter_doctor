import 'package:go_router/go_router.dart';

import '../memo/view/recent_voice_memos_view.dart';
import 'view/mypage_view.dart';

final List<RouteBase> myPageRoutes = [
  GoRoute(
    path: '/mypage',
    name: 'mypage',
    builder: (context, state) {
      return const MyPageView();
    },
  ),
  GoRoute(
    path: '/mypage/recent-recordings',
    name: 'recentVoiceMemos',
    builder: (context, state) => const RecentVoiceMemosView(),
  ),
];
