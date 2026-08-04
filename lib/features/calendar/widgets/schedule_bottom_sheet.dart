import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'schedule_tile.dart';

final class ScheduleItem {
  const ScheduleItem({
    required this.date,
    required this.time,
    required this.title,
    this.description,
  });

  final DateTime date;
  final String time;
  final String title;
  final String? description;
}

final class ScheduleBottomSheet extends StatelessWidget {
  const ScheduleBottomSheet({
    super.key,
    required this.selectedDate,
    required this.schedules,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime selectedDate;
  final List<ScheduleItem> schedules;
  final ValueChanged<ScheduleItem> onEdit;
  final ValueChanged<ScheduleItem> onDelete;

  String _getWeekday(DateTime date) {
    const weekdays = [
      '월요일',
      '화요일',
      '수요일',
      '목요일',
      '금요일',
      '토요일',
      '일요일',
    ];

    return weekdays[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 선택 날짜와 달력 사이의 손잡이
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 8,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(
                  alpha: 0.22,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          /// 선택 날짜
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              16,
            ),
            child: Text(
              '${selectedDate.year}년 '
              '${selectedDate.month}월 '
              '${selectedDate.day}일 '
              '${_getWeekday(selectedDate)}',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Divider(
            height: 1,
            color: theme.dividerColor,
          ),

          /// 일정 목록
          Expanded(
            child: schedules.isEmpty
                ? _EmptySchedule(
                    colorScheme: colorScheme,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      100,
                    ),
                    itemCount: schedules.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(
                        height: 12,
                      );
                    },
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];

                      return ScheduleTile(
                        schedule: schedule,
                        onEdit: () {
                          onEdit(schedule);
                        },
                        onDelete: () {
                          onDelete(schedule);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

final class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({
    required this.colorScheme,
  });

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        100,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 20),

          Padding(
            padding: const EdgeInsets.only(
              top: 18,
            ),
            child: Text(
              '일정이 없습니다.',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}