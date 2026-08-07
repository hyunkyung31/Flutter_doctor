import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../model/patient_detail.dart';
import '../view_model/patient_detail_view_model.dart';
import 'package:go_router/go_router.dart';
import '../../diagnosis/diagnosis_routes.dart'; // 추가
import '../../diagnosis/model/diagnosis_entry_args.dart'; // 추가
import '../../../core/security/screen_protection/screen_protection_notice.dart';
import '../widgets/patient_profile_avatar.dart';

final class PatientDetailView extends StatefulWidget {
  const PatientDetailView({super.key, required this.patientId});

  final String patientId;

  @override
  State<PatientDetailView> createState() {
    return _PatientDetailViewState();
  }
}

final class _PatientDetailViewState extends State<PatientDetailView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<PatientDetailViewModel>().loadPatientDetail(
        widget.patientId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PatientDetailViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.patientDetail == null) {
          return const Scaffold(
            appBar: _PatientDetailAppBar(),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (viewModel.errorMessage != null && viewModel.patientDetail == null) {
          return Scaffold(
            appBar: const _PatientDetailAppBar(),
            body: _PatientDetailErrorView(
              message: viewModel.errorMessage!,
              onRetry: () {
                viewModel.loadPatientDetail(widget.patientId);
              },
            ),
          );
        }

        final detail = viewModel.patientDetail;

        if (detail == null) {
          return const Scaffold(
            appBar: _PatientDetailAppBar(),
            body: Center(child: Text('환자 정보가 없습니다.')),
          );
        }

        return Scaffold(
          appBar: const _PatientDetailAppBar(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.pushNamed(
                'memoList',
                pathParameters: {'patientId': detail.patient.patientId},
                extra: detail.patient,
              );
            },
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('메모'),
          ),
          body: RefreshIndicator(
            onRefresh: () {
              return viewModel.refreshPatientDetail(widget.patientId);
            },
            child: _PatientDetailBody(
              detail: detail,
              mediaHeaders: viewModel.mediaHeaders,
              resolveMediaUrl: viewModel.resolveMediaUrl,
            ),
          ),
        );
      },
    );
  }
}

final class _PatientDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _PatientDetailAppBar();

  @override
  Size get preferredSize {
    return const Size.fromHeight(kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        '환자 상세 정보',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

final class _PatientDetailBody extends StatelessWidget {
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const ScreenProtectionNotice(),
        if (kReleaseMode) const SizedBox(height: 12),
        _PatientProfileCard(
          patientName: patient.patientName,
          patientId: patient.patientId,
          gender: patient.genderText,
          age: patient.age,
          primaryDoctorId: patient.primaryDoctorId,
          chiefComplaint: patient.chiefComplaint,
          ecgResult: patient.ecgResult,
          troponinTText: patient.troponinTText,
          historyScoreText: patient.historyScoreText,
          riskFactorsCountText: patient.riskFactorsCountText,
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
            icon: Icons.image_not_supported_outlined,
            message: '등록된 촬영 이미지가 없습니다.',
          )
        else
          ...detail.examinations.asMap().entries.map((entry) {
            final index = entry.key;
            final examination = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExaminationExpansionCard(
                examination: examination,
                examinationIndex: index,
                mediaHeaders: mediaHeaders,
                resolveMediaUrl: resolveMediaUrl,
              ),
            );
          }),
        const SizedBox(height: 20),

        _AiAnalysisRequestButton(patientId: patient.patientId),

        const SizedBox(height: 8),
      ],
    );
  }
}

final class _AiAnalysisRequestButton extends StatelessWidget {
  const _AiAnalysisRequestButton({required this.patientId});

  final String patientId;
  // 추가 : AI 분석 화면 연결
  void _openDiagnosisView(BuildContext context) {
    final normalizedPatientId = patientId.trim();

    if (normalizedPatientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('환자 ID가 없어 AI 분석을 요청할 수 없습니다.')),
      );

