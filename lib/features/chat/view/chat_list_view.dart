import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_model/chat_view_model.dart';
import '../../../core/widgets/profile/doctor_profile_avatar.dart';

final class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

final class _ChatListViewState extends State<ChatListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatViewModel>().loadRooms(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();
    final rooms = viewModel.rooms;
    final totalUnreadCount = rooms.fold<int>(
      0,
      (total, room) => total + room.unreadCount,
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('채팅'),
            if (totalUnreadCount > 0) ...[
              const SizedBox(width: 8),
              Badge(
                label: Text(
                  totalUnreadCount > 99 ? '99+' : '$totalUnreadCount',
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: '새 채팅',
            onPressed: () => context.push('/chat/new'),
            icon: const Icon(Icons.edit_square),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              hintText: '의사 이름 또는 진료과 검색',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onTap: () => context.push('/chat/new'),
            ),
          ),
          Expanded(
            child: viewModel.isRoomsLoading && rooms.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : viewModel.errorMessage != null && rooms.isEmpty
                ? Center(
                    child: FilledButton(
                      onPressed: () => viewModel.loadRooms(force: true),
                      child: const Text('채팅 목록 다시 불러오기'),
                    ),
                  )
                : rooms.isEmpty
                ? const Center(child: Text('진행 중인 채팅이 없습니다.'))
                : RefreshIndicator(
                    onRefresh: () => viewModel.loadRooms(force: true),
                    child: ListView.separated(
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        final last = room.messages.lastOrNull;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: const DoctorProfileAvatar(radius: 22),
                          title: Text(
                            room.doctor.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${room.doctor.department} · ${room.doctor.hospital}\n${last?.content ?? '새 채팅을 시작해 보세요.'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: room.unreadCount > 0
                              ? Badge(
                                  label: Text(
                                    room.unreadCount > 9
                                        ? '9+'
                                        : '${room.unreadCount}',
                                  ),
                                )
                              : null,
                          onTap: () => context.push('/chat/${room.id}'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
