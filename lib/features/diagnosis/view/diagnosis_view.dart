// ai 분석 요청 화면
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../patient/model/patient.dart';
import '../../patient/view_model/patient_list_view_model.dart';
import '../../clinical_report/widgets/emr_sign_off_draft_card.dart';
import '../../clinical_report/model/create_emr_sign_off_request.dart';
import '../../clinical_report/model/update_emr_sign_off_request.dart';
import '../../clinical_report/view_model/emr_sign_off_view_model.dart';
import '../model/ai_analysis_type.dart';
import '../model/diagnosis_examination.dart';
import '../view_model/diagnosis_view_model.dart';
import '../../ai_result/widgets/ai_result_media_viewer.dart';
import '../../consultation/model/consultation_form_args.dart';

final class DiagnosisView extends StatefulWidget {
  const DiagnosisView({super.key});

  @override
  State<DiagnosisView> createState() {
    return _DiagnosisViewState();
  }
}

final class _DiagnosisViewState extends State<DiagnosisView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await context.read<DiagnosisViewModel>().initialize();

      if (!mounted) {
        return;
      }

      await context.read<EmrSignOffViewModel>().loadSignOffs();
    });
  }

  Future<bool> _saveSignOffDraft(String opinion) async {
    final diagnosisViewModel = context.read<DiagnosisViewModel>();
    final signOffViewModel = context.read<EmrSignOffViewModel>();

    final patientId = diagnosisViewModel.patientId?.trim();
    final examination = diagnosisViewModel.selectedExamination;

    if (patientId == null || patientId.isEmpty) {
      _showMessage('선택된 환자 정보가 없습니다.');
      return false;
    }

    if (examination == null) {
      _showMessage('선택된 검사 정보가 없습니다.');
      return false;
    }

    final normalizedOpinion = opinion.trim();

    if (normalizedOpinion.isEmpty) {
      _showMessage('의료진 소견을 입력해 주세요.');
      return false;
    }

    final loaded = await signOffViewModel.loadSignOffs();

    if (!mounted) {
      return false;
    }

    if (!loaded) {
      _showMessage(signOffViewModel.errorMessage ?? '기존 의료진 소견을 확인하지 못했습니다.');
      return false;
    }

    final existingSignOff = signOffViewModel.findSignOffByExamId(
      patientId: patientId,
      examId: examination.examId,
    );

    if (existingSignOff?.finalized ?? false) {
      _showMessage('이미 SIGN OFF가 완료된 검사는 소견을 수정할 수 없습니다.');
      return false;
    }

    if (existingSignOff == null) {
      final createdSignOff = await signOffViewModel.createSignOff(
        request: CreateEmrSignOffRequest(
          patientId: patientId,
          examId: examination.examId,
          finalResult: normalizedOpinion,
        ),
      );

      if (!mounted) {
        return false;
      }

      if (createdSignOff == null) {
        _showMessage(signOffViewModel.errorMessage ?? '의료진 소견 초안을 저장하지 못했습니다.');
        return false;
      }

      return true;
    }

    final signOffId = int.tryParse(existingSignOff.id);

    if (signOffId == null || signOffId <= 0) {
      _showMessage('저장된 의료진 소견의 ID가 올바르지 않습니다.');
      return false;
    }

    final updatedSignOff = await signOffViewModel.updateSignOff(
      signOffId: signOffId,
      request: UpdateEmrSignOffRequest(finalResult: normalizedOpinion),
    );

    if (!mounted) {
      return false;
    }

    if (updatedSignOff == null) {
      _showMessage(signOffViewModel.errorMessage ?? '의료진 소견 초안을 수정하지 못했습니다.');
      return false;
    }

    return true;
  }

  Future<void> _openConsultationForm(String opinion) async {
    final diagnosisViewModel = context.read<DiagnosisViewModel>();

    final patient = diagnosisViewModel.selectedPatient;
    final examination = diagnosisViewModel.selectedExamination;

    if (patient == null) {
      _showMessage('선택된 환자 정보가 없습니다.');
      return;
    }

    if (examination == null) {
      _showMessage('선택된 검사 정보가 없습니다.');
      return;
    }

    final saved = await _saveSignOffDraft(opinion);

    if (!mounted || !saved) {
      return;
    }

    final consultationCreated = await context.pushNamed<bool>(
      'consultationForm',
      extra: ConsultationFormArgs(
        patient: patient,
        examId: examination.examId,
        initialMemo: opinion.trim(),
      ),
    );

    if (!mounted || consultationCreated != true) {
      return;
    }

    _showMessage('협진 요청이 등록되었습니다.');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final diagnosisViewModel = context.watch<DiagnosisViewModel>();

    final patientListViewModel = context.watch<PatientListViewModel>();

    final signOffViewModel = context.watch<EmrSignOffViewModel>();

    final selectedPatientId = diagnosisViewModel.patientId;
    final selectedExamId = diagnosisViewModel.selectedExamination?.examId;

    final existingSignOff = selectedPatientId == null || selectedExamId == null
        ? null
        : signOffViewModel.findSignOffByExamId(
            patientId: selectedPatientId,
            examId: selectedExamId,
          );

    final patients = _mergePatients(
      // 환자 상세환자에서 진입한 환자가 전역 환자 목록에 없을 경우를 대비해 병합
      patientListViewModel.patients,
      diagnosisViewModel.selectedPatient,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('AI 분석 요청')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const _ScreenHeader(),

            const SizedBox(height: 24),

            _SectionHeader(
              step: 1,
              title: '환자 선택',
              description: 'AI 분석을 실행할 환자를 선택합니다.',
            ),

            const SizedBox(height: 12),

            _PatientSelectionCard(
              //환자 선택되면 상세 api호출 - 검사 목록 불러옴
              patients: patients,
              selectedPatient: diagnosisViewModel.selectedPatient,
              isLoadingPatients: patientListViewModel.isLoading,
              isLoadingExaminations: diagnosisViewModel.isLoadingExaminations,
              isEnabled: !diagnosisViewModel.isBusy,
              patientListError: patientListViewModel.errorMessage,
              onRefreshPatients: patientListViewModel.loadPatients,
              onSelected: (patient) async {
                await diagnosisViewModel.selectPatient(patient);
              },
            ),

            const SizedBox(height: 24),

            _SectionHeader(
              // 키프레임 등록된 검사 선택
              step: 2,
              title: '검사 선택',
              description: '키프레임이 등록된 관상동맥 검사를 선택합니다.',
            ),

            const SizedBox(height: 12),

            _ExaminationSelectionCard(
              // 선택된 환자의 검사 목록과 ai 분석 가능 여부 표시
              examinations: diagnosisViewModel.examinations,
              selectedExamination: diagnosisViewModel.selectedExamination,
              isLoading: diagnosisViewModel.isLoadingExaminations,
              isEnabled:
                  diagnosisViewModel.hasSelectedPatient &&
                  !diagnosisViewModel.isBusy,
              onSelected: diagnosisViewModel.selectExamination,
            ),

            const SizedBox(height: 24),

            _SectionHeader(
              // 통합 분석 결과의 기본 표시 방식 선택
              step: 3,
              title: '결과 보기 방식',
              description: '통합 분석 결과에서 확인할 표시 방식을 선택합니다.',
            ),

            const SizedBox(height: 12),

            ...AiAnalysisType.values.map((analysisType) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AnalysisTypeCard(
                  analysisType: analysisType,
                  isSelected:
                      diagnosisViewModel.selectedAnalysisType == analysisType,
                  isEnabled: !diagnosisViewModel.isBusy,
                  onSelected: () {
                    diagnosisViewModel.selectAnalysisType(analysisType);
                  },
                ),
              );
            }),

            if (diagnosisViewModel //환자 조회 또는 ai분석 요청 중 발생한 오류 표시
                    .errorMessage !=
                null) ...[
              const SizedBox(height: 8),
              _ErrorCard(
                message: diagnosisViewModel.errorMessage!,
                onDismiss: diagnosisViewModel.clearError,
              ),
            ],

            const SizedBox(height: 12),

            if (diagnosisViewModel.isBusy) // 환자 조회 또는 ai분석 요청 중 표시
              const _AnalysisProgressCard(),

            if (diagnosisViewModel.hasCompletedAnalysis) ...[
              const SizedBox(height: 12),

              _AnalysisCompletedCard(viewModel: diagnosisViewModel),

              const SizedBox(height: 16),

              EmrSignOffDraftCard(
                key: ValueKey(
                  '${selectedPatientId ?? ''}-${selectedExamId ?? ''}',
                ),
                initialValue: existingSignOff?.finalResult ?? '',
                isEnabled:
                    diagnosisViewModel.selectedPatient != null &&
                    diagnosisViewModel.selectedExamination != null &&
                    !(existingSignOff?.finalized ?? false),
                isSubmitting:
                    signOffViewModel.isLoading || signOffViewModel.isSubmitting,
                onSaveDraft: _saveSignOffDraft,
                onRequestConsultation: _openConsultationForm,
              ),
            ],
            const SizedBox(height: 24),

            if (!diagnosisViewModel.hasCompletedAnalysis)
              FilledButton.icon(
                onPressed: diagnosisViewModel.canRunAnalysis
                    ? () async {
                        await diagnosisViewModel.runAnalysis();
                      }
                    : null,
                icon: Icon(
                  diagnosisViewModel.isBusy
                      ? Icons.hourglass_top_rounded
                      : Icons.auto_awesome,
                ),

                label: Text(diagnosisViewModel.isBusy ? 'AI 분석 중' : 'AI 분석 시작'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: diagnosisViewModel.clearAnalysisResult,
                icon: const Icon(Icons.tune_outlined),
                label: const Text('분석 조건 변경'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

            const SizedBox(height: 12),

            Text(
              'AI 분석 결과는 의료진의 임상적 판단을 보조하며 최종 진단을 대신하지 않습니다.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Patient> _mergePatients(
    List<Patient> patients,
    Patient? selectedPatient,
  ) {
    final patientMap = <String, Patient>{};

    for (final patient in patients) {
      final patientId = patient.patientId.trim();

      if (patientId.isNotEmpty) {
        patientMap[patientId] = patient;
      }
    }

    if (selectedPatient != null) {
      final selectedPatientId = selectedPatient.patientId.trim();

      if (selectedPatientId.isNotEmpty) {
        patientMap.putIfAbsent(selectedPatientId, () => selectedPatient);
      }
    }

    return patientMap.values.toList(growable: false);
  }
}

// 화면 상단에 ai분석 목적과 안내 문구 표시
final class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.monitor_heart_outlined,
              color: colorScheme.onPrimary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 영상 판독 지원',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '관상동맥 조영 영상의 병변 위치와 정상·협착 분류 결과를 확인합니다.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    height: 1.5,
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

// 환자 선택, 검사 선택과 결과 보기 방식의 단계 제목을 표시
final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.step,
    required this.title,
    required this.description,
  });

  final int step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          child: Text(
            '$step',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 3),

              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 환자 드롭다운, 환자 목록 재시도와 선택된 환자 요약 표시
