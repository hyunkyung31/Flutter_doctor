import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../features/settings/view_model/settings_view_model.dart';
import '../features/chat/view_model/chat_view_model.dart';

final class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

final class _AppShellState extends State<AppShell> {
  Timer? _chatPollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatViewModel>().loadRooms(force: true);
      _chatPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          context.read<ChatViewModel>().loadRooms(force: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _chatPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = context.watch<ChatViewModel>();
    final totalUnreadCount = chatViewModel.rooms.fold<int>(
      0,
      (total, room) => total + room.unreadCount,
    );
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = path.startsWith('/mypage')
        ? 3
        : path.startsWith('/chat')
            ? 2
            : path.startsWith('/patient')
                ? 1
                : 0;
    final colorScheme = Theme.of(context).colorScheme;
    final hidesTopBar = path.startsWith('/mypage') ||
        path.startsWith('/settings') ||
        path.startsWith('/chat');

    return Scaffold(
      appBar: hidesTopBar ? null : _buildTopBar(context),
      body: widget.child,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primary,
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withValues(alpha: 0.9),
              size: selected ? 25 : 23,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? colorScheme.primary : colorScheme.onSurface,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/home');
                return;
              case 1:
                context.go('/patient');
                return;
              case 2:
                context.go('/chat');
                return;
              case 3:
                context.go('/mypage');
                return;
            }
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: '환자',
            ),
            NavigationDestination(
              icon: _ChatTabIcon(
                selected: false,
                unreadCount: totalUnreadCount,
              ),
              selectedIcon: _ChatTabIcon(
                selected: true,
                unreadCount: totalUnreadCount,
              ),
              label: '채팅',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '마이페이지',
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsViewModel>();
    return AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface,
      foregroundColor: colorScheme.primary,
      title: Text(
        'VENA',
        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: '알림',
              onPressed: () => _showPreparingMessage(context, '알림'),
              icon: const Icon(Icons.notifications_none),
            ),
            const Positioned(
              right: 10,
              top: 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 8, height: 8),
              ),
            ),
          ],
        ),
        IconButton(
          tooltip: settings.isDarkMode ? '라이트 모드로 변경' : '다크 모드로 변경',
          onPressed: settings.toggleTheme,
          icon: Icon(
            settings.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
        ),
      ],
    );
  }

  void _showPreparingMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature 기능은 현재 준비 중입니다.')));
  }
}

final class _ChatTabIcon extends StatelessWidget {
  const _ChatTabIcon({
    required this.selected,
    required this.unreadCount,
  });

  final bool selected;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          selected ? Icons.chat_bubble : Icons.chat_bubble_outline,
        ),
        if (unreadCount > 0)
          Positioned(
            right: -11,
            top: -9,
            child: Container(
              constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
