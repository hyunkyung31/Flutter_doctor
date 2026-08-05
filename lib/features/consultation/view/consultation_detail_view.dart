import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../patient/model/patient.dart';
import '../../patient/view_model/patient_detail_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../model/consultation_request.dart';
import '../view_model/consultation_view_model.dart';

final class ConsultationDetailView extends StatefulWidget {
  const ConsultationDetailView({
    super.key,
    required this.request,
  });

  final ConsultationRequest request;

  @override
  State<ConsultationDetailView> createState() =>
      _ConsultationDetailViewState();
}

final class _ConsultationDetailViewState extends State<ConsultationDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.request.patientId.isNotEmpty) {
        context.read<PatientDetailViewModel>().loadPatientDetail(
          widget.request.patientId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientViewModel = context.watch<PatientDetailViewModel>();
    final consultationViewModel = context.watch<ConsultationViewModel>();
    final request = consultationViewModel.requestById(
          widget.request.consultationId,
        ) ??
        widget.request;
    final currentDoctorId = context.watch<AuthViewModel>().doctorId?.trim();
    final canRespond = currentDoctorId != null &&
        currentDoctorId.isNotEmpty &&
        currentDoctorId == request.receiverId.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('협진 요청 상세'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => patientViewModel.refreshPatientDetail(
          widget.request.patientId,
        ),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _ConsultationSection(request: request),
            if (request.responseMemo.isNotEmpty) ...[
              const SizedBox(height: 16),
              _OpinionRecordCard(request: request),
            ],
            const SizedBox(height: 24),
            Text(
              '환자 상세 정보',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _PatientSection(
              request: widget.request,
              viewModel: patientViewModel,
            ),
            const SizedBox(height: 24),
            _StatusActions(
              request: request,
              canRespond: canRespond,
            ),
          ],
        ),
      ),
    );
  }
}

final class _OpinionRecordCard extends StatelessWidget {
  const _OpinionRecordCard({required this.request});

