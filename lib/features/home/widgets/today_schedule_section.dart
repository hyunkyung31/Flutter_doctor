import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

final class TodayScheduleItem {
  const TodayScheduleItem({
    required this.time,
    required this.title,
    this.description,
  });

  final String time;
  final String title;
  final String? description;
}

final class TodayScheduleSection extends StatelessWidget {
  const TodayScheduleSection({
    super.key,
    required this.schedules,
    required this.onViewAll,
  });

  final List<TodayScheduleItem> schedules;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '오늘 일정',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('전체보기'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.dividerColor,
            ),
          ),
          child: schedules.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 34,
                        color: colorScheme.onSurface.withOpacity(0.35),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '오늘 등록된 일정이 없습니다.',
                        style: textTheme.bodyMedium?.copyWith(
                          color:
                              colorScheme.onSurface.withOpacity(0.55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: schedules.length,
                  separatorBuilder: (context, index) {
                    return Divider(
                      height: 1,
                      indent: 70,
                      color: colorScheme.onSurface.withOpacity(0.08),
                    );
                  },
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          schedule.time,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        schedule.title,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: schedule.description == null
                          ? null
                          : Text(
                              schedule.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}