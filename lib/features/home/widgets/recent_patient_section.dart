import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

final class RecentPatientItem {
  const RecentPatientItem({
    required this.patientId,
    required this.patientName,
    required this.description,
  });

  final String patientId;
  final String patientName;
  final String description;
}

final class RecentPatientSection extends StatelessWidget {
  const RecentPatientSection({
    super.key,
    required this.patients,
    required this.onPatientTap,
    required this.onViewAll,
  });

  final List<RecentPatientItem> patients;
  final ValueChanged<RecentPatientItem> onPatientTap;
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
                '최근 본 환자',
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
          child: patients.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_search_outlined,
                        size: 34,
                        color: colorScheme.onSurface.withOpacity(0.35),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '최근 확인한 환자가 없습니다.',
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
                  itemCount: patients.length,
                  separatorBuilder: (context, index) {
                    return Divider(
                      height: 1,
                      indent: 72,
                      color: colorScheme.onSurface.withOpacity(0.08),
                    );
                  },
                  itemBuilder: (context, index) {
                    final patient = patients[index];

                    return ListTile(
                      onTap: () {
                        onPatientTap(patient);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withOpacity(0.12),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        patient.patientName,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${patient.patientId} · ${patient.description}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurface.withOpacity(0.45),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}