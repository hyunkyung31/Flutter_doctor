import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../patient/model/patient.dart';
import '../model/patient_memo.dart';
import '../view_model/memo_view_model.dart';

final class MemoDetailView extends StatefulWidget {
  const MemoDetailView({
    super.key,
    required this.patient,
    required this.memo,
  });

  final Patient patient;
  final PatientMemo memo;

  @override
  State<MemoDetailView> createState() => _MemoDetailViewState();
}

final class _MemoDetailViewState extends State<MemoDetailView> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MemoViewModel>();

    final memo = viewModel.memoById(widget.memo.id) ??
        viewModel.selectedMemo ??
        widget.memo;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '메모 상세',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<_MemoAction>(
            onSelected: (action) {
              switch (action) {
                case _MemoAction.edit:
                  _openEditView(context, memo);
                  return;

                case _MemoAction.delete:
                  _confirmDelete(context, viewModel, memo);
                  return;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: _MemoAction.edit,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('수정'),
                  ),
                ),
                PopupMenuItem(
                  value: _MemoAction.delete,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: Text(
                      '삭제',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _MemoTypeBadge(memo: memo),
            const SizedBox(height: 16),
            Text(
              memo.title.trim().isEmpty
                  ? memo.isVoiceMemo
                      ? '음성 메모'
                      : '제목 없는 메모'
                  : memo.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            if (memo.isTextMemo)
              _TextMemoContent(memo: memo)
            else
              _VoiceMemoContent(memo: memo),
            const SizedBox(height: 20),
            _MemoInformationCard(
              memo: memo,
              patient: widget.patient,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: viewModel.isDeleting
                        ? null
                        : () => _openEditView(
                              context,
                              memo,
                            ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('수정'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.error,
                      foregroundColor:
                          Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: viewModel.isDeleting
                        ? null
                        : () => _confirmDelete(
                              context,
                              viewModel,
                              memo,
                            ),
                    icon: viewModel.isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(
                      viewModel.isDeleting ? '삭제 중' : '삭제',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditView(
    BuildContext context,
    PatientMemo memo,
  ) async {
    final changed = await context.pushNamed<bool>(
      'memoEdit',
      pathParameters: {
        'memoId': memo.id.toString(),
      },
      extra: <String, dynamic>{
        'patient': widget.patient,
        'memo': memo,
      },
    );

    if (!mounted || changed != true) return;

    await context.read<MemoViewModel>().loadMemo(
          memoId: memo.id,
        );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MemoViewModel viewModel,
    PatientMemo memo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('메모 삭제'),
          content: const Text(
            '이 메모를 삭제하시겠습니까?\n삭제한 메모는 복구할 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error,
                foregroundColor:
                    Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final success = await viewModel.deleteMemo(
      memoId: memo.id,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ??
                '메모를 삭제하지 못했습니다.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('메모를 삭제했습니다.'),
      ),
    );

    Navigator.of(context).pop(true);
  }
}

enum _MemoAction {
  edit,
  delete,
}

final class _MemoTypeBadge extends StatelessWidget {
  const _MemoTypeBadge({
    required this.memo,
  });

  final PatientMemo memo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = memo.isVoiceMemo
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;

    final foregroundColor = memo.isVoiceMemo
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              memo.isVoiceMemo
                  ? Icons.mic_none
                  : Icons.description_outlined,
              size: 17,
              color: foregroundColor,
            ),
            const SizedBox(width: 6),
            Text(
              memo.isVoiceMemo ? '음성 메모' : '텍스트 메모',
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TextMemoContent extends StatelessWidget {
  const _TextMemoContent({
    required this.memo,
  });

  final PatientMemo memo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SelectableText(
          memo.content.trim().isEmpty
              ? '작성된 내용이 없습니다.'
              : memo.content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
        ),
      ),
    );
  }
}

final class _VoiceMemoContent extends StatelessWidget {
  const _VoiceMemoContent({
    required this.memo,
  });

  final PatientMemo memo;

  @override
  Widget build(BuildContext context) {
    final duration = memo.audioDurationSeconds;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton.filled(
                  tooltip: '음성 재생',
                  onPressed: memo.hasAudio
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '음성 재생 기능은 다음 단계에서 연결합니다.',
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: memo.hasAudio ? 0 : null,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  duration == null
                      ? '--:--'
                      : _durationText(duration),
                ),
              ],
            ),
            if (memo.hasTranscript) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                '음성 변환 내용',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                memo.transcript,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.6),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _durationText(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds =
        (seconds % 60).toString().padLeft(2, '0');

    return '$minutes:$remainingSeconds';
  }
}

final class _MemoInformationCard extends StatelessWidget {
  const _MemoInformationCard({
    required this.memo,
    required this.patient,
  });

  final PatientMemo memo;
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _InformationRow(
              icon: Icons.calendar_today_outlined,
              label: '작성일',
              value: _dateText(memo.createdAt),
            ),
            const SizedBox(height: 14),
            _InformationRow(
              icon: Icons.person_outline,
              label: '작성자',
              value: memo.doctorId.trim().isEmpty
                  ? '정보 없음'
                  : memo.doctorId,
            ),
            const SizedBox(height: 14),
            _InformationRow(
              icon: Icons.badge_outlined,
              label: '환자',
              value:
                  '${patient.patientName} · ${patient.patientId}',
            ),
            if (memo.examId != null) ...[
              const SizedBox(height: 14),
              _InformationRow(
                icon: Icons.monitor_heart_outlined,
                label: '연결 검사',
                value: '검사 ${memo.examId}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dateText(DateTime? value) {
    if (value == null) {
      return '정보 없음';
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

final class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}