      return;
    }

    context.pushNamed(
      DiagnosisRoute.name,
      extra: DiagnosisEntryArgs(patientId: normalizedPatientId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: () {
          _openDiagnosisView(context); // 추가 - ai 버튼
        },
        icon: const Icon(Icons.analytics_outlined),
        label: const Text(
          'AI 예측분석 요청',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

final class _PatientProfileCard extends StatelessWidget {
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

    final displayName = patientName.trim().isEmpty
        ? '이름 미등록'
        : patientName.trim();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const PatientProfileAvatar(radius: 34),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '$gender · $age세',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '환자 ID  $patientId',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
              value: _nullableText(primaryDoctorId),
            ),

            _ProfileInformationRow(
              title: '주호소',
              value: _nullableText(chiefComplaint),
            ),

            _ProfileInformationRow(
              title: 'ECG 결과',
              value: _nullableText(ecgResult),
            ),

            _ProfileInformationRow(title: 'Troponin T', value: troponinTText),

            _ProfileInformationRow(title: '병력 점수', value: historyScoreText),

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

final class _ProfileInformationRow extends StatelessWidget {
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
      padding: EdgeInsets.only(bottom: showBottomPadding ? 12 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon, this.count});

  final String title;
  final IconData icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 21, color: colorScheme.primary),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count건',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

final class _EcgImageExpansionCard extends StatelessWidget {
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
    final hasImage = ecgImageUrl.trim().isNotEmpty;

    final resolvedImageUrl = hasImage ? resolveMediaUrl(ecgImageUrl) : '';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.monitor_heart_outlined)),
        title: const Text(
          'ECG 이미지',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_nullableText(ecgResult)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        children: [
          const Divider(height: 1),

          const SizedBox(height: 16),

          if (!hasImage)
            const _NoImageView(message: '등록된 ECG 이미지가 없습니다.')
          else
            _NetworkImageViewer(
              imageUrl: resolvedImageUrl,
              headers: mediaHeaders,
              title: 'ECG 이미지',
              heroTag: 'ecg-image-$resolvedImageUrl',
            ),
        ],
      ),
    );
  }
}

final class _ExaminationExpansionCard extends StatelessWidget {
  const _ExaminationExpansionCard({
    required this.examination,
    required this.examinationIndex,
    required this.mediaHeaders,
    required this.resolveMediaUrl,
  });

  final Map<String, dynamic> examination;
  final int examinationIndex;
  final Map<String, String> mediaHeaders;
  final String Function(String?) resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    final examId = _displayValue(examination['exam_id'] ?? examination['id']);

    final title = _findExaminationTitle(examination);

    final imageUrl = _findImageUrl(examination, const [
      'key_frame_url',
      'image_url',
      'frame_url',
      'thumbnail_url',
    ]);

    final resolvedImageUrl = imageUrl == null
        ? null
        : resolveMediaUrl(imageUrl);

    final examinationInformation = examination.entries.where((entry) {
      return !_isHiddenExaminationField(entry.key.toLowerCase());
    }).toList();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.image_outlined)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: examId == '-'
            ? const Text('이미지 상세보기')
            : Text('검사 번호 $examId'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        children: [
          const Divider(height: 1),

          if (examinationInformation.isNotEmpty) ...[
            const SizedBox(height: 16),

            ...examinationInformation.map((entry) {
              return _InformationRow(
                title: _fieldLabel(entry.key),
                value: _displayValue(entry.value),
              );
            }),
          ],

          const SizedBox(height: 12),

          if (resolvedImageUrl == null || resolvedImageUrl.trim().isEmpty)
            const _NoImageView(message: '등록된 Key Frame 이미지가 없습니다.')
          else
            _NetworkImageViewer(
              imageUrl: resolvedImageUrl,
              headers: mediaHeaders,
              title: title,
              heroTag:
                  'examination-$examinationIndex-$examId-$resolvedImageUrl',
            ),
        ],
      ),
    );
  }
}

final class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

final class _NetworkImageViewer extends StatelessWidget {
  const _NetworkImageViewer({
    required this.imageUrl,
    required this.headers,
    required this.title,
    required this.heroTag,
  });