  final ConsultationRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                const Text(
                  '작성한 의료진 소견',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SelectableText(request.responseMemo),
            if (request.completedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                '전송 일시  ${_completedDateText(request.completedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _completedDateText(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${local.year}.${twoDigits(local.month)}.${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

final class _StatusActions extends StatefulWidget {
  const _StatusActions({
    required this.request,
    required this.canRespond,
  });

  final ConsultationRequest request;
  final bool canRespond;

  @override
  State<_StatusActions> createState() => _StatusActionsState();
}

final class _StatusActionsState extends State<_StatusActions> {
  bool _isOpinionFormVisible = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.request.status.trim().toLowerCase();

    if (!widget.canRespond) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.schedule_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status == 'completed'
                      ? '상대 의료진의 소견 작성이 완료되었습니다.'
                      : '상대 의료진의 소견을 기다리고 있습니다.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'in_progress') {
      if (_isOpinionFormVisible) {
        return _OpinionComposer(request: widget.request);
      }

      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            setState(() {
              _isOpinionFormVisible = true;
            });
          },
          icon: const Icon(Icons.check),
          label: const Text('수락'),
        ),
      );
    }

    if (status == 'accepted') {
      return _OpinionComposer(request: widget.request);
    }

    if (status == 'completed' || status == 'rejected') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                status == 'completed' ? Icons.task_alt : Icons.cancel_outlined,
              ),
              const SizedBox(width: 10),
              Text(
                status == 'completed'
                    ? '완료된 협진입니다.'
                    : '거절된 협진입니다.',
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

final class _OpinionComposer extends StatefulWidget {
  const _OpinionComposer({required this.request});

  final ConsultationRequest request;

  @override
  State<_OpinionComposer> createState() => _OpinionComposerState();
}

final class _OpinionComposerState extends State<_OpinionComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final opinion = _controller.text.trim();

    if (opinion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('의료진 소견을 입력해 주세요.')),
      );
      return;
    }

    final viewModel = context.read<ConsultationViewModel>();
    final success = await viewModel.completeConsultation(
      consultationId: widget.request.consultationId,
      responseMemo: opinion,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ?? '소견을 전송하지 못했습니다.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('소견을 전송했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_outline),
                SizedBox(width: 10),
                Text(
                  '수락한 협진 요청입니다.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              '의료진 소견',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: '검사 결과와 환자 상태에 대한 소견을 입력하세요.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_outlined),
                label: const Text('소견 전송'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ConsultationSection extends StatelessWidget {
  const _ConsultationSection({required this.request});

  final ConsultationRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              label: '요청 의료진',
              value: request.senderName.isEmpty ? '정보 없음' : request.senderName,
            ),
            _DetailRow(label: '상태', value: _statusLabel(request.status)),
            _DetailRow(
              label: '긴급도',
              value: _priorityLabel(request.priority),
            ),
            _DetailRow(
              label: '요청 일시',
              value: request.createdAt == null
                  ? '정보 없음'
                  : _dateText(request.createdAt!),
            ),
            const Divider(height: 28),
            const Text(
              '협진 요청 내용',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(request.reason.isEmpty ? '입력된 요청 내용이 없습니다.' : request.reason),
            if (request.memo.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                '추가 메모',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(request.memo),
            ],
            if (request.referenceTypes.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                '공유 자료',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: request.referenceTypes
                    .map((type) => Chip(label: Text(_referenceLabel(type))))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
      case 'requested':
      case 'waiting':
      case 'new':
        return '대기';
      case 'accepted':
        return '수락됨';
      case 'in_progress':
        return '검토중';
      case 'completed':
        return '완료';
      case 'rejected':
        return '거절됨';
      default:
        return value.isEmpty ? '정보 없음' : value;
    }
  }

  String _priorityLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'normal':
        return '일반';
      case 'high':
        return '높음';
      case 'urgent':
        return '긴급';
      default:
        return value.isEmpty ? '정보 없음' : value;
    }
  }

  String _referenceLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'patient_info':
        return '환자 기본정보';
      case 'angiography':
        return '혈관조영 영상';
      case 'ai_analysis':
        return 'AI 분석 결과';
      case 'test_result':
        return '검사 결과';
      default:
        return value;
    }
  }

  String _dateText(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${local.year}.${twoDigits(local.month)}.${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

final class _PatientSection extends StatelessWidget {
  const _PatientSection({
    required this.request,
    required this.viewModel,
  });

  final ConsultationRequest request;
  final PatientDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (request.patientId.isEmpty) {
      return const _MessageCard(message: '협진 요청에 환자 ID가 없습니다.');
    }

    if (viewModel.isLoading && viewModel.patientDetail == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(36),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (viewModel.errorMessage != null && viewModel.patientDetail == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(viewModel.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => viewModel.loadPatientDetail(request.patientId),
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final detail = viewModel.patientDetail;
    if (detail == null) {
      return const _MessageCard(message: '환자 상세 정보가 없습니다.');
    }

    return _PatientCard(
      patient: detail.patient,
      examinations: detail.examinations,
      aiResults: detail.aiResults,
      mediaHeaders: viewModel.mediaHeaders,
      resolveMediaUrl: viewModel.resolveMediaUrl,
    );
  }
}

final class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.examinations,
    required this.aiResults,
    required this.mediaHeaders,
    required this.resolveMediaUrl,
  });

  final Patient patient;
  final List<Map<String, dynamic>> examinations;
  final List<Map<String, dynamic>> aiResults;
  final Map<String, String> mediaHeaders;
  final String Function(String?) resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _DetailRow(label: '환자명', value: patient.patientName),
            _DetailRow(label: '환자 ID', value: patient.patientId),
            _DetailRow(label: '성별', value: patient.genderText),
            _DetailRow(label: '나이', value: '${patient.age}세'),
            _DetailRow(
              label: '담당 의료진',
              value: _nullableValue(patient.primaryDoctorId),
            ),
            _DetailRow(
              label: '주호소',
              value: patient.chiefComplaint?.trim().isNotEmpty == true
                  ? patient.chiefComplaint!
                  : '정보 없음',
            ),
            _DetailRow(
              label: 'ECG 결과',
              value: patient.ecgResult?.trim().isNotEmpty == true
                  ? patient.ecgResult!
                  : '정보 없음',
            ),
            _DetailRow(label: 'Troponin T', value: patient.troponinTText),
            _DetailRow(label: 'History 점수', value: patient.historyScoreText),
            _DetailRow(
              label: '위험인자',
              value: patient.riskFactorsCountText,
            ),
            const SizedBox(height: 12),
            _ImageMedia(
              title: '심전도 이미지',
              imageUrl: resolveMediaUrl(patient.ecgImageUrl),
              headers: mediaHeaders,
              emptyMessage: '심전도 이미지가 없습니다.',
            ),
            const Divider(height: 28),
            _RecordSection(
              title: '검사 기록',
              icon: Icons.medical_information_outlined,
              records: examinations,
              emptyMessage: '등록된 검사 기록이 없습니다.',
              mediaHeaders: mediaHeaders,
              resolveMediaUrl: resolveMediaUrl,
            ),
            const SizedBox(height: 12),
            _RecordSection(
              title: 'AI 분석 결과',
              icon: Icons.analytics_outlined,
              records: aiResults,
              emptyMessage: 'AI 분석 결과가 없습니다.',
              mediaHeaders: mediaHeaders,
              resolveMediaUrl: resolveMediaUrl,
            ),
          ],
        ),
      ),
    );
  }

  String _nullableValue(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? '정보 없음' : normalized;
  }
}

