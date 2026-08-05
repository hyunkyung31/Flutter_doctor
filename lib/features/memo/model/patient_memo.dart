enum PatientMemoType {
  text,
  voice;

  static PatientMemoType fromValue(dynamic value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'voice' => PatientMemoType.voice,
      _ => PatientMemoType.text,
    };
  }

  String get value {
    return switch (this) {
      PatientMemoType.text => 'text',
      PatientMemoType.voice => 'voice',
    };
  }
}

enum MemoTranscriptionStatus {
  none,
  processing,
  completed,
  failed;

  static MemoTranscriptionStatus fromValue(dynamic value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'processing' => MemoTranscriptionStatus.processing,
      'completed' => MemoTranscriptionStatus.completed,
      'failed' => MemoTranscriptionStatus.failed,
      _ => MemoTranscriptionStatus.none,
    };
  }

  String get value {
    return switch (this) {
      MemoTranscriptionStatus.none => 'none',
      MemoTranscriptionStatus.processing => 'processing',
      MemoTranscriptionStatus.completed => 'completed',
      MemoTranscriptionStatus.failed => 'failed',
    };
  }
}

final class PatientMemo {
  const PatientMemo({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.examId,
    required this.memoType,
    required this.title,
    required this.content,
    required this.audioUrl,
    required this.audioDurationSeconds,
    required this.transcript,
    required this.transcriptionStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String doctorId;
  final String? patientId;
  final int? examId;
  final PatientMemoType memoType;
  final String title;
  final String content;
  final String audioUrl;
  final int? audioDurationSeconds;
  final String transcript;
  final MemoTranscriptionStatus transcriptionStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isTextMemo {
    return memoType == PatientMemoType.text;
  }

  bool get isVoiceMemo {
    return memoType == PatientMemoType.voice;
  }

  bool get hasAudio {
    return audioUrl.trim().isNotEmpty;
  }

  bool get hasTranscript {
    return transcript.trim().isNotEmpty;
  }

  String get displayContent {
    if (content.trim().isNotEmpty) {
      return content.trim();
    }

    if (transcript.trim().isNotEmpty) {
      return transcript.trim();
    }

    return isVoiceMemo ? '음성 메모' : '작성된 내용이 없습니다.';
  }

  factory PatientMemo.fromJson(Map<String, dynamic> json) {
    return PatientMemo(
      id: _intValue(json['id']) ?? 0,
      doctorId: _stringValue(
        json['doctor_id'] ?? json['doctorId'],
      ),
      patientId: _nullableStringValue(
        json['patient_id'] ?? json['patientId'],
      ),
      examId: _intValue(
        json['exam_id'] ?? json['examId'],
      ),
      memoType: PatientMemoType.fromValue(
        json['memo_type'] ?? json['memoType'],
      ),
      title: _stringValue(json['title']),
      content: _stringValue(json['content']),
      audioUrl: _stringValue(
        json['audio_url'] ?? json['audioUrl'],
      ),
      audioDurationSeconds: _intValue(
        json['audio_duration_seconds'] ??
            json['audioDurationSeconds'],
      ),
      transcript: _stringValue(json['transcript']),
      transcriptionStatus: MemoTranscriptionStatus.fromValue(
        json['transcription_status'] ??
            json['transcriptionStatus'],
      ),
      createdAt: _dateTimeValue(
        json['created_at'] ?? json['createdAt'],
      ),
      updatedAt: _dateTimeValue(
        json['updated_at'] ?? json['updatedAt'],
      ),
    );
  }

  PatientMemo copyWith({
    int? id,
    String? doctorId,
    String? patientId,
    int? examId,
    PatientMemoType? memoType,
    String? title,
    String? content,
    String? audioUrl,
    int? audioDurationSeconds,
    String? transcript,
    MemoTranscriptionStatus? transcriptionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientMemo(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      examId: examId ?? this.examId,
      memoType: memoType ?? this.memoType,
      title: title ?? this.title,
      content: content ?? this.content,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDurationSeconds:
          audioDurationSeconds ?? this.audioDurationSeconds,
      transcript: transcript ?? this.transcript,
      transcriptionStatus:
          transcriptionStatus ?? this.transcriptionStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _stringValue(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _nullableStringValue(dynamic value) {
    final result = value?.toString().trim() ?? '';

    return result.isEmpty ? null : result;
  }

  static int? _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _dateTimeValue(dynamic value) {
    final result = value?.toString().trim() ?? '';

    if (result.isEmpty) {
      return null;
    }

    return DateTime.tryParse(result);
  }
}