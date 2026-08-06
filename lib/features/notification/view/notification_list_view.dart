import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../consultation/view_model/consultation_view_model.dart';
import '../model/app_notification.dart';
import '../view_model/notification_view_model.dart';
import '../widgets/notification_filter_chips.dart';
import '../widgets/notification_tile.dart';

final class NotificationListView extends StatefulWidget {
  const NotificationListView({super.key});

  @override
  State<NotificationListView> createState() => _NotificationListViewState();
}

final class _NotificationListViewState extends State<NotificationListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationViewModel>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: viewModel.isLoading ? null : viewModel.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, NotificationViewModel viewModel) {
    if (viewModel.isLoading && !viewModel.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!viewModel.hasLoaded && viewModel.errorMessage != null) {
      return _ErrorState(
        message: viewModel.errorMessage!,
        onRetry: viewModel.refresh,
      );
    }

    if (viewModel.notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [SizedBox(height: 150), _EmptyState()],
        ),
      );
    }

    final visibleNotifications = viewModel.visibleNotifications;

    return Column(
      children: [
        NotificationFilterChips(viewModel: viewModel),
        if (viewModel.errorMessage != null)
          MaterialBanner(
            content: Text(viewModel.errorMessage!),
            actions: [
              TextButton(
                onPressed: viewModel.refresh,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: visibleNotifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      _FilteredEmptyState(category: viewModel.selectedCategory),
                    ],
                  )
                : _NotificationGroupedList(
                    notifications: visibleNotifications,
                    onTap: _openNotification,
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _openNotification(AppNotification notification) async {
    final notificationViewModel = context.read<NotificationViewModel>();
    final readSucceeded = await notificationViewModel.markAsRead(notification);

    if (!mounted) return;
    if (!readSucceeded) {
      _showMessage(notificationViewModel.errorMessage ?? '알림을 읽음 처리하지 못했습니다.');
      return;
    }

    if (notification.type.isChat) {
      final roomId = notification.chatRoomId;
      if (roomId == null) {
        _showMessage('연결된 채팅방 정보가 없습니다.');
        return;
      }
      context.push('/chat/$roomId');
      return;
    }

    if (notification.type.isConsultation) {
      await _openConsultation(notification);
      return;
    }

    if (notification.type == AppNotificationType.appointmentRequested) {
      context.go('/calendar');
      return;
    }

    if (notification.type == AppNotificationType.clinicalReportReady) {
      context.push('/clinical-report/sign-offs');
      return;
    }

    _showMessage('이 알림은 연결된 화면 정보가 없습니다.');
  }

  Future<void> _openConsultation(AppNotification notification) async {
    final consultationId = notification.consultationId;
    if (consultationId == null) {
      _showMessage('연결된 협진 정보가 없습니다.');
      return;
    }

    final consultationViewModel = context.read<ConsultationViewModel>();
    var request = consultationViewModel.requestById(consultationId);

    if (request == null) {
      await consultationViewModel.loadAllRequests();
      request = consultationViewModel.requestById(consultationId);
    }

    if (!mounted) return;

    if (request != null) {
      context.pushNamed('consultationDetail', extra: request);
      return;
    }

    _showMessage(consultationViewModel.errorMessage ?? '협진 요청을 찾을 수 없습니다.');
    context.pushNamed('consultationInbox');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _NotificationGroupedList extends StatelessWidget {
  const _NotificationGroupedList({
    required this.notifications,
    required this.onTap,
  });

  final List<AppNotification> notifications;
  final ValueChanged<AppNotification> onTap;

  @override
  Widget build(BuildContext context) {
    final groups = _groupNotificationsByDate(notifications);
    final children = <Widget>[];

    for (final entry in groups.entries) {
      children.add(_DateSectionHeader(label: entry.key));

      for (var index = 0; index < entry.value.length; index++) {
        final notification = entry.value[index];
        children.add(
          NotificationTile(
            notification: notification,
            onTap: () => onTap(notification),
          ),
        );

        if (index < entry.value.length - 1) {
          children.add(const Divider(height: 1));
        }
      }
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
    );
  }
}

LinkedHashMap<String, List<AppNotification>> _groupNotificationsByDate(
  List<AppNotification> notifications,
) {
  final groups = LinkedHashMap<String, List<AppNotification>>();

  for (final notification in notifications) {
    final label = _dateSectionLabel(notification.createdAt);
    groups.putIfAbsent(label, () => <AppNotification>[]).add(notification);
  }

  return groups;
}

String _dateSectionLabel(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();

  final date = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (date == today) return '오늘';
  if (date == yesterday) return '어제';

  if (date.year == today.year) {
    return '${date.month}월 ${date.day}일';
  }

  return '${date.year}년 ${date.month}월 ${date.day}일';
}

final class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      color: colorScheme.surfaceContainerLowest,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

final class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.category});

  final NotificationCategory category;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            size: 44,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            '${category.label} 알림이 없습니다',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            '다른 카테고리를 선택하거나 아래로 당겨 새로고침해 주세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 34,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '새로운 알림이 없습니다',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            '협진, 채팅, 예약 관련 알림이 도착하면 이곳에서 확인할 수 있습니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

final class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