final class _PatientSelectionCard extends StatelessWidget {
  const _PatientSelectionCard({
    required this.patients,
    required this.selectedPatient,
    required this.isLoadingPatients,
    required this.isLoadingExaminations,
    required this.isEnabled,
    required this.patientListError,
    required this.onRefreshPatients,
    required this.onSelected,
  });

  final List<Patient> patients;
  final Patient? selectedPatient;
  final bool isLoadingPatients;
  final bool isLoadingExaminations;
  final bool isEnabled;
  final String? patientListError;
  final Future<void> Function() onRefreshPatients;
  final Future<void> Function(Patient) onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedPatientId = selectedPatient?.patientId.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoadingPatients) const LinearProgressIndicator(),

            if (isLoadingPatients) const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              key: ValueKey(selectedPatientId),
              initialValue: selectedPatientId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '환자',
                prefixIcon: Icon(Icons.person_search),
                border: OutlineInputBorder(),
              ),
              hint: const Text('환자를 선택해 주세요.'),
              items: patients.map((patient) {
                final displayName = patient.patientName.trim().isEmpty
                    ? '이름 미등록'
                    : patient.patientName.trim();

                return DropdownMenuItem<String>(
                  value: patient.patientId,
                  child: Text(
                    '$displayName · ${patient.patientId}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged:
                  !isEnabled || isLoadingPatients || isLoadingExaminations
                  ? null
                  : (patientId) async {
                      final patient = _findPatient(patientId);

                      if (patient != null) {
                        await onSelected(patient);
                      }
                    },
            ),

            if (patientListError != null && patients.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                patientListError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onRefreshPatients,
                icon: const Icon(Icons.refresh),
                label: const Text('환자 목록 다시 불러오기'),
              ),
            ],

            if (isLoadingExaminations) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('환자 검사 정보를 불러오는 중입니다.'),
                ],
              ),
            ],

            if (selectedPatient != null && !isLoadingExaminations) ...[
              const SizedBox(height: 16),
              _SelectedPatientSummary(patient: selectedPatient!),
            ],
          ],
        ),
      ),
    );
  }

  Patient? _findPatient(String? patientId) {
    if (patientId == null) {
      return null;
    }

    for (final patient in patients) {
      if (patient.patientId == patientId) {
        return patient;
      }
    }

    return null;
  }
}

