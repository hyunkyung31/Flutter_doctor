import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/storage/secure_storage.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../patient/model/patient.dart';
import '../../patient/model/patient_detail.dart';
import '../../patient/repository/patient_repository.dart';
import '../../patient/view_model/patient_detail_view_model.dart';
import '../../patient/view_model/patient_list_view_model.dart';
import '../model/chat_models.dart';
import '../view_model/chat_view_model.dart';

final class ChatRoomView extends StatefulWidget {
  const ChatRoomView({super.key, required this.roomId});

  final String roomId;

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

final class _ChatRoomViewState extends State<ChatRoomView> {
  final controller = TextEditingController();
  Timer? _messagePollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatViewModel>().loadMessages(widget.roomId);
      _messagePollingTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) {
          if (mounted) {
            context.read<ChatViewModel>().loadMessages(widget.roomId);
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _messagePollingTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();
    final room = viewModel.roomById(widget.roomId);
    if (room == null) {
      return const Scaffold(body: Center(child: Text('채팅방을 찾을 수 없습니다.')));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room.doctor.name, style: const TextStyle(fontSize: 17)),
            Text(
              '${room.doctor.department} · ${room.doctor.hospital}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: viewModel.isRoomLoading(widget.roomId) && room.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : room.messages.isEmpty
                ? const Center(child: Text('메시지를 보내 대화를 시작하세요.'))
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: room.messages.length,
                    itemBuilder: (context, index) {
                      final message = room.messages.reversed.elementAt(index);
                      return _MessageBubble(
                        message: message,
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filledTonal(
                    tooltip: '자료 공유',
                    onPressed: () => _showShareMenu(context, viewModel),
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: '메시지를 입력하세요',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: '전송',
                    onPressed: viewModel.isSending(widget.roomId)
                        ? null
                        : () async {
                      final success = await viewModel.sendText(
                        widget.roomId,
                        controller.text,
                      );
                      if (success) controller.clear();
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              viewModel.errorMessage ?? '메시지를 전송하지 못했습니다.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showShareMenu(
    BuildContext context,
    ChatViewModel viewModel,
  ) async {
    final type = await showModalBottomSheet<ChatMessageType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text('자료 공유', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            _shareTile(context, Icons.person, '환자 공유', ChatMessageType.patient),
            _shareTile(context, Icons.monitor_heart, '혈관조영 영상', ChatMessageType.examination),
            _shareTile(context, Icons.auto_awesome, 'AI 분석 결과', ChatMessageType.aiResult),
          ],
        ),
      ),
    );
    if (!mounted || type == null) return;
    final patient = await showModalBottomSheet<Patient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _PatientPickerSheet(),
    );
    if (!mounted || patient == null) return;
    int? examId;
    int? aiResultId;
    if (type == ChatMessageType.examination ||
        type == ChatMessageType.aiResult) {
      final selectedId = await _selectClinicalData(context, patient, type);
      if (!mounted || selectedId == null) return;
      examId = selectedId;
      if (type == ChatMessageType.aiResult) aiResultId = selectedId;
    }
    final content = switch (type) {
      ChatMessageType.patient => '환자 자료를 공유했습니다.',
      ChatMessageType.examination => '검사 자료를 공유했습니다.',
      ChatMessageType.aiResult => 'AI 분석 결과를 공유했습니다.',
      ChatMessageType.consultation => '협진 요청을 공유했습니다.',
      ChatMessageType.text => '',
    };
    final success = await viewModel.share(
      widget.roomId,
      type: type,
      content: content,
      patientId: patient.patientId,
      examId: examId,
      aiResultId: aiResultId,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? '자료를 공유하지 못했습니다.')),
      );
    }
  }

  Future<int?> _selectClinicalData(
    BuildContext context,
    Patient patient,
    ChatMessageType type,
  ) async {
    try {
      final detail = await context
          .read<PatientRepository>()
          .getPatientDetail(patient.patientId);
      if (!context.mounted) return null;
      final items = type == ChatMessageType.aiResult
          ? detail.aiResults
          : detail.examinations;
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == ChatMessageType.aiResult
                  ? '공유할 AI 분석 결과가 없습니다.'
                  : '공유할 검사 자료가 없습니다.',
            ),
          ),
        );
        return null;
      }
      return showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  type == ChatMessageType.aiResult
                      ? '공유할 AI 분석 결과 선택'
                      : '공유할 검사 자료 선택',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final id = int.tryParse(
                      (item['exam_id'] ?? item['id'] ?? '').toString(),
                    );
                    return ListTile(
                      leading: Icon(
                        type == ChatMessageType.aiResult
                            ? Icons.auto_awesome
                            : Icons.monitor_heart,
                      ),
                      title: Text('검사 ${id ?? index + 1}'),
                      subtitle: Text(
                        (item['vessel_type'] ??
                                item['severity_class'] ??
                                '상세 자료')
                            .toString(),
                      ),
                      enabled: id != null,
                      onTap: id == null
                          ? null
                          : () => Navigator.pop(context, id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
      return null;
    }
  }

  Widget _shareTile(
    BuildContext context,
    IconData icon,
    String title,
    ChatMessageType type,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => Navigator.pop(context, type),
    );
  }
}

