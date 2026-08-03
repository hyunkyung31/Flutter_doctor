import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../calendar/widgets/schedule_bottom_sheet.dart';

final class DoctorBriefingCard extends StatelessWidget {
  const DoctorBriefingCard({
    super.key,
    required this.doctorName,
    required this.schedules,
    required this.todoItems,
  });

  final String doctorName;
  final List<ScheduleItem> schedules;
  final List<Map<String, dynamic>> todoItems;

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isDarkMode =
    theme.brightness == Brightness.dark;

    final primaryColor = isDarkMode
        ? const Color(0xFF8EC5FF)
        : AppColors.primary;

    final secondaryTextColor = isDarkMode
        ? colorScheme.onSurface.withValues(
            alpha: 0.88,
          )
    : colorScheme.onSurfaceVariant;

    final now = DateTime.now();

    final todaySchedules = schedules.where((schedule) {
      return _isSameDate(
        schedule.date,
        now,
      );
    }).toList();

    final pendingTodos = todoItems.where((item) {
      return item['isCompleted'] == false;
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(
            alpha: 0.14,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(
                    alpha: isDarkMode ? 0.22 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  color: primaryColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$doctorName 의료진님',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${now.year}년 ${now.month}월 ${now.day}일',
                      style: textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(
                    alpha: isDarkMode ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '업무 브리핑',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _BriefingCountItem(
                  icon: Icons.calendar_today_outlined,
                  label: '오늘 일정',
                  value: '${todaySchedules.length}건',
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: theme.dividerColor,
              ),
              Expanded(
                child: _BriefingCountItem(
                  icon: Icons.task_alt_outlined,
                  label: '미완료 업무',
                  value: '${pendingTodos.length}건',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _BriefingListSection(
            icon: Icons.calendar_month_outlined,
            title: '오늘 일정',
            totalCount: todaySchedules.length,
            emptyText: '오늘 등록된 일정이 없습니다.',
            children: todaySchedules.take(2).map((schedule) {
              return _BriefingListItem(
                leadingText: schedule.time,
                title: schedule.title,
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          _BriefingListSection(
            icon: Icons.assignment_outlined,
            title: '미완료 업무',
            totalCount: pendingTodos.length,
            emptyText: '미완료 업무가 없습니다.',
            warning: pendingTodos.isNotEmpty,
            children: pendingTodos.take(2).map((todo) {
              return _BriefingListItem(
                leadingIcon: Icons.circle,
                title: todo['title']?.toString() ?? '',
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

final class _BriefingCountItem extends StatelessWidget {
  const _BriefingCountItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode =
        theme.brightness == Brightness.dark;

    final primaryColor = isDarkMode
        ? const Color(0xFF8EC5FF)
        : colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primaryColor.withValues(
              alpha: isDarkMode ? 0.20 : 0.09,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 17,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(
                  alpha: isDarkMode ? 0.90 : 0.72,
                ),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _BriefingListSection extends StatelessWidget {
  const _BriefingListSection({
    required this.icon,
    required this.title,
    required this.totalCount,
    required this.emptyText,
    required this.children,
    this.warning = false,
  });

  final IconData icon;
  final String title;
  final int totalCount;
  final String emptyText;
  final List<Widget> children;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode =
        theme.brightness == Brightness.dark;

    final accentColor = warning
        ? const Color(0xFFF0B52D)
        : colorScheme.primary;

    final titleColor = warning
        ? isDarkMode
            ? const Color(0xFFFFD76A)
            : const Color(0xFF7A5600)
        : colorScheme.onSurface;

    final backgroundColor = warning
        ? isDarkMode
            ? const Color(0xFF2A2518)
            : const Color(0xFFFFFAEC)
        : colorScheme.surface;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(9),
                  bottomLeft: Radius.circular(9),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(
                              alpha: 0.11,
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            icon,
                            size: 15,
                            color: warning
                                ? isDarkMode
                                    ? const Color(0xFFFFD76A)
                                    : const Color(0xFF9A6B00)
                                : isDarkMode
                                    ? const Color(0xFF8EC5FF)
                                    : colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(
                              alpha: 0.11,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$totalCount건',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    if (children.isEmpty)
                      Text(
                        emptyText,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(
                            alpha: isDarkMode ? 0.88 : 0.72,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _BriefingListItem extends StatelessWidget {
  const _BriefingListItem({
    required this.title,
    this.leadingText,
    this.leadingIcon,
  });

  final String title;
  final String? leadingText;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode =
        theme.brightness == Brightness.dark;

    final primaryColor = isDarkMode
        ? const Color(0xFF8EC5FF)
        : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 4,
      ),
      child: Row(
        children: [
          if (leadingText != null) ...[
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(
                vertical: 2,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primaryColor.withValues(
                  alpha: isDarkMode ? 0.20 : 0.10,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                leadingText!,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (leadingIcon != null) ...[
            Icon(
              leadingIcon!,
              size: 6,
              color: const Color(0xFFF0B52D),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}