// 선택된 환자의 이름, id, 성별과 나이 요약
final class _SelectedPatientSummary extends StatelessWidget {
  const _SelectedPatientSummary({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final displayName = patient.patientName.trim().isEmpty
        ? '이름 미등록'
        : patient.patientName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Text(
              displayName == '이름 미등록' ? '?' : displayName.substring(0, 1),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '환자 ID ${patient.patientId} · ${patient.genderText} · ${patient.age}세',
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

// 환자 검사 목록 제공, 분석할 검사 선택
final class _ExaminationSelectionCard extends StatelessWidget {
  const _ExaminationSelectionCard({
    required this.examinations,
    required this.selectedExamination,
    required this.isLoading,
    required this.isEnabled,
    required this.onSelected,
  });

  final List<DiagnosisExamination> examinations;

  final DiagnosisExamination? selectedExamination;

  final bool isLoading;
  final bool isEnabled;

  final void Function(DiagnosisExamination?) onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedExamId = selectedExamination?.examId;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey(selectedExamId),
              initialValue: selectedExamId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '검사',
                prefixIcon: Icon(Icons.image_search),
                border: OutlineInputBorder(),
              ),
              hint: Text(isLoading ? '검사 정보를 불러오는 중입니다.' : '검사를 선택해 주세요.'),
              items: examinations.map((examination) {
                final availabilityText = examination.canRunIntegratedAnalysis
                    ? ''
                    : ' · 키프레임 없음';

                return DropdownMenuItem<int>(
                  value: examination.examId,
                  child: Text(
                    '${examination.title}$availabilityText',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: !isEnabled || isLoading || examinations.isEmpty
                  ? null
                  : (examId) {
                      onSelected(_findExamination(examId));
                    },
            ),

            if (!isLoading && isEnabled && examinations.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '등록된 검사가 없습니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            if (selectedExamination != null) ...[
              const SizedBox(height: 14),
              _ExaminationSummary(examination: selectedExamination!),
            ],
          ],
        ),
      ),
    );
  }

  DiagnosisExamination? _findExamination(int? examId) {
    if (examId == null) {
      return null;
    }

    for (final examination in examinations) {
      if (examination.examId == examId) {
        return examination;
      }
    }

    return null;
  }
}

final class _ExaminationSummary extends StatelessWidget {
  const _ExaminationSummary({required this.examination});

