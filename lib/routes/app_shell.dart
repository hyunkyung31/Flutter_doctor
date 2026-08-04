import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../features/settings/view_model/settings_view_model.dart';

final class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
      body: child,
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: '환자',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: '채팅',
            ),
            NavigationDestination(
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
              tooltip: '채팅',
              onPressed: () => context.go('/chat'),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
            Positioned(
              right: 6,
              top: 5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
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
