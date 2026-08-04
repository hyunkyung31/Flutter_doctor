import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

final class PatientStatusSection extends StatelessWidget {
  const PatientStatusSection({
    super.key,
    required this.reservationCount,
    required this.waitingCount,
    required this.onReservationTap,
    required this.onWaitingTap,
  });

  final int reservationCount;
  final int waitingCount;
  final VoidCallback onReservationTap;
  final VoidCallback onWaitingTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘의 환자 현황',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _PatientStatusItem(
                    title: '예약 환자',
                    count: reservationCount,
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.primary,
                    onTap: onReservationTap,
                  ),
                ),
                Container(
                  width: 1,
                  height: 42,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                  color: colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _PatientStatusItem(
                    title: '대기 환자',
                    count: waitingCount,
                    icon: Icons.groups_outlined,
                    color: AppColors.secondary,
                    onTap: onWaitingTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _PatientStatusItem extends StatelessWidget {
  const _PatientStatusItem({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode =
        theme.brightness == Brightness.dark;

    final effectiveColor = isDarkMode
        ? Color.lerp(
            color,
            Colors.white,
            0.22,
          )!
        : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 4,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: effectiveColor.withValues(
                  alpha: isDarkMode ? 0.22 : 0.12,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: effectiveColor,
                size: 17,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface
                          .withValues(
                        alpha:
                            isDarkMode ? 0.88 : 0.72,
                      ),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$count명',
                    style: TextStyle(
                      color: effectiveColor,
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 17,
              color: colorScheme.onSurface.withValues(
                alpha: isDarkMode ? 0.70 : 0.38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}