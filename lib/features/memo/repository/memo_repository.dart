import '../../../core/storage/secure_storage.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/patient_memo.dart';
import '../service/memo_service.dart';

final class MemoRepository {
  const MemoRepository({
    required MemoService memoService,
    required SecureStorage secureStorage,
  })  : _memoService = memoService,
        _secureStorage = secureStorage;

  final MemoService _memoService;
  final SecureStorage _secureStorage;

  Future<List<PatientMemo>> fetchMemos({
    String? patientId,
  }) async {
    final accessToken = await _accessToken();

    try {
      return await _memoService.fetchMemos(
        accessToken: accessToken,
        patientId: patientId,
      );
    } on MemoServiceException catch (error) {
      throw MemoRepositoryException(error.message);
    }
  }

  Future<PatientMemo> fetchMemo({
    required int memoId,
  }) async {
    final accessToken = await _accessToken();

    try {
      return await _memoService.fetchMemo(
        accessToken: accessToken,
        memoId: memoId,
      );
    } on MemoServiceException catch (error) {
      throw MemoRepositoryException(error.message);
    }
  }

  Future<PatientMemo> createTextMemo({
    required String patientId,
    required String title,
    required String content,
    int? examId,
  }) async {
    final accessToken = await _accessToken();

    try {
      return await _memoService.createTextMemo(
        accessToken: accessToken,
        patientId: patientId,
        title: title,
        content: content,
        examId: examId,
      );
    } on MemoServiceException catch (error) {
      throw MemoRepositoryException(error.message);
    }
  }

  Future<PatientMemo> createVoiceMemo({
    required String patientId,
    required String audioPath,
    required int durationSeconds,
    String title = '',
    int? examId,
  }) async {
    final accessToken = await _accessToken();

    try {
      return await _memoService.createVoiceMemo(
        accessToken: accessToken,
        patientId: patientId,
        audioPath: audioPath,
        durationSeconds: durationSeconds,
        title: title,
        examId: examId,
      );
    } on MemoServiceException catch (error) {
      throw MemoRepositoryException(error.message);
    }
  }

  Future<PatientMemo> updateTextMemo({
    required int memoId,
    required String title,
    required String content,
    int? examId,
  }) async {
    final accessToken = await _accessToken();

    try {
      return await _memoService.updateTextMemo(
        accessToken: accessToken,
        memoId: memoId,
        title: title,
        content: content,
        examId: examId,
      );
    } on MemoServiceException catch (error) {
      throw MemoRepositoryException(error.message);
    }
  }

  Future<PatientMemo> updateVoiceMemo({
    required int memoId,
    required String title,
  }) async {
    final accessToken = await _accessToken();

    try {
      return await _memoService.updateVoiceMemo(
        accessToken: accessToken,
        memoId: memoId,
        title: title,
      );
    } on MemoServiceException catch (error) {
      throw MemoRepositoryException(error.message);
    }
  }

  Future<MemoAudioSource> audioSource(int memoId) async {
    final accessToken = await _accessToken();
    return MemoAudioSource(
      url: '${ApiEndpoints.baseUrl}${ApiEndpoints.memoAudio(memoId)}',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  Future<void> deleteMemo({
    required int memoId,
  }) async {
    final accessToken = await _accessToken();

    try {
      await _memoService.deleteMemo(
        accessToken: accessToken,
        memoId: memoId,
      );
    } on MemoServiceException catch (error) {
      throw MemoRepositoryException(error.message);
    }
  }

  Future<String> _accessToken() async {
    final accessToken = await _secureStorage.readAccessToken();

    if (accessToken == null ||
        accessToken.trim().isEmpty) {
      throw const MemoRepositoryException(
        '로그인 정보가 없습니다. 다시 로그인해 주세요.',
      );
    }

    return accessToken.trim();
  }
}

final class MemoRepositoryException implements Exception {
  const MemoRepositoryException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}

final class MemoAudioSource {
  const MemoAudioSource({required this.url, required this.headers});

  final String url;
  final Map<String, String> headers;
}
