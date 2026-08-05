import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../patient/model/patient.dart';
import '../model/patient_memo.dart';
import '../service/voice_memo_recorder.dart';
import '../view_model/memo_view_model.dart';

final class MemoFormView extends StatefulWidget {
  const MemoFormView({
    super.key,
    required this.patient,
    this.memo,
  });

  final Patient patient;
  final PatientMemo? memo;

  bool get isEditing => memo != null;

  @override
  State<MemoFormView> createState() => _MemoFormViewState();
}

final class _MemoFormViewState extends State<MemoFormView> {
  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _contentController =
      TextEditingController();

  PatientMemoType _selectedType = PatientMemoType.text;

  final VoiceMemoRecorder _voiceRecorder = VoiceMemoRecorder();

  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _recordedPath;

  bool _isRecording = false;
  bool _isPaused = false;

  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();

    final memo = widget.memo;

    if (memo != null) {
      _titleController.text = memo.title;
      _contentController.text = memo.content;
      _selectedType = memo.memoType;
    }

    _contentController.addListener(_handleContentChanged);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    unawaited(_disposeVoiceResources());
    _contentController.removeListener(_handleContentChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleContentChanged() {
    setState(() {});
  }

  Future<void> _disposeVoiceResources() async {
    await _audioPlayer.dispose();
    await _voiceRecorder.dispose();
    await _voiceRecorder.deleteTemporaryFile(_recordedPath);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MemoViewModel>();
    final canSave = !viewModel.isSaving &&
        (_selectedType == PatientMemoType.text ||
            (widget.isEditing
                ? _titleController.text.trim().isNotEmpty
                : (!_isRecording &&
                    _recordedPath != null &&
                    _recordedPath!.isNotEmpty)));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? '메모 수정' : '새 메모',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: canSave ? () => _saveMemo(viewModel) : null,
            child: Text(
              viewModel.isSaving ? '저장 중' : '저장',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _PatientHeader(patient: widget.patient),
            const SizedBox(height: 20),
            _MemoTypeSelector(
              selectedType: _selectedType,
              enabled: !widget.isEditing,
              onChanged: _changeMemoType,
            ),
            const SizedBox(height: 20),
            if (_selectedType == PatientMemoType.text)
              _buildTextMemoForm(context)
            else
              _buildVoicePreparingView(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTextMemoForm(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '메모 제목을 입력하세요.',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _contentController,
              minLines: 10,
              maxLines: 16,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: '메모 내용을 입력하세요.',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                counterText:
                    '${_contentController.text.length} / 1000',
              ),
            ),
            const SizedBox(height: 14),
            _QuickMemoButtons(
              onSelected: _appendQuickText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoicePreparingView(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          maxLength: 200,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: '음성 메모 제목',
            hintText: '제목을 입력해 주세요.',
            prefixIcon: Icon(Icons.title),
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 72,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _durationText(
                widget.isEditing
                    ? widget.memo?.audioDurationSeconds ?? 0
                    : _recordingSeconds,
              ),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isEditing
                  ? '저장된 음성 메모'
                  : _isRecording
                  ? _isPaused
                      ? '일시정지'
                      : '녹음 중...'
                  : _recordedPath == null
                      ? '녹음 준비'
                      : '녹음 완료',
            ),
            const SizedBox(height: 24),
            if (widget.isEditing)
              Text(
                '기존 녹음은 유지되고 제목만 수정됩니다.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else if (!_isRecording)
              FilledButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.mic),
                label: Text(
                  _recordedPath == null ? '녹음 시작' : '다시 녹음',
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _togglePause,
                      icon: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                      ),
                      label: Text(_isPaused ? '계속 녹음' : '일시정지'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop),
                      label: const Text('완료'),
                    ),
                  ),
                ],
              ),
            if (!widget.isEditing &&
                !_isRecording &&
                _recordedPath != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _playRecording,
                icon: const Icon(Icons.play_arrow),
                label: const Text('녹음 재생'),
              ),
            ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _changeMemoType(PatientMemoType value) async {
    if (_selectedType == value) return;

    await _audioPlayer.stop();
    if (_isRecording || _isPaused) {
      await _voiceRecorder.cancel();
    } else {
      await _voiceRecorder.deleteTemporaryFile(_recordedPath);
    }
    _recordingTimer?.cancel();

    if (!mounted) return;
    setState(() {
      _selectedType = value;
      _isRecording = false;
      _isPaused = false;
      _recordedPath = null;
      _recordingSeconds = 0;
    });
  }

