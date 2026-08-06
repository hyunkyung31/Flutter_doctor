import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../model/appointment.dart';
import '../view_model/appointment_view_model.dart';

enum _AppointmentFilter { all, requested, confirmed, cancelled, completed }

enum _DateScope { today, all }

final class AppointmentListView extends StatefulWidget {
  const AppointmentListView({super.key});

  @override
  State<AppointmentListView> createState() => _AppointmentListViewState();
}

final class _AppointmentListViewState extends State<AppointmentListView> {
  _AppointmentFilter _selectedFilter = _AppointmentFilter.all;
  _DateScope _selectedScope = _DateScope.today;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AppointmentViewModel>().loadAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AppointmentViewModel>();
    final appointments = _filteredAppointments(viewModel.appointments);

    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 환자'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildBody(context, viewModel, appointments),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppointmentViewModel viewModel,
    List<Appointment> appointments,
  ) {
    if (viewModel.isLoading && viewModel.appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && viewModel.appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 12),
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => viewModel.loadAppointments(),
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final source = _scopedAppointments(viewModel.appointments);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_DateScope>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _DateScope.today,
                  label: Text('오늘 ${_countForScope(viewModel, _DateScope.today)}'),
                ),
                ButtonSegment(
                  value: _DateScope.all,
                  label: Text('전체 ${viewModel.appointments.length}'),
                ),
              ],
              selected: {_selectedScope},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedScope = selection.first;
                  _selectedFilter = _AppointmentFilter.all;
                });
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _AppointmentFilter.values.map((filter) {
                final selected = _selectedFilter == filter;
                final count = source.where((item) {
                  return _matchesFilter(item, filter);
                }).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: selected,
                    label: Text('${_filterLabel(filter)} $count'),
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => viewModel.refreshAppointments(),
            child: appointments.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 100),
                      Icon(Icons.event_busy_outlined, size: 72),
                      SizedBox(height: 16),
                      Text(
                        '표시할 예약이 없습니다.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: appointments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];

                      return _AppointmentCard(
                        appointment: appointment,
                        isUpdating: viewModel.isUpdating,
                        onOpenPatient: () {
                          context.push(
                            '/patient/detail/${appointment.patientId}',
                          );
                        },
                        onConfirm: appointment.isRequested
                            ? () => _updateStatus(
                                  context,
                                  appointmentId: appointment.id,
                                  status: 'confirmed',
                                  successMessage: '예약을 확정했습니다.',
                                )
                            : null,
                        onCancel: appointment.isActive
                            ? () => _updateStatus(
                                  context,
                                  appointmentId: appointment.id,
                                  status: 'cancelled',
                                  successMessage: '예약을 취소했습니다.',
                                )
                            : null,
                        onComplete: appointment.isConfirmed
                            ? () => _updateStatus(
                                  context,
                                  appointmentId: appointment.id,
                                  status: 'completed',
                                  successMessage: '예약을 완료 처리했습니다.',
                                )
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context, {
    required int appointmentId,
    required String status,
    required String successMessage,
  }) async {
    final viewModel = context.read<AppointmentViewModel>();
    final updated = await viewModel.updateStatus(
      appointmentId: appointmentId,
      status: status,
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated == null
              ? (viewModel.errorMessage ?? '예약 상태를 변경하지 못했습니다.')
              : successMessage,
        ),
      ),
    );
  }

  List<Appointment> _scopedAppointments(List<Appointment> appointments) {
    if (_selectedScope == _DateScope.all) {
      return appointments;
    }

    final today = DateUtils.dateOnly(DateTime.now());

    return appointments.where((appointment) {
      return DateUtils.dateOnly(appointment.scheduledAt) == today;
    }).toList();
  }

  List<Appointment> _filteredAppointments(List<Appointment> appointments) {
    return _scopedAppointments(appointments).where((appointment) {
      return _matchesFilter(appointment, _selectedFilter);
    }).toList();
  }

  int _countForScope(AppointmentViewModel viewModel, _DateScope scope) {
    if (scope == _DateScope.all) {
      return viewModel.appointments.length;
    }

    final today = DateUtils.dateOnly(DateTime.now());

    return viewModel.appointments.where((appointment) {
      return DateUtils.dateOnly(appointment.scheduledAt) == today;
    }).length;
  }

  bool _matchesFilter(Appointment appointment, _AppointmentFilter filter) {
    return switch (filter) {
      _AppointmentFilter.all => true,
      _AppointmentFilter.requested => appointment.isRequested,
      _AppointmentFilter.confirmed => appointment.isConfirmed,
      _AppointmentFilter.cancelled => appointment.isCancelled,
      _AppointmentFilter.completed => appointment.isCompleted,
    };
  }

  String _filterLabel(_AppointmentFilter filter) {
    return switch (filter) {
      _AppointmentFilter.all => '전체',
      _AppointmentFilter.requested => '신청',
      _AppointmentFilter.confirmed => '확정',
      _AppointmentFilter.cancelled => '취소',
      _AppointmentFilter.completed => '완료',
    };
  }
}

final class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.isUpdating,
    required this.onOpenPatient,
    this.onConfirm,
    this.onCancel,
    this.onComplete,
  });

  final Appointment appointment;
  final bool isUpdating;
  final VoidCallback onOpenPatient;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateText = DateFormat('yyyy.MM.dd (E) HH:mm', 'ko_KR').format(
      appointment.scheduledAt.toLocal(),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenPatient,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appointment.patientName.isEmpty
                          ? '환자 ${appointment.patientId}'
                          : appointment.patientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusBadge(status: appointment.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '환자 ID ${appointment.patientId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.primary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dateText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (appointment.department.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '진료과 ${appointment.department}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (appointment.memo.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  appointment.memo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
              if (onConfirm != null ||
                  onCancel != null ||
                  onComplete != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onConfirm != null)
                      FilledButton(
                        onPressed: isUpdating ? null : onConfirm,
                        child: const Text('확정'),
                      ),
                    if (onComplete != null)
                      FilledButton.tonal(
                        onPressed: isUpdating ? null : onComplete,
                        child: const Text('완료'),
                      ),
                    if (onCancel != null)
                      OutlinedButton(
                        onPressed: isUpdating ? null : onCancel,
                        child: const Text('취소'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final label = switch (normalized) {
      'requested' => '신청',
      'confirmed' => '확정',
      'cancelled' => '취소',
      'completed' => '완료',
      _ => status.trim().isEmpty ? '미정' : status.trim(),
    };

    final color = switch (normalized) {
      'requested' => AppColors.secondary,
      'confirmed' => AppColors.primary,
      'cancelled' => Colors.grey,
      'completed' => const Color(0xFF059669),
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