  final String imageUrl;
  final Map<String, String> headers;
  final String title;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title 전체 화면으로 보기',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) {
                return _FullScreenImageView(
                  imageUrl: imageUrl,
                  headers: headers,
                  title: title,
                  heroTag: heroTag,
                );
              },
            ),
          );
        },
        child: Hero(
          tag: heroTag,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
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
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) {
                        return const SizedBox(
                          height: 260,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorWidget: (context, url, error) {
                        debugPrint('이미지 요청 URL: $url');

                        debugPrint('이미지 로드 오류: $error');

                        return const SizedBox(
                          height: 240,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 52,
                                  color: Colors.white70,
                                ),

                                SizedBox(height: 12),

                                Text(
                                  '이미지를 불러올 수 없습니다.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),

                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          color: Colors.white,
                          size: 16,
                        ),

                        SizedBox(width: 5),

                        Text(
                          '눌러서 크게 보기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _FullScreenImageView extends StatefulWidget {
  const _FullScreenImageView({
    required this.imageUrl,
    required this.headers,
    required this.title,
    required this.heroTag,
  });

  final String imageUrl;
  final Map<String, String> headers;
  final String title;
  final String heroTag;

  @override
  State<_FullScreenImageView> createState() {
    return _FullScreenImageViewState();
  }
}

final class _FullScreenImageViewState extends State<_FullScreenImageView> {
  final TransformationController _transformationController =
      TransformationController();

  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();

    _transformationController.addListener(_handleTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformationChanged);

    _transformationController.dispose();

    super.dispose();
  }

  void _handleTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();

    final nextIsZoomed = scale > 1.05;

    if (nextIsZoomed != _isZoomed && mounted) {
      setState(() {
        _isZoomed = nextIsZoomed;
      });
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _toggleZoom() {
    if (_isZoomed) {
      _resetZoom();
      return;
    }

    _transformationController.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isZoomed)
            IconButton(
              tooltip: '확대 초기화',
              onPressed: _resetZoom,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: _toggleZoom,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.8,
                  maxScale: 6,
                  panEnabled: true,
                  scaleEnabled: true,
                  clipBehavior: Clip.none,
                  boundaryMargin: const EdgeInsets.all(120),
                  child: Center(
                    child: Hero(
                      tag: widget.heroTag,
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        httpHeaders: widget.headers,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        placeholder: (context, url) {
                          return const SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorWidget: (context, url, error) {
                          debugPrint('전체 화면 이미지 URL: $url');

                          debugPrint('전체 화면 이미지 오류: $error');

                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 64,
                                  color: Colors.white70,
                                ),

                                SizedBox(height: 14),

                                Text(
                                  '이미지를 불러올 수 없습니다.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (!_isZoomed)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(child: _FullScreenGuide()),
              ),
          ],
        ),
      ),
    );
  }
}

final class _FullScreenGuide extends StatelessWidget {
  const _FullScreenGuide();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.zoom_in, color: Colors.white, size: 18),

            SizedBox(width: 7),

            Text(
              '두 손가락 또는 두 번 눌러 확대',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _NoImageView extends StatelessWidget {
  const _NoImageView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 44,
            color: colorScheme.onSurfaceVariant,
          ),

          const SizedBox(height: 10),

          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

final class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),

            const SizedBox(height: 12),

            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

final class _PatientDetailErrorView extends StatelessWidget {
  const _PatientDetailErrorView({required this.message, required this.onRetry});

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
            const Icon(Icons.error_outline, size: 64),

            const SizedBox(height: 16),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 20),

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

String _findExaminationTitle(Map<String, dynamic> examination) {
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

String? _findImageUrl(Map<String, dynamic> data, List<String> candidateKeys) {
  for (final key in candidateKeys) {
    final value = data[key];

    if (_hasValue(value)) {
      return value.toString().trim();
    }
  }

  return null;
}

bool _isHiddenExaminationField(String fieldName) {
  return fieldName.endsWith('_path') ||
      fieldName.endsWith('_url') ||
      fieldName.contains('video') ||
      fieldName == 'id' ||
      fieldName == 'exam_id';
}

String _fieldLabel(String fieldName) {
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

  return labels[fieldName] ?? fieldName.replaceAll('_', ' ');
}

String _nullableText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '미등록';
  }

  return value.trim();
}

String _displayValue(dynamic value) {
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
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }

  final result = value.toString().trim();

  return result.isEmpty ? '-' : result;
}

bool _hasValue(dynamic value) {
  if (value == null) {
    return false;
  }

  final text = value.toString().trim();

  return text.isNotEmpty && text.toLowerCase() != 'null';
}
