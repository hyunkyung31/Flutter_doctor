import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/emr_sign_off.dart';
import '../model/emr_sign_off_workflow_item.dart';
import '../model/emr_sign_off_workflow_status.dart';
import '../model/update_emr_sign_off_request.dart';
import '../view_model/emr_sign_off_view_model.dart';

final class EmrSignOffDetailView extends StatefulWidget {
  const EmrSignOffDetailView({super.key, required this.item});

  final EmrSignOffWorkflowItem item;

  @override
  State<EmrSignOffDetailView> createState() {
    return _EmrSignOffDetailViewState();
  }
}

final class _EmrSignOffDetailViewState extends State<EmrSignOffDetailView> {
  late final TextEditingController _finalResultController;

  EmrSignOff? _currentSignOff;

  @override
  void initState() {
    super.initState();

    _currentSignOff = widget.item.signOff;

    _finalResultController = TextEditingController(
      text: widget.item.signOff.finalResult,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _loadSignOff();
    });
  }

  @override
  void dispose() {
    _finalResultController.dispose();
    super.dispose();
  }

  Future<void> _loadSignOff() async {
    final signOffId = int.tryParse(widget.item.signOffId);

    if (signOffId == null) {
      _showMessage('SIGN OFF 식별자가 올바르지 않습니다.');
      return;
    }

    final viewModel = context.read<EmrSignOffViewModel>();

    final success = await viewModel.loadSignOff(signOffId: signOffId);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(viewModel.errorMessage ?? 'SIGN OFF 정보를 불러오지 못했습니다.');
      return;
    }

    final loadedSignOff = viewModel.selectedSignOff;

    if (loadedSignOff == null) {
      _showMessage('SIGN OFF 응답 데이터가 없습니다.');
      return;
    }

    setState(() {
      _currentSignOff = loadedSignOff;
      _finalResultController.text = loadedSignOff.finalResult;
    });
  }

  Future<void> _saveDraft() async {
    final signOff = _currentSignOff;

    if (signOff == null) {
      _showMessage('SIGN OFF 정보를 확인할 수 없습니다.');
      return;
    }

    if (signOff.finalized) {
      _showMessage('이미 최종 승인된 소견은 수정할 수 없습니다.');
      return;
    }

    final finalResult = _finalResultController.text.trim();

    if (finalResult.isEmpty) {
      _showMessage('의료진 소견을 입력해 주세요.');
      return;
    }

    final signOffId = int.tryParse(signOff.id);

    if (signOffId == null) {
      _showMessage('SIGN OFF 식별자가 올바르지 않습니다.');
      return;
    }

    final viewModel = context.read<EmrSignOffViewModel>();

    final updatedSignOff = await viewModel.updateSignOff(
      signOffId: signOffId,
      request: UpdateEmrSignOffRequest(
        finalResult: finalResult,
        finalized: false,
      ),
    );

    if (!mounted) {
      return;
    }

    if (updatedSignOff == null) {
      _showMessage(viewModel.errorMessage ?? '의료진 소견을 저장하지 못했습니다.');
      return;
    }

    setState(() {
      _currentSignOff = updatedSignOff;
      _finalResultController.text = updatedSignOff.finalResult;
    });

    _showMessage('의료진 소견을 저장했습니다.');
  }

  Future<void> _finalizeSignOff() async {
    final signOff = _currentSignOff;

    if (signOff == null) {
      _showMessage('SIGN OFF 정보를 확인할 수 없습니다.');
      return;
    }

    if (signOff.finalized) {
      _showMessage('이미 최종 승인된 SIGN OFF입니다.');
      return;
    }

    final finalResult = _finalResultController.text.trim();

    if (finalResult.isEmpty) {
      _showMessage('최종 소견을 입력해 주세요.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('SIGN OFF 최종 승인'),
          content: const Text(
            '최종 승인 후에는 의료진 소견을 수정할 수 없습니다.\n'
            '계속 진행하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('최종 승인'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final signOffId = int.tryParse(signOff.id);

    if (signOffId == null) {
      _showMessage('SIGN OFF 식별자가 올바르지 않습니다.');
      return;
    }

    final viewModel = context.read<EmrSignOffViewModel>();

    final updatedSignOff = await viewModel.updateSignOff(
      signOffId: signOffId,
      request: UpdateEmrSignOffRequest(
        finalResult: finalResult,
        finalized: true,
      ),
    );

    if (!mounted) {
      return;
    }

    if (updatedSignOff == null) {
      _showMessage(viewModel.errorMessage ?? 'SIGN OFF 최종 승인에 실패했습니다.');
      return;
    }

    setState(() {
      _currentSignOff = updatedSignOff;
      _finalResultController.text = updatedSignOff.finalResult;
    });

    final reportSignOff = await viewModel.generateReport(signOffId: signOffId);

    if (!mounted) {
      return;
    }

    if (reportSignOff == null) {
      _showMessage(
        viewModel.errorMessage ?? 'SIGN OFF는 완료되었지만 환자용 보고서를 생성하지 못했습니다.',
      );
      return;
    }

    setState(() {
      _currentSignOff = reportSignOff;
    });

    _showMessage('SIGN OFF와 환자용 보고서 생성이 완료되었습니다.');
  }

  EmrSignOffWorkflowStatus _resolveCurrentStatus(EmrSignOff signOff) {
    if (signOff.emrTransmitted) {
      return EmrSignOffWorkflowStatus.transmitted;
    }

    if (signOff.reportReady) {
      return EmrSignOffWorkflowStatus.reportReady;
    }

    if (signOff.finalized) {
      return EmrSignOffWorkflowStatus.finalized;
    }

    final consultation = widget.item.consultation;

    if (consultation == null) {
      return EmrSignOffWorkflowStatus.draft;
    }

    final consultationStatus = consultation.status.trim().toLowerCase();

    if (consultation.responseMemo.trim().isNotEmpty ||
        consultationStatus == 'completed') {
      return EmrSignOffWorkflowStatus.consultationAnswered;
    }

    if (consultation.isPending ||
        consultationStatus == 'accepted' ||
        consultationStatus == 'in_progress') {
      return EmrSignOffWorkflowStatus.consultationPending;
    }

    return EmrSignOffWorkflowStatus.draft;
  }

  String _dateTimeText(DateTime date) {
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EmrSignOffViewModel>();

    final signOff = _currentSignOff ?? widget.item.signOff;

    final isFinalized = signOff.finalized;

    final isFinalizing = viewModel.isSubmitting || viewModel.isGeneratingReport;

    final consultation = widget.item.consultation;

    return Scaffold(
      appBar: AppBar(title: const Text('SIGN OFF 상세'), centerTitle: true),
      body: SafeArea(
        child: viewModel.isLoading && _currentSignOff == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                children: [
                  _InformationCard(
                    title: '환자 및 검사 정보',
                    icon: Icons.person_search_outlined,
                    children: [
                      _InformationRow(
                        label: '환자',
                        value: widget.item.patientName,
                      ),
                      _InformationRow(
                        label: '환자 ID',
                        value: widget.item.patientId,
                      ),
                      _InformationRow(
                        label: '검사 ID',
                        value: widget.item.examId?.toString() ?? '정보 없음',
                      ),
                      _InformationRow(
                        label: '현재 상태',
                        value: _resolveCurrentStatus(signOff).label,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _InformationCard(
                    title: 'AI 분석 결과',
                    icon: Icons.analytics_outlined,
                    children: [_AiResultContent(aiResult: signOff.aiResult)],
                  ),

                  if (consultation != null) ...[
                    const SizedBox(height: 16),

                    _InformationCard(
                      title: '협진 내용',
                      icon: Icons.groups_outlined,
                      children: [
                        _InformationRow(
                          label: '협진 상태',
                          value: consultation.status.trim().isEmpty
                              ? '상태 정보 없음'
                              : consultation.status,
                        ),
                        _InformationRow(
                          label: '요청 사유',
                          value: consultation.reason.trim().isEmpty
                              ? '등록된 요청 사유가 없습니다.'
                              : consultation.reason,
                        ),
                        _InformationRow(
                          label: '협진 답변',
                          value: consultation.responseMemo.trim().isEmpty
                              ? '아직 등록된 협진 답변이 없습니다.'
                              : consultation.responseMemo,
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  _InformationCard(
                    title: '최종 의료진 소견',
                    icon: Icons.edit_note_outlined,
                    children: [
                      TextField(
                        controller: _finalResultController,
                        minLines: 8,
                        maxLines: 14,
                        maxLength: 3000,
                        enabled: !isFinalized && !viewModel.isSubmitting,
                        decoration: InputDecoration(
                          hintText: 'AI 분석 결과와 협진 답변을 참고하여 최종 소견을 입력하세요.',
                          alignLabelWithHint: true,
                          border: const OutlineInputBorder(),
                          filled: isFinalized,
                        ),
                      ),

                      if (isFinalized)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  '최종 승인된 소견은 수정할 수 없습니다.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (!isFinalized) ...[
                    OutlinedButton.icon(
                      onPressed: isFinalizing ? null : _saveDraft,
                      icon: const Icon(Icons.save_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Text('초안 저장'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    FilledButton.icon(
                      onPressed: isFinalizing ? null : _finalizeSignOff,
                      icon: isFinalizing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Text(
                          isFinalizing ? 'SIGN OFF 처리 중...' : 'SIGN OFF 최종 승인',
                        ),
                      ),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.verified),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Text('SIGN OFF 완료'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _InformationCard(
                      title: '환자용 임상 보고서',
                      icon: Icons.description_outlined,
                      children: [
                        _InformationRow(
                          label: '보고서 상태',
                          value: signOff.reportReady
                              ? '환자 앱에서 확인 가능'
                              : viewModel.isGeneratingReport
                              ? '보고서 생성 중'
                              : '보고서 생성 실패 또는 대기 중',
                        ),

                        if (signOff.reportGeneratedAt != null)
                          _InformationRow(
                            label: '생성 시각',
                            value: _dateTimeText(signOff.reportGeneratedAt!),
                          ),

                        Text(
                          signOff.reportReady
                              ? '아래에서 최종 보고서 내용을 확인할 수 있으며 환자는 환자용 앱에서 PDF로 받을 수 있습니다.'
                              : '환자용 보고서가 아직 생성되지 않았습니다.',
                        ),
                      ],
                    ),

                    if (signOff.reportReady) ...[
                      const SizedBox(height: 16),

                      _ClinicalReportPreview(
                        signOff: signOff,
                        item: widget.item,
                        generatedAtText: signOff.reportGeneratedAt == null
                            ? null
                            : _dateTimeText(signOff.reportGeneratedAt!),
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}

final class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 9),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

final class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}

final class _AiResultContent extends StatelessWidget {
  const _AiResultContent({required this.aiResult});

  final EmrAiResultReference? aiResult;

  @override
  Widget build(BuildContext context) {
    final data = aiResult?.data;

    if (data == null || data.isEmpty) {
      return const Text('상세 AI 분석 결과가 응답에 포함되지 않았습니다.');
    }

    final entries = data.entries.where((entry) {
      return entry.key != 'id' &&
          entry.key != 'ai_result_id' &&
          entry.key != 'exam_id';
    }).toList();

    if (entries.isEmpty) {
      return const Text('상세 AI 분석 결과가 응답에 포함되지 않았습니다.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        return _InformationRow(
          label: entry.key,
          value: entry.value?.toString() ?? '정보 없음',
        );
      }).toList(),
    );
  }
}

final class _ClinicalReportPreview extends StatelessWidget {
  const _ClinicalReportPreview({
    required this.signOff,
    required this.item,
    required this.generatedAtText,
  });

  final EmrSignOff signOff;
  final EmrSignOffWorkflowItem item;
  final String? generatedAtText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final consultation = item.consultation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '관상동맥 조영술 임상 보고서',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            '최종 승인된 의료진 보고서 미리보기',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 20),

          const Divider(),

          const SizedBox(height: 16),

          _ReportSection(
            title: '환자 및 검사 정보',
            children: [
              _ReportRow(label: '환자', value: item.patientName),
              _ReportRow(label: '환자 ID', value: item.patientId),
              _ReportRow(
                label: '검사 ID',
                value: item.examId?.toString() ?? '정보 없음',
              ),
              _ReportRow(
                label: '보고서 생성 시각',
                value: generatedAtText ?? '생성 시각 정보 없음',
              ),
            ],
          ),

          const SizedBox(height: 20),

          _ReportSection(
            title: 'AI 보조 분석 결과',
            children: [
              SelectableText(
                signOff.aiSummary.trim().isEmpty
                    ? 'AI 보조 분석 결과가 보고서 응답에 포함되지 않았습니다.'
                    : signOff.aiSummary,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _ReportSection(
            title: 'AI 분석에 대한 안내',
            children: [
              SelectableText(
                signOff.xaiExplanation.trim().isEmpty
                    ? 'AI 분석에 대한 안내가 보고서 응답에 포함되지 않았습니다.'
                    : signOff.xaiExplanation,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ],
          ),

          if (consultation != null) ...[
            const SizedBox(height: 20),

            _ReportSection(
              title: '협진 소견',
              children: [
                _ReportRow(
                  label: '협진 상태',
                  value: consultation.status.trim().isEmpty
                      ? '상태 정보 없음'
                      : consultation.status,
                ),
                _ReportRow(
                  label: '협진 요청 사유',
                  value: consultation.reason.trim().isEmpty
                      ? '등록된 협진 요청 사유가 없습니다.'
                      : consultation.reason,
                ),
                _ReportRow(
                  label: '협진 답변',
                  value: consultation.responseMemo.trim().isEmpty
                      ? '등록된 협진 답변이 없습니다.'
                      : consultation.responseMemo,
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          _ReportSection(
            title: '최종 의료진 소견',
            children: [
              SelectableText(
                signOff.finalResult.trim().isEmpty
                    ? '등록된 최종 의료진 소견이 없습니다.'
                    : signOff.finalResult,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '본 보고서는 담당 의료진의 SIGN OFF가 완료된 최종 보고서입니다.',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

final class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(value, style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }
}
