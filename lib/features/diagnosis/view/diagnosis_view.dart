// ai 분석 요청 화면 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../patient/model/patient.dart';
import '../../patient/view_model/patient_list_view_model.dart';
import '../model/ai_analysis_type.dart';
import '../model/diagnosis_examination.dart';
import '../view_model/diagnosis_view_model.dart';

final class DiagnosisView extends StatefulWidget {
  const DiagnosisView({
    super.key,
  });

  @override
  State<DiagnosisView> createState() {
    return _DiagnosisViewState();
  }
}

final class _DiagnosisViewState
    extends State<DiagnosisView> {
  @override
  void initState() {  // 홈에서 진입하면 환자 미선택 상태, 환자상세에서 진입하면 patientId로 환자 상세 및 검사목록 불러옴
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        context
            .read<DiagnosisViewModel>()
            .initialize();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final diagnosisViewModel =
        context.watch<DiagnosisViewModel>();

    final patientListViewModel =
        context.watch<PatientListViewModel>();

    final patients = _mergePatients(// 환자 상세환자에서 진입한 환자가 전역 환자 목록에 없을 경우를 대비해 병합
      patientListViewModel.patients,
      diagnosisViewModel.selectedPatient,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI 분석 요청',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            32,
          ),
          children: [
            const _ScreenHeader(),

            const SizedBox(height: 24),

            _SectionHeader(
              step: 1,
              title: '환자 선택',
              description:
                  'AI 분석을 실행할 환자를 선택합니다.',
            ),

            const SizedBox(height: 12),

            _PatientSelectionCard(//환자 선택되면 상세 api호출 - 검사 목록 불러옴
              patients: patients,
              selectedPatient:
                  diagnosisViewModel
                      .selectedPatient,
              isLoadingPatients:
                  patientListViewModel
                      .isLoading,
              isLoadingExaminations:
                  diagnosisViewModel
                      .isLoadingExaminations,
              isEnabled:
                  !diagnosisViewModel.isBusy,
              patientListError:
                  patientListViewModel
                      .errorMessage,
              onRefreshPatients:
                  patientListViewModel
                      .loadPatients,
              onSelected: (
                patient,
              ) async {
                await diagnosisViewModel
                    .selectPatient(patient);
              },
            ),

            const SizedBox(height: 24),

            _SectionHeader(// 키프레임 등록된 검사 선택
              step: 2,
              title: '검사 선택',
              description:
                  '키프레임이 등록된 관상동맥 검사를 선택합니다.',
            ),

            const SizedBox(height: 12),

            _ExaminationSelectionCard(// 선택된 환자의 검사 목록과 ai 분석 가능 여부 표시
              examinations:
                  diagnosisViewModel
                      .examinations,
              selectedExamination:
                  diagnosisViewModel
                      .selectedExamination,
              isLoading:
                  diagnosisViewModel
                      .isLoadingExaminations,
              isEnabled:
                  diagnosisViewModel
                          .hasSelectedPatient &&
                      !diagnosisViewModel
                          .isBusy,
              onSelected:
                  diagnosisViewModel
                      .selectExamination,
            ),

            const SizedBox(height: 24),

            _SectionHeader(// 통합 분석 결과의 기본 표시 방식 선택
              step: 3,
              title: '결과 보기 방식',
              description:
                  '통합 분석 결과에서 확인할 표시 방식을 선택합니다.',
            ),

            const SizedBox(height: 12),

            ...AiAnalysisType.values.map(
              (analysisType) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _AnalysisTypeCard(
                    analysisType:
                        analysisType,
                    isSelected:
                        diagnosisViewModel
                                .selectedAnalysisType ==
                            analysisType,
                    isEnabled:
                        !diagnosisViewModel
                            .isBusy,
                    onSelected: () {
                      diagnosisViewModel
                          .selectAnalysisType(
                        analysisType,
                      );
                    },
                  ),
                );
              },
            ),

            if (diagnosisViewModel//환자 조회 또는 ai분석 요청 중 발생한 오류 표시
                    .errorMessage !=
                null) ...[
              const SizedBox(height: 8),
              _ErrorCard(
                message:
                    diagnosisViewModel
                        .errorMessage!,
                onDismiss:
                    diagnosisViewModel
                        .clearError,
              ),
            ],

            const SizedBox(height: 12),

            if (diagnosisViewModel.isBusy)// 환자 조회 또는 ai분석 요청 중 표시
              const _AnalysisProgressCard(),

            if (diagnosisViewModel
                .hasCompletedAnalysis) ...[
              const SizedBox(height: 12),
              _AnalysisCompletedCard(
                viewModel:
                    diagnosisViewModel,
              ),
            ],

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed:
                  diagnosisViewModel
                          .canRunAnalysis
                      ? () async {
                          await diagnosisViewModel
                              .runAnalysis();
                        }
                      : null,
              icon: diagnosisViewModel.isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome,
                    ),
              label: Text(
                diagnosisViewModel.isBusy
                    ? 'AI 분석 중'
                    : 'AI 분석 시작',
              ),
              style: FilledButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(54),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'AI 분석 결과는 의료진의 임상적 판단을 보조하며 최종 진단을 대신하지 않습니다.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
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
    final patientMap =
        <String, Patient>{};

    for (final patient in patients) {
      final patientId =
          patient.patientId.trim();

      if (patientId.isNotEmpty) {
        patientMap[patientId] = patient;
      }
    }

    if (selectedPatient != null) {
      final selectedPatientId =
          selectedPatient.patientId.trim();

      if (selectedPatientId.isNotEmpty) {
        patientMap.putIfAbsent(
          selectedPatientId,
          () => selectedPatient,
        );
      }
    }

    return patientMap.values.toList(
      growable: false,
    );
  }
}
// 화면 상단에 ai분석 목적과 안내 문구 표시
final class _ScreenHeader
    extends StatelessWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.monitor_heart_outlined,
              color: colorScheme.onPrimary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '관상동맥 AI 분석',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),

                const SizedBox(height: 6),

                Text(
                  '환자와 검사를 선택한 뒤 병변 위치, 정상·협착 분류 또는 통합 결과를 확인합니다.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: colorScheme
                            .onPrimaryContainer,
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
final class _SectionHeader
    extends StatelessWidget {
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
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor:
              colorScheme.primary,
          foregroundColor:
              colorScheme.onPrimary,
          child: Text(
            '$step',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
              ),

              const SizedBox(height: 3),

              Text(
                description,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: colorScheme
                          .onSurfaceVariant,
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
final class _PatientSelectionCard
    extends StatelessWidget {
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
  final Future<void> Function()
      onRefreshPatients;
  final Future<void> Function(Patient)
      onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedPatientId =
        selectedPatient?.patientId.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (isLoadingPatients)
              const LinearProgressIndicator(),

            if (isLoadingPatients)
              const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              key: ValueKey(
                selectedPatientId,
              ),
              initialValue:
                  selectedPatientId,
              isExpanded: true,
              decoration:
                  const InputDecoration(
                labelText: '환자',
                prefixIcon:
                    Icon(Icons.person_search),
                border:
                    OutlineInputBorder(),
              ),
              hint: const Text(
                '환자를 선택해 주세요.',
              ),
              items: patients.map(
                (patient) {
                  final displayName =
                      patient.patientName
                              .trim()
                              .isEmpty
                          ? '이름 미등록'
                          : patient
                              .patientName
                              .trim();

                  return DropdownMenuItem<
                      String>(
                    value:
                        patient.patientId,
                    child: Text(
                      '$displayName · ${patient.patientId}',
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  );
                },
              ).toList(),
              onChanged:
                  !isEnabled ||
                          isLoadingPatients ||
                          isLoadingExaminations
                      ? null
                      : (patientId) async {
                          final patient =
                              _findPatient(
                            patientId,
                          );

                          if (patient !=
                              null) {
                            await onSelected(
                              patient,
                            );
                          }
                        },
            ),

            if (patientListError !=
                    null &&
                patients.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                patientListError!,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .error,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    onRefreshPatients,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  '환자 목록 다시 불러오기',
                ),
              ),
            ],

            if (isLoadingExaminations) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '환자 검사 정보를 불러오는 중입니다.',
                  ),
                ],
              ),
            ],

            if (selectedPatient !=
                    null &&
                !isLoadingExaminations) ...[
              const SizedBox(height: 16),
              _SelectedPatientSummary(
                patient: selectedPatient!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Patient? _findPatient(
    String? patientId,
  ) {
    if (patientId == null) {
      return null;
    }

    for (final patient in patients) {
      if (patient.patientId ==
          patientId) {
        return patient;
      }
    }

    return null;
  }
}
// 선택된 환자의 이름, id, 성별과 나이 요약
final class _SelectedPatientSummary
    extends StatelessWidget {
  const _SelectedPatientSummary({
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final displayName =
        patient.patientName.trim().isEmpty
            ? '이름 미등록'
            : patient.patientName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                colorScheme.primaryContainer,
            foregroundColor:
                colorScheme.onPrimaryContainer,
            child: Text(
              displayName == '이름 미등록'
                  ? '?'
                  : displayName.substring(
                      0,
                      1,
                    ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '환자 ID ${patient.patientId} · ${patient.genderText} · ${patient.age}세',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
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
final class _ExaminationSelectionCard
    extends StatelessWidget {
  const _ExaminationSelectionCard({
    required this.examinations,
    required this.selectedExamination,
    required this.isLoading,
    required this.isEnabled,
    required this.onSelected,
  });

  final List<DiagnosisExamination>
      examinations;

  final DiagnosisExamination?
      selectedExamination;

  final bool isLoading;
  final bool isEnabled;

  final void Function(
    DiagnosisExamination?,
  ) onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedExamId =
        selectedExamination?.examId;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey(
                selectedExamId,
              ),
              initialValue:
                  selectedExamId,
              isExpanded: true,
              decoration:
                  const InputDecoration(
                labelText: '검사',
                prefixIcon: Icon(
                  Icons.image_search,
                ),
                border:
                    OutlineInputBorder(),
              ),
              hint: Text(
                isLoading
                    ? '검사 정보를 불러오는 중입니다.'
                    : '검사를 선택해 주세요.',
              ),
              items: examinations.map(
                (examination) {
                  final availabilityText =
                      examination
                              .canRunIntegratedAnalysis
                          ? ''
                          : ' · 키프레임 없음';

                  return DropdownMenuItem<int>(
                    value:
                        examination.examId,
                    child: Text(
                      '${examination.title}$availabilityText',
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  );
                },
              ).toList(),
              onChanged:
                  !isEnabled ||
                          isLoading ||
                          examinations.isEmpty
                      ? null
                      : (examId) {
                          onSelected(
                            _findExamination(
                              examId,
                            ),
                          );
                        },
            ),

            if (!isLoading &&
                isEnabled &&
                examinations.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '등록된 검사가 없습니다.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
            ],

            if (selectedExamination !=
                null) ...[
              const SizedBox(height: 14),
              _ExaminationSummary(
                examination:
                    selectedExamination!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  DiagnosisExamination?
      _findExamination(
    int? examId,
  ) {
    if (examId == null) {
      return null;
    }

    for (final examination
        in examinations) {
      if (examination.examId ==
          examId) {
        return examination;
      }
    }

    return null;
  }
}

final class _ExaminationSummary
    extends StatelessWidget {
  const _ExaminationSummary({
    required this.examination,
  });

  final DiagnosisExamination examination;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            examination.title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),

          const SizedBox(height: 6),

          Text(
            '검사 ID ${examination.examId}',
          ),

          if (examination.examDate !=
              null)
            Text(
              '검사일 ${examination.examDate}',
            ),

          if (examination.vesselType !=
              null)
            Text(
              '혈관 ${examination.vesselType}',
            ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                examination
                        .canRunIntegratedAnalysis
                    ? Icons
                        .check_circle_outline
                    : Icons
                        .error_outline,
                size: 18,
                color: examination
                        .canRunIntegratedAnalysis
                    ? colorScheme.primary
                    : colorScheme.error,
              ),

              const SizedBox(width: 6),

              Text(
                examination
                        .canRunIntegratedAnalysis
                    ? 'AI 분석 가능'
                    : '키프레임이 없어 분석할 수 없습니다.',
                style: TextStyle(
                  color: examination
                          .canRunIntegratedAnalysis
                      ? colorScheme.primary
                      : colorScheme.error,
                  fontWeight:
                      FontWeight.w600,
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
final class _AnalysisTypeCard
    extends StatelessWidget {
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
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surface,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: isEnabled
            ? onSelected
            : null,
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                _iconForType(
                  analysisType,
                ),
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme
                        .onSurfaceVariant,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysisType.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                          ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      analysisType
                          .description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Icon(
                isSelected
                    ? Icons
                        .check_circle
                    : Icons
                        .radio_button_unchecked,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(
    AiAnalysisType type,
  ) {
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
// 진행상태 표시
final class _AnalysisProgressCard
    extends StatelessWidget {
  const _AnalysisProgressCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'YOLOv11, InceptionV3와 Grad-CAM 통합 분석을 진행하고 있습니다.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// 신뢰도, 탐지 영역 수, BBox/Heatmap 사용 가능 여부 등 분석 결과 요약 표시
final class _AnalysisCompletedCard
    extends StatelessWidget {
  const _AnalysisCompletedCard({
    required this.viewModel,
  });

  final DiagnosisViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final result =
        viewModel.analysisResult;

    if (result == null) {
      return const SizedBox.shrink();
    }

    final confidence =
        result.confidenceScore <= 1
            ? result.confidenceScore *
                100
            : result.confidenceScore;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons
                      .check_circle_outline,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI 분석 완료',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              '결과 보기: ${viewModel.selectedAnalysisType?.title ?? '-'}',
            ),

            Text(
              '분류 결과: ${result.severityClass}',
            ),

            Text(
              '분류 신뢰도: ${confidence.toStringAsFixed(1)}%',
            ),

            Text(
              '탐지 영역: ${result.boundingBoxData.detectionCount}개',
            ),

            const SizedBox(height: 8),

            Text(
              'BBox ${result.canShowBoundingBox ? '사용 가능' : '결과 없음'} · Heatmap ${result.canShowHeatmap ? '사용 가능' : '결과 없음'}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

final class _ErrorCard
    extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color:
                colorScheme.onErrorContainer,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme
                    .onErrorContainer,
              ),
            ),
          ),

          IconButton(
            onPressed: onDismiss,
            tooltip: '닫기',
            icon: const Icon(
              Icons.close,
            ),
          ),
        ],
      ),
    );
  }
}