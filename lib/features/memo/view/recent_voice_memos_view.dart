import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../model/patient_memo.dart';
import '../repository/memo_repository.dart';
import '../view_model/memo_view_model.dart';

final class RecentVoiceMemosView extends StatefulWidget {
  const RecentVoiceMemosView({super.key});

  @override
  State<RecentVoiceMemosView> createState() => _RecentVoiceMemosViewState();
}

final class _RecentVoiceMemosViewState extends State<RecentVoiceMemosView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemoViewModel>().loadMemos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MemoViewModel>();
    final recordings = viewModel.memos
        .where((memo) => memo.isVoiceMemo)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '최근 녹음',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.refreshMemos(),
        child: viewModel.isLoading && recordings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : recordings.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Icon(Icons.mic_none, size: 52),
                      SizedBox(height: 12),
                      Center(child: Text('저장된 음성 메모가 없습니다.')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: recordings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _RecentRecordingCard(memo: recordings[index]);
                    },
                  ),
      ),
    );
  }
}

final class _RecentRecordingCard extends StatefulWidget {
  const _RecentRecordingCard({required this.memo});

  final PatientMemo memo;

  @override
  State<_RecentRecordingCard> createState() => _RecentRecordingCardState();
}

final class _RecentRecordingCardState extends State<_RecentRecordingCard> {
  final AudioPlayer _player = AudioPlayer();
  bool _isLoading = false;
  bool _isPrepared = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    try {
      if (!_isPrepared) {
        setState(() => _isLoading = true);
        final source = await context
            .read<MemoRepository>()
            .audioSource(widget.memo.id);
        await _player.setUrl(source.url, headers: source.headers);
        _isPrepared = true;
      }

      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음성 파일을 재생하지 못했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memo = widget.memo;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return IconButton.filled(
                  onPressed: memo.isVoiceMemo && !_isLoading
                      ? _togglePlayback
                      : null,
                  icon: _isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(playing ? Icons.pause : Icons.play_arrow),
                );
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memo.title.trim().isEmpty ? '음성 메모' : memo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${memo.patientId ?? '환자 정보 없음'} · '
                    '${_durationText(memo.audioDurationSeconds)}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _dateText(memo.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _durationText(int? seconds) {
    if (seconds == null) return '--:--';
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  String _dateText(DateTime? value) {
    if (value == null) return '작성일 정보 없음';
    final local = value.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
