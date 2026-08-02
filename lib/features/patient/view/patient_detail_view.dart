import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/patient_detail.dart';
import '../view_model/patient_detail_view_model.dart';

final class PatientDetailView extends StatefulWidget {
  const PatientDetailView({
    super.key,
    required this.patientId,
  });

  final String patientId;

  @override
  State<PatientDetailView> createState() {
    return _PatientDetailViewState();
  }
}

final class _PatientDetailViewState
    extends State<PatientDetailView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context
          .read<PatientDetailViewModel>()
          .loadPatientDetail(
            widget.patientId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PatientDetailViewModel>(
      builder: (
        context,
        viewModel,
        child,
      ) {
        if (viewModel.isLoading &&
            viewModel.patientDetail == null) {
          return const Scaffold(
            appBar: _PatientDetailAppBar(),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (viewModel.errorMessage != null &&
            viewModel.patientDetail == null) {
          return Scaffold(
            appBar: const _PatientDetailAppBar(),
            body: _PatientDetailErrorView(
              message: viewModel.errorMessage!,
              onRetry: () {
                viewModel.loadPatientDetail(
                  widget.patientId,
                );
              },
            ),
          );
        }

        final detail = viewModel.patientDetail;

        if (detail == null) {
          return const Scaffold(
            appBar: _PatientDetailAppBar(),
            body: Center(
              child: Text(
                '환자 정보가 없습니다.',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: const _PatientDetailAppBar(),
          body: RefreshIndicator(
            onRefresh: () {
              return viewModel.refreshPatientDetail(
                widget.patientId,
              );
            },
            child: _PatientDetailBody(
              detail: detail,
              mediaHeaders: viewModel.mediaHeaders,
              resolveMediaUrl:
                  viewModel.resolveMediaUrl,
            ),
          ),
        );
      },
    );
  }
}

final class _PatientDetailAppBar
    extends StatelessWidget
    implements PreferredSizeWidget {
  const _PatientDetailAppBar();

  @override
  Size get preferredSize {
    return const Size.fromHeight(
      kToolbarHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        '환자 상세 정보',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

final class _PatientDetailBody
    extends StatelessWidget {
  const _PatientDetailBody({
    required this.detail,
    required this.mediaHeaders,
    required this.resolveMediaUrl,
  });

  final PatientDetail detail;
  final Map<String, String> mediaHeaders;
  final String Function(String?) resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    final patient = detail.patient;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        32,
      ),
      children: [
        _PatientProfileCard(
          patientName: patient.patientName,
          patientId: patient.patientId,
          gender: patient.genderText,
          age: patient.age,
          primaryDoctorId:
              patient.primaryDoctorId,
          chiefComplaint:
              patient.chiefComplaint,
          ecgResult: patient.ecgResult,
          troponinTText:
              patient.troponinTText,
          historyScoreText:
              patient.historyScoreText,
          riskFactorsCountText:
              patient.riskFactorsCountText,
        ),

        const SizedBox(height: 24),

        const _SectionHeader(
          title: 'ECG 검사',
          icon: Icons.monitor_heart_outlined,
        ),

        const SizedBox(height: 12),

        _EcgImageExpansionCard(
          ecgResult: patient.ecgResult,
          ecgImageUrl: patient.ecgImageUrl,
          mediaHeaders: mediaHeaders,
          resolveMediaUrl: resolveMediaUrl,
        ),

        const SizedBox(height: 24),

        _SectionHeader(
          title: '촬영 이미지',
          icon: Icons.image_outlined,
          count: detail.examinations.length,
        ),

        const SizedBox(height: 12),

        if (detail.examinations.isEmpty)
          const _EmptySectionCard(
            icon:
                Icons.image_not_supported_outlined,
            message:
                '등록된 촬영 이미지가 없습니다.',
          )
        else
          ...detail.examinations.map(
            (examination) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 12,
                ),
                child: _ExaminationExpansionCard(
                  examination: examination,
                  mediaHeaders: mediaHeaders,
                  resolveMediaUrl:
                      resolveMediaUrl,
                ),
              );
            },
          ),
      ],
    );
  }
}

final class _PatientProfileCard
    extends StatelessWidget {
  const _PatientProfileCard({
    required this.patientName,
    required this.patientId,
    required this.gender,
    required this.age,
    required this.primaryDoctorId,
    required this.chiefComplaint,
    required this.ecgResult,
    required this.troponinTText,
    required this.historyScoreText,
    required this.riskFactorsCountText,
  });

  final String patientName;
  final String patientId;
  final String gender;
  final int age;
  final String? primaryDoctorId;
  final String? chiefComplaint;
  final String? ecgResult;
  final String troponinTText;
  final String historyScoreText;
  final String riskFactorsCountText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayName =
        patientName.trim().isEmpty
            ? '이름 미등록'
            : patientName.trim();

    final firstLetter =
        displayName == '이름 미등록'
            ? '?'
            : displayName.substring(0, 1);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor:
                      colorScheme.primaryContainer,
                  foregroundColor:
                      colorScheme.onPrimaryContainer,
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '$gender · $age세',
                        style: theme
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '환자 ID  $patientId',
                        style: theme
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
            ),

            const SizedBox(height: 20),

            const Divider(height: 1),

            const SizedBox(height: 16),

            _ProfileInformationRow(
              title: '담당 의료진',
              value: _nullableText(
                primaryDoctorId,
              ),
            ),

            _ProfileInformationRow(
              title: '주호소',
              value: _nullableText(
                chiefComplaint,
              ),
            ),

            _ProfileInformationRow(
              title: 'ECG 결과',
              value: _nullableText(
                ecgResult,
              ),
            ),

            _ProfileInformationRow(
              title: 'Troponin T',
              value: troponinTText,
            ),

            _ProfileInformationRow(
              title: '병력 점수',
              value: historyScoreText,
            ),

            _ProfileInformationRow(
              title: '위험요인',
              value: riskFactorsCountText,
              showBottomPadding: false,
            ),
          ],
        ),
      ),
    );
  }
}

