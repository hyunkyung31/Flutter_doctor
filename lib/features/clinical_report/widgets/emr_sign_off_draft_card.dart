import 'package:flutter/material.dart';

final class EmrSignOffDraftCard extends StatefulWidget {
  const EmrSignOffDraftCard({
    super.key,
    required this.isEnabled,
    required this.isSubmitting,
    required this.onSaveDraft,
    required this.onRequestConsultation,
    this.initialValue = '',
  });

  final bool isEnabled;
  final bool isSubmitting;
  final String initialValue;
  final Future<bool> Function(String opinion) onSaveDraft;
  final Future<void> Function(String opinion) onRequestConsultation;

  @override
  State<EmrSignOffDraftCard> createState() {
    return _EmrSignOffDraftCardState();
  }
}

final class _EmrSignOffDraftCardState extends State<EmrSignOffDraftCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _opinionController;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _opinionController = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant EmrSignOffDraftCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue != widget.initialValue &&
        _opinionController.text.trim() != widget.initialValue.trim()) {
      _opinionController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _opinionController.dispose();

    super.dispose();
  }

  Future<void> _saveDraft() async {
    if (!widget.isEnabled || widget.isSubmitting) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await widget.onSaveDraft(_opinionController.text.trim());

    if (!mounted || !success) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('의료진 소견 초안을 저장했습니다.')));
  }

  Future<void> _requestConsultation() async {
    if (!widget.isEnabled || widget.isSubmitting) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();

    await widget.onRequestConsultation(_opinionController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: widget.isSubmitting
                ? null
                : () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_note_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '의료진 소견 작성',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'AI 분석 결과를 참고하여 초안 소견을 작성합니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(height: 1),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _opinionController,
                      enabled: widget.isEnabled && !widget.isSubmitting,
                      minLines: 6,
                      maxLines: 12,
                      maxLength: 2000,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: '의료진 소견',
                        hintText: '협착 의심 위치, 중증도, 추가 확인 사항과 임상적 판단을 작성해 주세요.',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final normalizedValue = value?.trim() ?? '';

                        if (normalizedValue.isEmpty) {
                          return '의료진 소견을 입력해 주세요.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              '초안 저장 후 SIGN OFF 목록에서 최종 소견을 검토하고 승인할 수 있습니다.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: !widget.isEnabled || widget.isSubmitting
                                ? null
                                : _saveDraft,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('초안 저장'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: FilledButton.icon(
                            onPressed: !widget.isEnabled || widget.isSubmitting
                                ? null
                                : _requestConsultation,
                            icon: const Icon(Icons.group_add_outlined),
                            label: const Text('협진 요청'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (widget.isSubmitting) ...[
                      const SizedBox(height: 16),

                      const LinearProgressIndicator(),

                      const SizedBox(height: 8),

                      const Text(
                        '의료진 소견을 저장하고 있습니다.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
