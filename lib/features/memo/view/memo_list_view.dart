import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../patient/model/patient.dart';
import '../model/patient_memo.dart';
import '../view_model/memo_view_model.dart';

final class MemoListView extends StatefulWidget {
  const MemoListView({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  State<MemoListView> createState() => _MemoListViewState();
}

final class _MemoListViewState extends State<MemoListView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<MemoViewModel>().loadMemos(
            patientId: widget.patient.patientId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MemoViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '환자 메모',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: '새 메모',
            onPressed: () => _openCreateView(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          _PatientHeader(patient: widget.patient),
          _MemoFilterBar(viewModel: viewModel),
          Expanded(
            child: _MemoListBody(
              patient: widget.patient,
              viewModel: viewModel,
              onCreate: () => _openCreateView(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateView(BuildContext context) async {
    final created = await context.pushNamed<bool>(
      'memoCreate',
      pathParameters: {
        'patientId': widget.patient.patientId,
      },
      extra: widget.patient,
    );

    if (!mounted || created != true) return;

    await context.read<MemoViewModel>().refreshMemos(
          patientId: widget.patient.patientId,
        );
  }
}

final class _PatientHeader extends StatelessWidget {
  const _PatientHeader({
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = patient.patientName.trim().isEmpty
        ? '?'
        : patient.patientName.trim().substring(0, 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.patientName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${patient.genderText} · ${patient.age}세',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '환자 ID  ${patient.patientId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _MemoFilterBar extends StatelessWidget {
  const _MemoFilterBar({
    required this.viewModel,
  });

  final MemoViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<MemoFilter>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: MemoFilter.all,
              label: Text('전체 ${viewModel.totalCount}'),
            ),
            ButtonSegment(
              value: MemoFilter.text,
              label: Text('텍스트 ${viewModel.textCount}'),
            ),
            ButtonSegment(
              value: MemoFilter.voice,
              label: Text('음성 ${viewModel.voiceCount}'),
            ),
          ],
          selected: {viewModel.filter},
          onSelectionChanged: (selection) {
            viewModel.changeFilter(selection.first);
          },
        ),
      ),
    );
  }
}

final class _MemoListBody extends StatelessWidget {
  const _MemoListBody({
    required this.patient,
    required this.viewModel,
    required this.onCreate,
  });

  final Patient patient;
  final MemoViewModel viewModel;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final memos = viewModel.filteredMemos;

    if (viewModel.isLoading && viewModel.memos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewModel.errorMessage != null &&
        viewModel.memos.isEmpty) {
      return _MemoLoadError(
        message: viewModel.errorMessage!,
        onRetry: () {
          viewModel.loadMemos(
            patientId: patient.patientId,
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        return viewModel.refreshMemos(
          patientId: patient.patientId,
        );
      },
      child: memos.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 90),
                const Icon(
                  Icons.note_alt_outlined,
                  size: 64,
                ),
                const SizedBox(height: 14),
                Text(
                  _emptyMessage(viewModel.filter),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('새 메모 작성'),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              itemCount: memos.length,
              separatorBuilder: (_, __) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (context, index) {
                final memo = memos[index];

                return _MemoCard(
                  memo: memo,
                  onTap: () async {
                    final changed = await context.pushNamed<bool>(
                      'memoDetail',
                      pathParameters: {
                        'memoId': memo.id.toString(),
                      },
                      extra: <String, dynamic>{
                        'patient': patient,
                        'memo' : memo,
                      },
                    );

                    if (!context.mounted || changed != true) return;

                    await viewModel.refreshMemos(
                      patientId: patient.patientId,
                    );
                  },
                );
              },
            ),
    );
  }

  String _emptyMessage(MemoFilter filter) {
    return switch (filter) {
      MemoFilter.all => '작성된 메모가 없습니다.',
      MemoFilter.text => '작성된 텍스트 메모가 없습니다.',
      MemoFilter.voice => '작성된 음성 메모가 없습니다.',
    };
  }
}

final class _MemoCard extends StatelessWidget {
  const _MemoCard({
    required this.memo,
    required this.onTap,
  });

  final PatientMemo memo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: memo.isVoiceMemo
                    ? colorScheme.errorContainer
                    : colorScheme.primaryContainer,
                foregroundColor: memo.isVoiceMemo
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
                child: Icon(
                  memo.isVoiceMemo
                      ? Icons.mic_none
                      : Icons.description_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memo.title.trim().isEmpty
                          ? memo.isVoiceMemo
                              ? '음성 메모'
                              : '제목 없는 메모'
                          : memo.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      memo.isVoiceMemo
                          ? _voiceDescription(memo)
                          : memo.displayContent,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_dateText(memo.createdAt)} · ${memo.doctorId}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _voiceDescription(PatientMemo memo) {
    final duration = memo.audioDurationSeconds;

    if (duration == null) {
      return memo.displayContent;
    }

    final minutes = duration ~/ 60;
    final seconds = (duration % 60).toString().padLeft(2, '0');

    return '음성 메모  $minutes:$seconds';
  }

  String _dateText(DateTime? value) {
    if (value == null) {
      return '작성일 정보 없음';
    }

    final local = value.toLocal();

    String twoDigits(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${local.year}.${twoDigits(local.month)}.'
        '${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

final class _MemoLoadError extends StatelessWidget {
  const _MemoLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