final class _ProfileInformationRow
    extends StatelessWidget {
  const _ProfileInformationRow({
    required this.title,
    required this.value,
    this.showBottomPadding = true,
  });

  final String title;
  final String value;
  final bool showBottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: showBottomPadding ? 12 : 0,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

final class _SectionHeader
    extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.count,
  });

  final String title;
  final IconData icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 21,
          color: colorScheme.primary,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color:
                  colorScheme.primaryContainer,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              '$count건',
              style: TextStyle(
                color: colorScheme
                    .onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

final class _EcgImageExpansionCard
    extends StatelessWidget {
  const _EcgImageExpansionCard({
    required this.ecgResult,
    required this.ecgImageUrl,
    required this.mediaHeaders,
    required this.resolveMediaUrl,
  });

  final String? ecgResult;
  final String ecgImageUrl;
  final Map<String, String> mediaHeaders;
  final String Function(String?) resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        ecgImageUrl.trim().isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const CircleAvatar(
          child: Icon(
            Icons.monitor_heart_outlined,
          ),
        ),
        title: const Text(
          'ECG 이미지',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _nullableText(ecgResult),
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          18,
        ),
        children: [
          const Divider(height: 1),

          const SizedBox(height: 16),

          if (!hasImage)
            const _NoImageView(
              message:
                  '등록된 ECG 이미지가 없습니다.',
            )
          else
            _NetworkImageViewer(
              imageUrl: resolveMediaUrl(
                ecgImageUrl,
              ),
              headers: mediaHeaders,
            ),
        ],
      ),
    );
  }
}

