import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../consultation/view_model/consultation_view_model.dart';
import '../model/emr_sign_off_workflow_item.dart';
import '../model/emr_sign_off_workflow_status.dart';
import '../view_model/emr_sign_off_view_model.dart';

import '../../patient/view_model/patient_list_view_model.dart';

final class EmrSignOffListView extends StatefulWidget {
  const EmrSignOffListView({super.key});

  @override
  State<EmrSignOffListView> createState() {
    return _EmrSignOffListViewState();
  }
}

final class _EmrSignOffListViewState extends State<EmrSignOffListView> {
  _EmrSignOffListFilter _selectedFilter = _EmrSignOffListFilter.all;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _loadWorkflowItems();
    });
  }

  Future<void> _loadWorkflowItems() async {
    await Future.wait([
      context.read<EmrSignOffViewModel>().loadSignOffs(),
      context.read<ConsultationViewModel>().loadAllRequests(),
      context.read<PatientListViewModel>().loadPatients(),
    ]);
  }

  String _normalizePatientId(String patientId) {
    return patientId.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final signOffViewModel = context.watch<EmrSignOffViewModel>();
    final consultationViewModel = context.watch<ConsultationViewModel>();
    final patientListViewModel = context.watch<PatientListViewModel>();

    final patientNameById = {
      for (final patient in patientListViewModel.patients)
        _normalizePatientId(patient.patientId): patient.patientName.trim(),
    };

    debugPrint('환자 이름 Map: $patientNameById');

    for (final signOff in signOffViewModel.signOffs) {
      final normalizedId = _normalizePatientId(signOff.patientId);

      debugPrint(
        'SIGN OFF patientId=${signOff.patientId}, '
        'normalized=$normalizedId, '
        'matchedName=${patientNameById[normalizedId]}',
      );
    }

    final items = signOffViewModel.signOffs
        .map(
          (signOff) => EmrSignOffWorkflowItem.fromSignOff(
            signOff: signOff,
            sentConsultations: consultationViewModel.sentRequests,
            patientName:
                patientNameById[_normalizePatientId(signOff.patientId)],
          ),
        )
        .toList();

    items.sort((first, second) {
      final firstDate = first.updatedAt;
      final secondDate = second.updatedAt;

      if (firstDate == null && secondDate == null) {
        return 0;
      }

      if (firstDate == null) {
        return 1;
      }

      if (secondDate == null) {
        return -1;
      }

      return secondDate.compareTo(firstDate);
    });

    final filteredItems = items.where(_matchesSelectedFilter).toList();

    final isLoading =
        signOffViewModel.isLoading ||
        consultationViewModel.isRequestsLoading ||
        patientListViewModel.isLoading;

    final errorMessage =
        signOffViewModel.errorMessage ?? consultationViewModel.errorMessage;

    return Scaffold(
      body: SafeArea(
        child: _buildBody(
          items: items,
          filteredItems: filteredItems,
          isLoading: isLoading,
          errorMessage: errorMessage,
        ),
      ),
    );
  }

  Widget _buildBody({
    required List<EmrSignOffWorkflowItem> items,
    required List<EmrSignOffWorkflowItem> filteredItems,
    required bool isLoading,
    required String? errorMessage,
  }) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 12),
              Text(errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadWorkflowItems,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final activeCount = items.where((item) {
      return item.status == EmrSignOffWorkflowStatus.draft ||
          item.status == EmrSignOffWorkflowStatus.consultationPending ||
          item.status == EmrSignOffWorkflowStatus.consultationAnswered;
    }).length;

    final completedCount = items.length - activeCount;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIGN OFF',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '최종 소견 작성 후 SIGN OFF를 완료하면\n'
                      '환자는 환자 앱에서 임상 보고서 PDF를 확인할 수 있습니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: isLoading ? null : _loadWorkflowItems,
                tooltip: '새로고침',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_EmrSignOffListFilter>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment<_EmrSignOffListFilter>(
                  value: _EmrSignOffListFilter.all,
                  label: Text('전체 ${items.length}'),
                ),
                ButtonSegment<_EmrSignOffListFilter>(
                  value: _EmrSignOffListFilter.active,
                  label: Text('진행 중 $activeCount'),
                ),
                ButtonSegment<_EmrSignOffListFilter>(
                  value: _EmrSignOffListFilter.completed,
                  label: Text('완료 $completedCount'),
                ),
              ],
              selected: {_selectedFilter},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedFilter = selection.first;
                });
              },
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadWorkflowItems,
            child: filteredItems.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 100),
                      const Icon(Icons.assignment_turned_in_outlined, size: 72),
                      const SizedBox(height: 16),
                      Text(_emptyMessage(), textAlign: TextAlign.center),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      return _EmrSignOffWorkflowCard(
                        item: filteredItems[index],
                        onTap: () async {
                          await context.pushNamed(
                            'emrSignOffDetail',
                            extra: filteredItems[index],
                          );

                          if (!context.mounted) {
                            return;
                          }

                          await _loadWorkflowItems();
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  bool _matchesSelectedFilter(EmrSignOffWorkflowItem item) {
    final isActive =
        item.status == EmrSignOffWorkflowStatus.draft ||
        item.status == EmrSignOffWorkflowStatus.consultationPending ||
        item.status == EmrSignOffWorkflowStatus.consultationAnswered;

    switch (_selectedFilter) {
      case _EmrSignOffListFilter.all:
        return true;

      case _EmrSignOffListFilter.active:
        return isActive;

      case _EmrSignOffListFilter.completed:
        return !isActive;
    }
  }

  String _emptyMessage() {
    switch (_selectedFilter) {
      case _EmrSignOffListFilter.all:
        return '작성된 SIGN OFF 항목이 없습니다.';

      case _EmrSignOffListFilter.active:
        return '진행 중인 SIGN OFF 항목이 없습니다.';

      case _EmrSignOffListFilter.completed:
        return '완료된 SIGN OFF 항목이 없습니다.';
    }
  }
}

enum _EmrSignOffListFilter { all, active, completed }

final class _EmrSignOffWorkflowCard extends StatelessWidget {
  const _EmrSignOffWorkflowCard({required this.item, required this.onTap});

  final EmrSignOffWorkflowItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.patientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _WorkflowStatusChip(status: item.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.examId == null ? '검사 ID 없음' : '검사 ID: ${item.examId}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                '환자 ID: ${item.patientId}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              if (item.finalResult.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item.finalResult,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (item.hasConsultation) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      item.hasConsultationResponse
                          ? Icons.mark_chat_read_outlined
                          : Icons.forum_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.hasConsultationResponse
                            ? '협진 답변이 도착했습니다.'
                            : '협진 요청이 연결되어 있습니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (item.updatedAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  _dateText(item.updatedAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _dateText(DateTime date) {
    final local = date.toLocal();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${local.year}.'
        '${twoDigits(local.month)}.'
        '${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}';
  }
}

final class _WorkflowStatusChip extends StatelessWidget {
  const _WorkflowStatusChip({required this.status});

  final EmrSignOffWorkflowStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final visual = _statusVisual(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: visual.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: visual.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 15, color: visual.foregroundColor),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: visual.foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _WorkflowStatusVisual _statusVisual(EmrSignOffWorkflowStatus status) {
    switch (status) {
      case EmrSignOffWorkflowStatus.draft:
        return const _WorkflowStatusVisual(
          backgroundColor: Color(0xFFF1F5F9),
          borderColor: Color(0xFFCBD5E1),
          foregroundColor: Color(0xFF1F2937),
          icon: Icons.edit_note_outlined,
        );

      case EmrSignOffWorkflowStatus.consultationPending:
        return const _WorkflowStatusVisual(
          backgroundColor: Color(0xFFE0F2FE),
          borderColor: Color(0xFF7DD3FC),
          foregroundColor: Color(0xFF1F2937),
          icon: Icons.schedule_outlined,
        );

      case EmrSignOffWorkflowStatus.consultationAnswered:
        return const _WorkflowStatusVisual(
          backgroundColor: Color(0xFFF3E8FF),
          borderColor: Color(0xFFD8B4FE),
          foregroundColor: Color(0xFF1F2937),
          icon: Icons.mark_chat_read_outlined,
        );

      case EmrSignOffWorkflowStatus.finalized:
        return const _WorkflowStatusVisual(
          backgroundColor: Color(0xFFDBEAFE),
          borderColor: Color(0xFF93C5FD),
          foregroundColor: Color(0xFF1F2937),
          icon: Icons.verified_outlined,
        );

      case EmrSignOffWorkflowStatus.reportReady:
        return const _WorkflowStatusVisual(
          backgroundColor: Color(0xFFD1FAE5),
          borderColor: Color(0xFF6EE7B7),
          foregroundColor: Color(0xFF1F2937),
          icon: Icons.picture_as_pdf_outlined,
        );

      case EmrSignOffWorkflowStatus.transmitted:
        return const _WorkflowStatusVisual(
          backgroundColor: Color(0xFFCCFBF1),
          borderColor: Color(0xFF5EEAD4),
          foregroundColor: Color(0xFF1F2937),
          icon: Icons.send_outlined,
        );
    }
  }
}

final class _WorkflowStatusVisual {
  const _WorkflowStatusVisual({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final IconData icon;
}
