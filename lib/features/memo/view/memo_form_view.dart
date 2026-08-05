import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../patient/model/patient.dart';
import '../model/patient_memo.dart';
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
    _contentController.removeListener(_handleContentChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleContentChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MemoViewModel>();

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
            onPressed: viewModel.isSaving
                ? null
                : () => _saveMemo(viewModel),
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
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 48,
        ),
        child: Column(
          children: [
            Icon(
              Icons.mic_none,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              '음성 메모 준비 중',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '텍스트 메모 저장을 먼저 연결한 뒤\n음성 녹음 기능을 추가합니다.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('음성 메모 기능은 다음 단계에서 연결합니다.'),
        ),
      );
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(
            Icons.medication_outlined,
            size: 18,
          ),
          label: const Text('약물 복용'),
          onPressed: () {
            onSelected('약물 복용: ');
          },
        ),
        ActionChip(
          avatar: const Icon(
            Icons.science_outlined,
            size: 18,
          ),
          label: const Text('추가 검사'),
          onPressed: () {
            onSelected('추가 검사: ');
          },
        ),
        ActionChip(
          avatar: const Icon(
            Icons.priority_high,
            size: 18,
          ),
          label: const Text('특이 사항'),
          onPressed: () {
            onSelected('특이 사항: ');
          },
        ),
      ],
    );
  }
}