final class _ExaminationExpansionCard
    extends StatelessWidget {
  const _ExaminationExpansionCard({
    required this.examination,
    required this.mediaHeaders,
    required this.resolveMediaUrl,
  });

  final Map<String, dynamic> examination;
  final Map<String, String> mediaHeaders;
  final String Function(String?) resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    final examId = _displayValue(
      examination['exam_id'] ??
          examination['id'],
    );

    final title = _findExaminationTitle(
      examination,
    );

    final imageUrl = _findImageUrl(
      examination,
      const [
        'key_frame_url',
        'image_url',
        'frame_url',
        'thumbnail_url',
      ],
    );

    final examinationInformation =
        examination.entries.where(
      (entry) {
        return !_isHiddenExaminationField(
          entry.key.toLowerCase(),
        );
      },
    ).toList();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const CircleAvatar(
          child: Icon(
            Icons.image_outlined,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: examId == '-'
            ? const Text(
                '이미지 상세보기',
              )
            : Text(
                '검사 번호 $examId',
              ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          18,
        ),
        children: [
          const Divider(height: 1),

          if (examinationInformation
              .isNotEmpty) ...[
            const SizedBox(height: 16),

            ...examinationInformation.map(
              (entry) {
                return _InformationRow(
                  title: _fieldLabel(
                    entry.key,
                  ),
                  value: _displayValue(
                    entry.value,
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 12),

          if (imageUrl == null)
            const _NoImageView(
              message:
                  '등록된 Key Frame 이미지가 없습니다.',
            )
          else
            _NetworkImageViewer(
              imageUrl: resolveMediaUrl(
                imageUrl,
              ),
              headers: mediaHeaders,
            ),
        ],
      ),
    );
  }
}

final class _AiResultExpansionCard
    extends StatelessWidget {
  const _AiResultExpansionCard({
    required this.aiResult,
    required this.mediaHeaders,
    required this.resolveMediaUrl,
  });

  final Map<String, dynamic> aiResult;
  final Map<String, String> mediaHeaders;
  final String Function(String?) resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    final examId = _displayValue(
      aiResult['exam_id'],
    );

    final hasLesion = _toBoolean(
      aiResult['has_lesion'],
    );

    final severity = _displayValue(
      aiResult['severity_class'],
    );

    final confidence =
        _formatPercentageFromDecimal(
      aiResult['confidence_score'],
    );

    final gradcamUrl = _findImageUrl(
      aiResult,
      const [
        'gradcam_url',
        'xai_url',
        'heatmap_url',
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(
            hasLesion
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
          ),
        ),
        title: const Text(
          'AI 분석 결과',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          examId == '-'
              ? '결과 상세보기'
              : '검사 번호 $examId',
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          18,
        ),
        children: [
          const Divider(height: 1),

          const SizedBox(height: 16),

          _AiSummaryCard(
            hasLesion: hasLesion,
            severity: severity,
            confidence: confidence,
          ),

          const SizedBox(height: 16),

          _InformationRow(
            title: '심장 점수',
            value: _displayValue(
              aiResult['heart_score'],
            ),
          ),

          _InformationRow(
            title: 'MACE 위험도',
            value: _formatPercentage(
              aiResult[
                  'mace_risk_percent'],
            ),
          ),

          _InformationRow(
            title: '담당 의료진',
            value: _displayValue(
              aiResult[
                  'confirming_doctor_id'],
            ),
          ),

          _InformationRow(
            title: '확정 여부',
            value: _confirmationLabel(
              aiResult['is_confirmed'],
            ),
          ),

          if (_hasValue(
            aiResult['doctor_opinion'],
          )) ...[
            const SizedBox(height: 6),

            _OpinionCard(
              opinion: aiResult[
                      'doctor_opinion']
                  .toString(),
            ),
          ],

          const SizedBox(height: 18),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Grad-CAM 분석 이미지',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          if (gradcamUrl == null)
            const _NoImageView(
              message:
                  '등록된 Grad-CAM 이미지가 없습니다.',
            )
          else
            _NetworkImageViewer(
              imageUrl: resolveMediaUrl(
                gradcamUrl,
              ),
              headers: mediaHeaders,
            ),
        ],
      ),
    );
  }
}

final class _AiSummaryCard
    extends StatelessWidget {
  const _AiSummaryCard({
    required this.hasLesion,
    required this.severity,
    required this.confidence,
  });

  final bool hasLesion;
  final String severity;
  final String confidence;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasLesion
            ? colorScheme.errorContainer
                .withOpacity(0.45)
            : colorScheme.primaryContainer
                .withOpacity(0.45),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                hasLesion
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  hasLesion
                      ? '병변이 감지되었습니다.'
                      : '감지된 병변이 없습니다.',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SummaryValueRow(
            title: '협착 등급',
            value: severity,
          ),

          const SizedBox(height: 9),

          _SummaryValueRow(
            title: 'AI 신뢰도',
            value: confidence,
          ),
        ],
      ),
    );
  }
}

final class _SummaryValueRow
    extends StatelessWidget {
  const _SummaryValueRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title),
        ),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

final class _OpinionCard
    extends StatelessWidget {
  const _OpinionCard({
    required this.opinion,
  });

  final String opinion;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          const Row(
            children: [
              Icon(
                Icons
                    .medical_information_outlined,
                size: 20,
              ),

              SizedBox(width: 8),

              Text(
                '의료진 소견',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(opinion),
        ],
      ),
    );
  }
}

