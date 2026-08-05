import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

final class VoiceMemoRecorder {
  VoiceMemoRecorder({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _currentPath;

  String? get currentPath => _currentPath;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<bool> isRecording() => _recorder.isRecording();

  Future<bool> isPaused() => _recorder.isPaused();

  Future<String> start() async {
    if (!await _recorder.hasPermission()) {
      throw const VoiceMemoRecorderException(
        '음성 메모를 녹음하려면 마이크 권한이 필요합니다.',
      );
    }

    await deleteTemporaryFile(_currentPath);

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}${Platform.pathSeparator}'
        'voice_memo_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _currentPath = path;
    return path;
  }

  Future<void> pause() async {
    if (await _recorder.isRecording()) {
      await _recorder.pause();
    }
  }

  Future<void> resume() async {
    if (await _recorder.isPaused()) {
      await _recorder.resume();
    }
  }

  Future<String?> stop() async {
    final path = await _recorder.stop();
    _currentPath = path ?? _currentPath;
    return _currentPath;
  }

  Future<void> cancel() async {
    final path = _currentPath;
    await _recorder.cancel();
    _currentPath = null;
    await deleteTemporaryFile(path);
  }

  Future<void> deleteTemporaryFile(String? path) async {
    final normalizedPath = path?.trim();
    if (normalizedPath == null || normalizedPath.isEmpty) return;

    final file = File(normalizedPath);
    if (await file.exists()) {
      await file.delete();
    }

    if (_currentPath == normalizedPath) {
      _currentPath = null;
    }
  }

  Future<void> dispose() async {
    if (await _recorder.isRecording() || await _recorder.isPaused()) {
      await _recorder.cancel();
    }
    await _recorder.dispose();
  }
}

final class VoiceMemoRecorderException implements Exception {
  const VoiceMemoRecorderException(this.message);

  final String message;

  @override
  String toString() => message;
}
