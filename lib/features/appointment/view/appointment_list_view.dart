import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../model/appointment.dart';
import '../view_model/appointment_view_model.dart';

final class AppointmentListView extends StatefulWidget {
  const AppointmentListView({super.key});

  @override
  State<AppointmentListView> createState() => _AppointmentListViewState();
}

final class _AppointmentListViewState extends State<AppointmentListView> {
  _AppointmentFilter _filter = _AppointmentFilter.active;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppointmentViewModel>().loadAppointments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AppointmentViewModel>();
    final items = _filtered(viewModel.appointments);

    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 환자'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<_AppointmentFilter>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _AppointmentFilter.active,
                      label: Text('진행중'),
                    ),
                    ButtonSegment(
                      value: _AppointmentFilter.requested,
                      label: Text('신청'),
                    ),
                    ButtonSegment(
                      value: _AppointmentFilter.confirmed,
                      label: Text('확정'),
                    ),
                    ButtonSegment(
                      value: _AppointmentFilter.all,
                      label: Text('전체'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (value) {
                    setState(() => _filter = value.first);
                  },
                ),
              ),
            ),
            Expanded(child: _buildBody(context, viewModel, items)),
          ],
        ),
      ),
    );
  }

  List<Appointment> _filtered(List<Appointment> source) {
    switch (_filter) {
      case _AppointmentFilter.active:
        return source.where((e) => e.isActive).toList(growable: false);
      case _AppointmentFilter.requested:
        return source
            .where((e) => e.status == AppointmentStatus.requested)
            .toList(growable: false);
      case _AppointmentFilter.confirmed:
        return source
            .where((e) => e.status == AppointmentStatus.confirmed)
            .toList(growable: false);
      case _AppointmentFilter.all:
        return source;
    }
  }

  Widget _buildBody(
    BuildContext context,
    AppointmentViewModel viewModel,
    List<Appointment> items,
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
                onPressed: viewModel.loadAppointments,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.loadAppointments,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                '표시할 예약이 없습니다.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadAppointments,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return _AppointmentCard(
            item: item,
            busy: viewModel.isUpdating,
            onConfirm: () => _runAction(
              context,
              successMessage: '예약을 확정했습니다.',
              action: () => viewModel.confirm(item.id),
            ),
            onComplete: () => _runAction(
              context,
              successMessage: '진료를 완료 처리했습니다.',
              action: () => viewModel.complete(item.id),
            ),
            onCancel: () => _confirmCancel(context, viewModel, item),
          );
        },
      ),
    );
  }

  Future<void> _runAction(
    BuildContext context, {
    required String successMessage,
    required Future<bool> Function() action,
  }) async {
    final ok = await action();
    if (!context.mounted) return;
    final viewModel = context.read<AppointmentViewModel>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? successMessage
              : (viewModel.errorMessage ?? '처리에 실패했습니다.'),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    AppointmentViewModel viewModel,
    Appointment item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('예약 취소'),
        content: Text(
          '${item.patientName.isEmpty ? item.patientId : item.patientName} 환자의\n'
          '${DateFormat('yyyy.MM.dd HH:mm').format(item.scheduledAt)} 예약을 취소할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _runAction(
      context,
      successMessage: '예약을 취소했습니다.',
      action: () => viewModel.cancel(item.id),
    );
  }
}

enum _AppointmentFilter { active, requested, confirmed, all }

final class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.item,
    required this.busy,
    required this.onConfirm,
    required this.onComplete,
    required this.onCancel,
  });

  final Appointment item;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  Color get _badgeColor {
    switch (item.status) {
      case AppointmentStatus.requested:
        return AppColors.secondary;
      case AppointmentStatus.confirmed:
        return const Color(0xFF059669);
      case AppointmentStatus.cancelled:
        return const Color(0xFF9CA3AF);
      case AppointmentStatus.completed:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patientLabel =
        item.patientName.isEmpty ? item.patientId : item.patientName;
    final timeText =
        DateFormat('yyyy.MM.dd HH:mm').format(item.scheduledAt);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    patientLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${item.department} · ${item.patientId}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            if (item.memo.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.memo,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (item.canConfirm || item.canComplete || item.canCancel) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (item.canConfirm)
                    FilledButton(
                      onPressed: busy ? null : onConfirm,
                      child: const Text('확정'),
                    ),
                  if (item.canComplete)
                    FilledButton(
                      onPressed: busy ? null : onComplete,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                      ),
                      child: const Text('완료'),
                    ),
                  if (item.canCancel)
                    OutlinedButton(
                      onPressed: busy ? null : onCancel,
                      child: const Text(
                        '취소',
                        style: TextStyle(color: Color(0xFFB91C1C)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
