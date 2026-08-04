import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'view/chat_doctor_select_view.dart';
import 'view/chat_list_view.dart';
import 'view/chat_room_view.dart';

final List<RouteBase> chatRoutes = [
  GoRoute(
    path: '/chat',
    name: 'chat',
    builder: (context, state) => const ChatListView(),
    routes: [
      GoRoute(
        path: 'new',
        name: 'chat-new',
        builder: (context, state) => const ChatDoctorSelectView(),
      ),
      GoRoute(
        path: ':roomId',
        name: 'chat-room',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'];
          if (roomId == null) {
            return const Scaffold(body: Center(child: Text('채팅방을 찾을 수 없습니다.')));
          }
          return ChatRoomView(roomId: roomId);
        },
      ),
    ],
  ),
];
