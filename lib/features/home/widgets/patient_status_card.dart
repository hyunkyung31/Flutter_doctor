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
    return Row(
      children: [
        Expanded(
          child: PatientStatusCard(
            title: '오늘 예약 환자',
            count: reservationCount,
            icon: Icons.calendar_month_outlined,
            color: AppColors.primary,
            onTap: onReservationTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PatientStatusCard(
            title: '현재 대기 환자',
            count: waitingCount,
            icon: Icons.groups_outlined,
            color: AppColors.secondary,
            onTap: onWaitingTap,
          ),
        ),
      ],
    );
  }
}

final class PatientStatusCard extends StatelessWidget {
  const PatientStatusCard({
    super.key,
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
    final textTheme = theme.textTheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.dividerColor,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '명',
                      style: textTheme.bodyMedium?.copyWith(
                        color:
                            colorScheme.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}