  Future<void> _startRecording() async {
    try {
      await _audioPlayer.stop();
      final path = await _voiceRecorder.start();

      if (!mounted) return;
      setState(() {
        _recordedPath = path;
        _isRecording = true;
        _isPaused = false;
        _recordingSeconds = 0;
      });
      _startRecordingTimer();
    } on VoiceMemoRecorderException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) return;
      _showMessage('녹음을 시작하지 못했습니다: $error');
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused) return;
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _togglePause() async {
    try {
      if (_isPaused) {
        await _voiceRecorder.resume();
      } else {
        await _voiceRecorder.pause();
      }

      if (!mounted) return;
      setState(() => _isPaused = !_isPaused);
    } catch (error) {
      if (!mounted) return;
      _showMessage('녹음 상태를 변경하지 못했습니다: $error');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _voiceRecorder.stop();
      _recordingTimer?.cancel();

      if (!mounted) return;
      setState(() {
        _recordedPath = path;
        _isRecording = false;
        _isPaused = false;
      });

      if (path == null || path.isEmpty) {
        _showMessage('녹음 파일이 생성되지 않았습니다.');
        return;
      }

      final fileSize = await File(path).length();
      if (mounted) _showMessage('녹음 완료: $fileSize bytes');
    } catch (error) {
      if (!mounted) return;
      _showMessage('녹음을 완료하지 못했습니다: $error');
    }
  }

  Future<void> _playRecording() async {
    final path = _recordedPath;
    if (path == null || path.isEmpty) {
      _showMessage('재생할 녹음 파일이 없습니다.');
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();
    } catch (error) {
      if (!mounted) return;
      _showMessage('녹음 파일을 재생하지 못했습니다: $error');
    }
  }

  String _durationText(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '${minutes.toString().padLeft(2, '0')}:$seconds';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _appendQuickText(String value) {
    final current = _contentController.text.trimRight();

    final nextValue = current.isEmpty
        ? value
        : '$current\n$value';

    if (nextValue.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메모는 최대 1000자까지 입력할 수 있습니다.'),
        ),
      );
      return;
    }

    _contentController.text = nextValue;
    _contentController.selection = TextSelection.collapsed(
      offset: nextValue.length,
    );
  }

  Future<void> _saveMemo(
    MemoViewModel viewModel,
  ) async {
    if (_selectedType == PatientMemoType.voice) {
      if (widget.isEditing) {
        final editingMemo = widget.memo;
        if (editingMemo == null) return;

        final success = await viewModel.updateVoiceMemo(
          memoId: editingMemo.id,
          title: _titleController.text,
        );

        if (!mounted) return;
        if (!success) {
          _showMessage(
            viewModel.errorMessage ?? '음성 메모 제목을 수정하지 못했습니다.',
          );
          return;
        }
        Navigator.of(context).pop(true);
        return;
      }

      final path = _recordedPath;
      if (path == null || path.isEmpty) {
        _showMessage('녹음을 완료한 뒤 저장해 주세요.');
        return;
      }

      final success = await viewModel.createVoiceMemo(
        patientId: widget.patient.patientId,
        audioPath: path,
        durationSeconds: _recordingSeconds < 1 ? 1 : _recordingSeconds,
        title: _titleController.text.trim().isEmpty
            ? '음성 메모'
            : _titleController.text.trim(),
      );

      if (!mounted) return;
      if (!success) {
        _showMessage(
          viewModel.errorMessage ?? '음성 메모를 저장하지 못했습니다.',
        );
        return;
      }

      await _voiceRecorder.deleteTemporaryFile(path);
      _recordedPath = null;
      if (!mounted) return;
      _showMessage('음성 메모를 저장했습니다.');
      Navigator.of(context).pop(true);
      return;
    }

    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메모 내용을 입력해 주세요.'),
        ),
      );
      return;
    }

    var title = _titleController.text.trim();

    if (title.isEmpty) {
      title = _createTitle(content);
    }

    final memo = widget.memo;

    final success = memo == null
        ? await viewModel.createTextMemo(
            patientId: widget.patient.patientId,
            title: title,
            content: content,
          )
        : await viewModel.updateTextMemo(
            memoId: memo.id,
            title: title,
            content: content,
            examId: memo.examId,
          );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ??
                '메모를 저장하지 못했습니다.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? '메모를 수정했습니다.'
              : '메모를 저장했습니다.',
        ),
      ),
    );

    Navigator.of(context).pop(true);
  }

  String _createTitle(String content) {
    final firstLine = content
        .split('\n')
        .first
        .trim();

    if (firstLine.length <= 30) {
      return firstLine;
    }

    return '${firstLine.substring(0, 30)}…';
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

    return Row(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 21,
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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                '${patient.genderText} · ${patient.age}세',
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
    );
  }
}

final class _MemoTypeSelector extends StatelessWidget {
  const _MemoTypeSelector({
    required this.selectedType,
    required this.enabled,
    required this.onChanged,
  });

  final PatientMemoType selectedType;
  final bool enabled;
  final ValueChanged<PatientMemoType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<PatientMemoType>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: PatientMemoType.text,
            icon: Icon(Icons.description_outlined),
            label: Text('텍스트 메모'),
          ),
          ButtonSegment(
            value: PatientMemoType.voice,
            icon: Icon(Icons.mic_none),
            label: Text('음성 메모'),
          ),
        ],
        selected: {selectedType},
        onSelectionChanged: enabled
            ? (selection) {
                onChanged(selection.first);
              }
            : null,
      ),
    );
  }
}

final class _QuickMemoButtons extends StatelessWidget {
  const _QuickMemoButtons({
    required this.onSelected,
  });

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickMemoButton(
            icon: Icons.medication_outlined,
            label: '복용 약물',
            onPressed: () => onSelected('복용 약물: '),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickMemoButton(
            icon: Icons.science_outlined,
            label: '추가 검사',
            onPressed: () => onSelected('추가 검사: '),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickMemoButton(
            icon: Icons.priority_high_rounded,
            label: '특이 사항',
            onPressed: () => onSelected('특이 사항: '),
          ),
        ),
      ],
    );
  }
}

final class _QuickMemoButton extends StatelessWidget {
  const _QuickMemoButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          foregroundColor: colorScheme.primary,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.04),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.18),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 17),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