final class _RecordSection extends StatelessWidget {
  const _RecordSection({
    required this.title,
    required this.icon,
    required this.records,
    required this.emptyMessage,
    required this.mediaHeaders,
    required this.resolveMediaUrl,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> records;
  final String emptyMessage;
  final Map<String, String> mediaHeaders;
  final String Function(String?) resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              '$title ${records.length}건',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (records.isEmpty)
          Text(emptyMessage)
        else
          ...records.asMap().entries.map(
            (entry) => _RecordTile(
              index: entry.key,
              record: entry.value,
              title: title,
              mediaHeaders: mediaHeaders,
              resolveMediaUrl: resolveMediaUrl,
            ),
          ),
      ],
    );
  }
}

final class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.index,
    required this.record,
    required this.title,
    required this.mediaHeaders,
    required this.resolveMediaUrl,
  });

  final int index;
  final Map<String, dynamic> record;
  final String title;
  final Map<String, String> mediaHeaders;
  final String Function(String?) resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    final visibleEntries = record.entries
        .where((entry) => !_isMediaField(entry.key))
        .toList();
    final imageUrl = _findMediaUrl(record, const [
      'key_frame_url',
      'image_url',
      'frame_url',
      'thumbnail_url',
    ]);
    final videoUrl = _findMediaUrl(record, const [
      'original_video_url',
      'video_url',
      'angiography_url',
      'file_url',
      'media_url',
    ]);

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text('$title ${index + 1}'),
        subtitle: Text(_recordSubtitle(record)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          ...visibleEntries.map(
            (entry) => _DetailRow(
              label: _fieldLabel(entry.key),
              value: _displayValue(entry.value),
            ),
          ),
          if (imageUrl != null) ...[
            const SizedBox(height: 8),
            _ImageMedia(
              title: '촬영 이미지',
              imageUrl: resolveMediaUrl(imageUrl),
              headers: mediaHeaders,
              emptyMessage: '촬영 이미지가 없습니다.',
            ),
          ],
          if (videoUrl != null) ...[
            const SizedBox(height: 12),
            _VideoMedia(
              videoUrl: resolveMediaUrl(videoUrl),
              headers: mediaHeaders,
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('환자 촬영 영상이 없습니다.'),
            ),
        ],
      ),
    );
  }

  String _recordSubtitle(Map<String, dynamic> value) {
    final candidate =
        value['exam_name'] ??
        value['exam_type'] ??
        value['result'] ??
        value['status'] ??
        value['created_at'];

    return _displayValue(candidate);
  }

  bool _isMediaField(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('image') ||
        normalized.contains('frame') ||
        normalized.contains('video');
  }

  String _fieldLabel(String key) {
    const labels = <String, String>{
      'exam_id': '검사 ID',
      'exam_date': '검사일',
      'exam_type': '검사 종류',
      'exam_name': '검사명',
      'result': '결과',
      'status': '상태',
      'created_at': '생성 일시',
      'updated_at': '수정 일시',
      'confidence': '신뢰도',
      'stenosis_rate': '협착률',
      'vessel_name': '혈관명',
    };

    return labels[key.toLowerCase()] ?? key;
  }

  String _displayValue(dynamic value) {
    if (value == null) {
      return '-';
    }

    if (value is List) {
      return value.map(_displayValue).join(', ');
    }

    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${_displayValue(entry.value)}')
          .join(', ');
    }

    final result = value.toString().trim();
    return result.isEmpty ? '-' : result;
  }
}

final class _ImageMedia extends StatelessWidget {
  const _ImageMedia({
    required this.title,
    required this.imageUrl,
    required this.headers,
    required this.emptyMessage,
  });

  final String title;
  final String imageUrl;
  final Map<String, String> headers;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(emptyMessage),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            httpHeaders: headers,
            width: double.infinity,
            fit: BoxFit.contain,
            placeholder: (_, _) => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, _, _) => const SizedBox(
              height: 140,
              child: Center(child: Text('이미지를 불러올 수 없습니다.')),
            ),
          ),
        ),
      ],
    );
  }
}

final class _VideoMedia extends StatefulWidget {
  const _VideoMedia({required this.videoUrl, required this.headers});

  final String videoUrl;
  final Map<String, String> headers;

  @override
  State<_VideoMedia> createState() => _VideoMediaState();
}

final class _VideoMediaState extends State<_VideoMedia> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      httpHeaders: widget.headers,
    );
    _initializeFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !_controller.value.isInitialized) {
          return const SizedBox(
            height: 140,
            child: Center(child: Text('촬영 영상을 불러올 수 없습니다.')),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '환자 촬영 영상',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  IconButton.filled(
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

String? _findMediaUrl(
  Map<String, dynamic> record,
  List<String> candidateKeys,
) {
  for (final key in candidateKeys) {
    final value = record[key]?.toString().trim() ?? '';
    if (value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }

  return null;
}

final class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

final class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(message)),
      ),
    );
  }
}