final class _InformationRow
    extends StatelessWidget {
  const _InformationRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

final class _NetworkImageViewer
    extends StatelessWidget {
  const _NetworkImageViewer({
    required this.imageUrl,
    required this.headers,
  });

  final String imageUrl;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 220,
          maxHeight: 480,
        ),
        color: Colors.black,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          httpHeaders: headers,
          fit: BoxFit.contain,
          fadeInDuration:
              const Duration(milliseconds: 200),
          placeholder: (
            context,
            url,
          ) {
            return const SizedBox(
              height: 260,
              child: Center(
                child:
                    CircularProgressIndicator(),
              ),
            );
          },
          errorWidget: (
            context,
            url,
            error,
          ) {
            debugPrint(
              '이미지 요청 URL: $url',
            );

            debugPrint(
              '이미지 로드 오류: $error',
            );

            return const SizedBox(
              height: 240,
              child: Center(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .broken_image_outlined,
                      size: 52,
                      color: Colors.white70,
                    ),

                    SizedBox(height: 12),

                    Text(
                      '이미지를 불러올 수 없습니다.',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _NoImageView
    extends StatelessWidget {
  const _NoImageView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 38,
      ),
      decoration: BoxDecoration(
        color:
            colorScheme.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 44,
            color:
                colorScheme.onSurfaceVariant,
          ),

          const SizedBox(height: 10),

          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

final class _EmptySectionCard
    extends StatelessWidget {
  const _EmptySectionCard({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 32,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color:
                  colorScheme.onSurfaceVariant,
            ),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

final class _PatientDetailErrorView
    extends StatelessWidget {
  const _PatientDetailErrorView({
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
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
            ),

            const SizedBox(height: 16),

            Text(
              message,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                '다시 시도',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _findExaminationTitle(
  Map<String, dynamic> examination,
) {
  final title =
      examination['title'] ??
      examination['exam_name'] ??
      examination['examination_name'] ??
      examination['view_name'] ??
      examination['artery_name'] ??
      examination['vessel_name'];

  if (_hasValue(title)) {
    return title.toString().trim();
  }

  return 'Key Frame 이미지';
}

String? _findImageUrl(
  Map<String, dynamic> data,
  List<String> candidateKeys,
) {
  for (final key in candidateKeys) {
    final value = data[key];

    if (_hasValue(value)) {
      return value.toString().trim();
    }
  }

  return null;
}

bool _isHiddenExaminationField(
  String fieldName,
) {
  return fieldName.endsWith('_path') ||
      fieldName.endsWith('_url') ||
      fieldName.contains('video') ||
      fieldName == 'id' ||
      fieldName == 'exam_id';
}

String _fieldLabel(
  String fieldName,
) {
  const labels = <String, String>{
    'exam_date': '검사일',
    'exam_type': '검사 종류',
    'exam_name': '검사명',
    'artery_name': '혈관',
    'vessel_name': '혈관',
    'view_name': '촬영 방향',
    'ecg_result': 'ECG 결과',
    'troponin_t_level': 'Troponin T',
    'chief_complaint': '주호소',
    'created_at': '등록일',
    'updated_at': '수정일',
  };

  return labels[fieldName] ??
      fieldName.replaceAll('_', ' ');
}

String _nullableText(
  String? value,
) {
  if (value == null ||
      value.trim().isEmpty) {
    return '미등록';
  }

  return value.trim();
}

String _displayValue(
  dynamic value,
) {
  if (value == null) {
    return '-';
  }

  if (value is bool) {
    return value ? '예' : '아니오';
  }

  if (value is List) {
    if (value.isEmpty) {
      return '-';
    }

    return value.join(', ');
  }

  if (value is Map) {
    if (value.isEmpty) {
      return '-';
    }

    return value.entries
        .map(
          (entry) =>
              '${entry.key}: ${entry.value}',
        )
        .join(', ');
  }

  final result =
      value.toString().trim();

  return result.isEmpty ? '-' : result;
}

bool _hasValue(
  dynamic value,
) {
  if (value == null) {
    return false;
  }

  final text =
      value.toString().trim();

  return text.isNotEmpty &&
      text.toLowerCase() != 'null';
}

bool _toBoolean(
  dynamic value,
) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized =
      value?.toString().trim().toLowerCase();

  return normalized == 'true' ||
      normalized == '1' ||
      normalized == 'yes' ||
      normalized == 'y';
}

String _confirmationLabel(
  dynamic value,
) {
  if (value == null) {
    return '-';
  }

  return _toBoolean(value)
      ? '확정'
      : '미확정';
}

String _formatPercentageFromDecimal(
  dynamic value,
) {
  final number = _toDouble(value);

  if (number == null) {
    return '-';
  }

  final percentage =
      number >= 0 && number <= 1
          ? number * 100
          : number;

  return '${percentage.toStringAsFixed(1)}%';
}

String _formatPercentage(
  dynamic value,
) {
  final number = _toDouble(value);

  if (number == null) {
    return '-';
  }

  return '${number.toStringAsFixed(1)}%';
}

double? _toDouble(
  dynamic value,
) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value?.toString() ?? '',
  );
}

bool _isCompletedAiResult(
  Map<String, dynamic> aiResult,
) {
  final status = (
    aiResult['analysis_status'] ??
    aiResult['status'] ??
    aiResult['ai_status'] ??
    ''
  )
      .toString()
      .trim()
      .toUpperCase();

  if (status.isNotEmpty) {
    return status == 'COMPLETED' ||
        status == 'COMPLETE' ||
        status == 'SUCCESS' ||
        status == 'SUCCEEDED' ||
        status == 'DONE';
  }

  final hasLesion =
      aiResult['has_lesion'];

  final severity =
      aiResult['severity_class'];

  final confidence =
      aiResult['confidence_score'];

  final gradcamUrl =
      aiResult['gradcam_url'];

  return hasLesion != null ||
      _hasValue(severity) ||
      confidence != null ||
      _hasValue(gradcamUrl);
}