  final DiagnosisExamination examination;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            examination.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 6),

          Text('검사 ID ${examination.examId}'),

          if (examination.examDate != null) Text('검사일 ${examination.examDate}'),

          if (examination.vesselType != null)
            Text('혈관 ${examination.vesselType}'),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                examination.canRunIntegratedAnalysis
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 18,
                color: examination.canRunIntegratedAnalysis
                    ? colorScheme.primary
                    : colorScheme.error,
              ),

              const SizedBox(width: 6),

              Text(
                examination.canRunIntegratedAnalysis
                    ? 'AI 분석 가능'
                    : '키프레임이 없어 분석할 수 없습니다.',
                style: TextStyle(
                  color: examination.canRunIntegratedAnalysis
                      ? colorScheme.primary
                      : colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 병변탐지, 분류, 통합분석 결과 보기 방식 선택
final class _AnalysisTypeCard extends StatelessWidget {
  const _AnalysisTypeCard({
    required this.analysisType,
    required this.isSelected,
    required this.isEnabled,
    required this.onSelected,
  });

  final AiAnalysisType analysisType;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isEnabled ? onSelected : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconForType(analysisType),
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysisType.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      analysisType.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? colorScheme.primary : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(AiAnalysisType type) {
    switch (type) {
      case AiAnalysisType.detection:
        return Icons.crop_free;

      case AiAnalysisType.classification:
        return Icons.gradient;

      case AiAnalysisType.integrated:
        return Icons.layers_outlined;
    }
  }
}

// 진행 상태 표시
final class _AnalysisProgressCard extends StatelessWidget {
  const _AnalysisProgressCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      label: 'AI 분석 진행 중',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colorScheme.primaryContainer.withAlpha(90),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colorScheme.primary.withAlpha(45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '통합 AI 분석을 진행하고 있습니다',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'YOLOv11 병변 탐지와 InceptionV3 분류, '
                      'Grad-CAM 생성을 순차적으로 처리합니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 선택한 분석 유형에 따라 탐지, 분류 또는 통합 결과를 구분하여 표시한다.
final class _AnalysisCompletedCard extends StatelessWidget {
  const _AnalysisCompletedCard({required this.viewModel});

  final DiagnosisViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final result = viewModel.analysisResult;
    final analysisType = viewModel.selectedAnalysisType;

    if (result == null || analysisType == null) {
      return const SizedBox.shrink();
    }

    final confidencePercent = _toPercent(result.confidenceScore);

    final resultKeyFrame = result.keyFramePath;

    final selectedKeyFrame = viewModel.selectedExamination?.keyFrameUrl;

    final keyFrameSource =
        resultKeyFrame != null && resultKeyFrame.trim().isNotEmpty
        ? resultKeyFrame
        : selectedKeyFrame;

    final gradcamUrl = result.gradcamUrl;

    final gradcamSource = gradcamUrl != null && gradcamUrl.trim().isNotEmpty
        ? gradcamUrl
        : result.gradcamPath;

    late final Widget resultCard;

    switch (analysisType) {
      case AiAnalysisType.detection:
        resultCard = _ResultCard(
          icon: Icons.crop_free,
          title: 'YOLOv11 병변 탐지 결과',
          summary: _detectionSummary(result.boundingBoxData.detectionCount),
          rows: [
            _ResultRowData(
              label: '협착 의심 영역',
              value: '${result.boundingBoxData.detectionCount}개',
            ),
            _ResultRowData(
              label: 'BBox 결과',
              value: result.canShowBoundingBox ? '표시 가능' : '표시할 영역 없음',
            ),
          ],
          notice: '탐지 결과는 협착 의심 영역의 위치를 나타내며 정상·협착 분류 결과와는 별개의 모델 출력입니다.',
        );
        break;

      case AiAnalysisType.classification:
        resultCard = _ResultCard(
          icon: Icons.gradient,
          title: 'InceptionV3 정상·협착 분류 결과',
          summary: '영상 전체에 대한 분류 결과를 확인했습니다.',
          rows: [
            _ResultRowData(
              label: '분류 판정',
              value: _normalizedText(result.severityClass),
            ),
            _ResultRowData(
              label: '분류 신뢰도',
              value: '${confidencePercent.toStringAsFixed(1)}%',
            ),
            _ResultRowData(
              label: 'Grad-CAM',
              value: result.canShowHeatmap ? '표시 가능' : '결과 없음',
            ),
          ],
          notice: '분류 결과는 영상 전체의 정상·협착 가능성을 나타내며 병변 위치를 직접 표시하지 않습니다.',
        );
        break;

      case AiAnalysisType.integrated:
        resultCard = _ResultCard(
          icon: Icons.layers_outlined,
          title: '통합 AI 분석 결과',
          summary: '병변 위치 탐지와 정상·협착 분류 결과를 함께 확인했습니다.',
          rows: [
            _ResultRowData(
              label: '분류 판정',
              value: _normalizedText(result.severityClass),
            ),
            _ResultRowData(
              label: '분류 신뢰도',
              value: '${confidencePercent.toStringAsFixed(1)}%',
            ),
            _ResultRowData(
              label: '협착 의심 영역',
              value: '${result.boundingBoxData.detectionCount}개',
            ),
            _ResultRowData(
              label: 'BBox 결과',
              value: result.canShowBoundingBox ? '표시 가능' : '표시할 영역 없음',
            ),
            _ResultRowData(
              label: 'Grad-CAM',
              value: result.canShowHeatmap ? '표시 가능' : '결과 없음',
            ),
          ],
          notice: '탐지와 분류는 서로 다른 모델의 결과이므로 두 결과가 일치하지 않을 수도 있습니다.',
        );
        break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AiResultMediaViewer(
          keyFrameSource: keyFrameSource,
          gradcamSource: gradcamSource,
          headers: viewModel.mediaHeaders,
          resolveMediaUrl: viewModel.resolveMediaUrl,
          showHeatmap: analysisType.supportsHeatmap && viewModel.showHeatmap,
          canShowHeatmap: analysisType.supportsHeatmap && result.canShowHeatmap,
          boundingBoxData: result.boundingBoxData,
          showBoundingBox:
              analysisType.supportsBoundingBox && viewModel.showBoundingBox,
          canShowBoundingBox:
              analysisType.supportsBoundingBox && result.canShowBoundingBox,
          onOriginalSelected: viewModel.showOriginalMedia,
          onBoundingBoxChanged: viewModel.setBoundingBoxVisible,
          onHeatmapChanged: viewModel.setHeatmapVisible,
        ),

        const SizedBox(height: 12),
        resultCard,
      ],
    );
  }

  String _detectionSummary(int detectionCount) {
    if (detectionCount <= 0) {
      return '탐지된 협착 의심 영역이 없습니다.';
    }

    return '협착 의심 영역이 탐지되었습니다.';
  }

  String _normalizedText(String value) {
    final normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      return '확인되지 않음';
    }

    return normalizedValue;
  }

  double _toPercent(double value) {
    final percent = value <= 1 ? value * 100 : value;

    return percent.clamp(0, 100).toDouble();
  }
}

// 분석 유형별 결과 카드에 전달할 한 줄 지표를 표현
final class _ResultRowData {
  const _ResultRowData({required this.label, required this.value});

  final String label;
  final String value;
}

// 탐지, 분류와 통합 분석 결과에 공통으로 사용하는 카드
final class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.rows,
    required this.notice,
  });

  final IconData icon;
  final String title;
  final String summary;
  final List<_ResultRowData> rows;
  final String notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < rows.length; index++) ...[
                    _ResultValueRow(data: rows[index]),
                    if (index != rows.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 결과 카드 내부에 지표 이름과 값을 한 줄로 표시
final class _ResultValueRow extends StatelessWidget {
  const _ResultValueRow({required this.data});

  final _ResultRowData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            data.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            data.value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

final class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),

          IconButton(
            onPressed: onDismiss,
            tooltip: '닫기',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