final class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final currentDoctorId = context.watch<AuthViewModel>().doctorId;
    final mine = currentDoctorId != null &&
        message.senderId.trim() == currentDoctorId.trim();
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (mine) _Time(message: message, showReadStatus: true),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mine ? colors.primary : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft: Radius.circular(mine ? 22 : 6),
                    bottomRight: Radius.circular(mine ? 6 : 22),
                  ),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: mine ? colors.onPrimary : colors.onSurfaceVariant,
                  ),
                  child: message.type == ChatMessageType.text
                      ? Text(message.content)
                      : _SharedCard(
                          message: message,
                          isMine: mine,
                        ),
                ),
              ),
            ),
            if (!mine) _Time(message: message, showReadStatus: false),
          ],
        ),
      ),
    );
  }
}

final class _SharedCard extends StatelessWidget {
  const _SharedCard({
    required this.message,
    required this.isMine,
  });

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final title = switch (message.type) {
      ChatMessageType.patient => '환자 자료',
      ChatMessageType.examination => '검사 자료',
      ChatMessageType.aiResult => 'AI 분석 결과',
      ChatMessageType.consultation => '협진 요청',
      ChatMessageType.text => '메시지',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (message.patientName != null)
          Text('${message.patientName} · ${message.patientId}'),
        Text(message.content),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: isMine
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => _openSharedData(context),
          child: const Text('자료 보기'),
        ),
      ],
    );
  }

  void _openSharedData(BuildContext context) {
    final patientId = message.patientId?.trim();
    if (patientId == null || patientId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('공유된 환자 정보를 찾을 수 없습니다.')),
        );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => ChangeNotifierProvider(
        create: (_) => PatientDetailViewModel(
          patientRepository: context.read<PatientRepository>(),
          secureStorage: context.read<SecureStorage>(),
        )..loadPatientDetail(patientId),
        child: _SharedDataSheet(message: message),
      ),
    );
  }
}

final class _SharedDataSheet extends StatelessWidget {
  const _SharedDataSheet({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientDetailViewModel>();
    final detail = viewModel.patientDetail;
    final title = switch (message.type) {
      ChatMessageType.patient => '환자 정보',
      ChatMessageType.examination => '검사·촬영 자료',
      ChatMessageType.aiResult => 'AI 분석 결과',
      ChatMessageType.consultation => '협진 요청',
      ChatMessageType.text => '공유 자료',
    };

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.86,
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${message.patientName} · ${message.patientId}'),
            trailing: IconButton(
              tooltip: '닫기',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: viewModel.isLoading && detail == null
                ? const Center(child: CircularProgressIndicator())
                : viewModel.errorMessage != null && detail == null
                    ? _SharedDataError(
                        message: viewModel.errorMessage!,
                        onRetry: () => viewModel.loadPatientDetail(
                          message.patientId ?? '',
                        ),
                      )
                    : detail == null
                        ? const Center(child: Text('표시할 자료가 없습니다.'))
                        : _SharedDataBody(
                            messageType: message.type,
                            detail: detail,
                            viewModel: viewModel,
                          ),
          ),
        ],
      ),
    );
  }
}

final class _SharedDataBody extends StatelessWidget {
  const _SharedDataBody({
    required this.messageType,
    required this.detail,
    required this.viewModel,
  });

  final ChatMessageType messageType;
  final PatientDetail detail;
  final PatientDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return switch (messageType) {
      ChatMessageType.patient => _PatientDataView(
          patient: detail.patient,
          viewModel: viewModel,
        ),
      ChatMessageType.examination => _MapDataList(
          items: detail.examinations,
          emptyMessage: '검사·촬영 자료가 없습니다.',
          resolveMediaUrl: viewModel.resolveMediaUrl,
          mediaHeaders: viewModel.mediaHeaders,
        ),
      ChatMessageType.aiResult => _MapDataList(
          items: detail.aiResults,
          emptyMessage: 'AI 분석 결과가 없습니다.',
          resolveMediaUrl: viewModel.resolveMediaUrl,
          mediaHeaders: viewModel.mediaHeaders,
        ),
      ChatMessageType.consultation => _PatientDataView(
          patient: detail.patient,
          viewModel: viewModel,
        ),
      ChatMessageType.text => const Center(child: Text('표시할 자료가 없습니다.')),
    };
  }
}

