import 'package:flutter/material.dart';

import '../model/app_notification.dart';
import '../view_model/notification_view_model.dart';

final class NotificationFilterChips extends StatelessWidget {
  const NotificationFilterChips({super.key, required this.viewModel});

  final NotificationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final categories = <NotificationCategory>[
      NotificationCategory.all,
      NotificationCategory.consultation,
      NotificationCategory.chat,
      NotificationCategory.appointment,
      if (viewModel.hasUnknownCategory) NotificationCategory.other,
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final unreadCount = viewModel.unreadCountFor(category);
          final isSelected = viewModel.selectedCategory == category;

          return ChoiceChip(
            selected: isSelected,
            onSelected: (_) => viewModel.selectCategory(category),
            avatar: Icon(_iconFor(category), size: 18),
            label: Text(
              unreadCount > 0
                  ? '${category.label} $unreadCount'
                  : category.label,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

IconData _iconFor(NotificationCategory category) => switch (category) {
  NotificationCategory.all => Icons.notifications_outlined,
  NotificationCategory.consultation => Icons.groups_outlined,
  NotificationCategory.chat => Icons.chat_bubble_outline,
  NotificationCategory.appointment => Icons.calendar_month_outlined,
  NotificationCategory.other => Icons.more_horiz,
};