final class _PatientDataView extends StatelessWidget {
  const _PatientDataView({
    required this.patient,
    required this.viewModel,
  });

  final Patient patient;
  final PatientDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: '환자 ID', value: patient.patientId),
        _InfoRow(label: '이름', value: patient.patientName),
        _InfoRow(label: '성별', value: patient.genderText),
        _InfoRow(label: '나이', value: '${patient.age}세'),
        _InfoRow(label: '주호소', value: patient.chiefComplaint ?? '미등록'),
        _InfoRow(label: '심전도 결과', value: patient.ecgResult ?? '미등록'),
        _InfoRow(label: 'Troponin T', value: patient.troponinTText),
        const SizedBox(height: 12),
        Text(
          '심전도 이미지',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (patient.ecgImageUrl.trim().isEmpty)
          const Text('심전도 이미지가 없습니다.')
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: viewModel.resolveMediaUrl(patient.ecgImageUrl),
              httpHeaders: viewModel.mediaHeaders,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => const SizedBox(
                height: 180,
                child: Center(
                  child: Text('심전도 이미지를 불러올 수 없습니다.'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      ),
    );
  }
}

final class _MapDataList extends StatelessWidget {
  const _MapDataList({
    required this.items,
    required this.emptyMessage,
    required this.resolveMediaUrl,
    required this.mediaHeaders,
  });

  final List<Map<String, dynamic>> items;
  final String emptyMessage;
  final String Function(String?) resolveMediaUrl;
  final Map<String, String> mediaHeaders;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(child: Text(emptyMessage));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final imageUrls = _imageUrls(item);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '자료 ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...item.entries
                    .where((entry) => !_isMediaField(entry.key))
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text('${_fieldLabel(entry.key)}: ${entry.value}'),
                      ),
                    ),
                ...imageUrls.map(
                  (url) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: resolveMediaUrl(url),
                        httpHeaders: mediaHeaders,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const SizedBox(
                          height: 160,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => const SizedBox(
                          height: 100,
                          child: Center(child: Text('촬영 이미지를 불러올 수 없습니다.')),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _imageUrls(Map<String, dynamic> item) {
    return item.entries
        .where((entry) => _isMediaField(entry.key))
        .expand((entry) => entry.value is List ? entry.value as List : [entry.value])
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
  }

  bool _isMediaField(String key) {
    final value = key.toLowerCase();
    return value.contains('image') ||
        value.contains('frame') ||
        value.contains('thumbnail') ||
        value.contains('media') ||
        value.contains('video');
  }

  String _fieldLabel(String key) => key.replaceAll('_', ' ');
}

final class _SharedDataError extends StatelessWidget {
  const _SharedDataError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

final class _PatientPickerSheet extends StatefulWidget {
  const _PatientPickerSheet();

  @override
  State<_PatientPickerSheet> createState() => _PatientPickerSheetState();
}

final class _PatientPickerSheetState extends State<_PatientPickerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientListViewModel>();
    final patients = viewModel.patients.where((patient) {
      final keyword = query.toLowerCase();
      return keyword.isEmpty ||
          patient.patientName.toLowerCase().contains(keyword) ||
          patient.patientId.toLowerCase().contains(keyword);
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '공유할 환자 선택',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: '환자 이름 또는 환자 ID 검색',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => query = value.trim()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: viewModel.isLoading && viewModel.patients.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : viewModel.errorMessage != null &&
                          viewModel.patients.isEmpty
                      ? _PatientLoadError(
                          message: viewModel.errorMessage!,
                          onRetry: viewModel.loadPatients,
                        )
                      : patients.isEmpty
                          ? const Center(child: Text('선택할 환자가 없습니다.'))
                          : RefreshIndicator(
                              onRefresh: viewModel.refreshPatients,
                              child: ListView.separated(
                                itemCount: patients.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final patient = patients[index];
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                                    title: Text(patient.patientName),
                                    subtitle: Text(
                                      '${patient.patientId} · ${patient.genderText} · ${patient.age}세',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () =>
                                        Navigator.pop(context, patient),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PatientLoadError extends StatelessWidget {
  const _PatientLoadError({required this.message, required this.onRetry});

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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

final class _Time extends StatelessWidget {
  const _Time({required this.message, required this.showReadStatus});

  final ChatMessage message;
  final bool showReadStatus;

  @override
  Widget build(BuildContext context) {
    final hour = message.sentAt.hour;
    final minute = message.sentAt.minute.toString().padLeft(2, '0');
    if (showReadStatus) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isRead)
              Text(
                '1',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            Text(
              '$hour:$minute',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Text(
        '$hour:$minute${showReadStatus ? (message.isRead ? ' 읽음' : ' 안 읽음') : ''}',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
