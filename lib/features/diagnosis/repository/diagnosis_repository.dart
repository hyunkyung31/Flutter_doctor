import '../../../core/storage/secure_storage.dart';
import '../../ai_result/model/integrated_analysis_result.dart';
import '../service/diagnosis_service.dart';

final class DiagnosisRepository {
  DiagnosisRepository(
    this._diagnosisService,
    this._secureStorage,
  );

  final DiagnosisService _diagnosisService;
  final SecureStorage _secureStorage;

  Future<IntegratedAnalysisResult> runIntegratedAnalysis({
    required int examId,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
  }) async {
    final accessToken =   //로그인 시 저장한 accessToken 조회
        await _secureStorage.readAccessToken();

    final normalizedAccessToken =   // 토큰 정규화
        accessToken?.trim();

    if (normalizedAccessToken == null ||
        normalizedAccessToken.isEmpty) {
      throw const DiagnosisRepositoryException(
        '로그인이 필요합니다.',
      );
    }

    try {
      return await _diagnosisService
          .runIntegratedAnalysis(
        examId: examId,
        accessToken: normalizedAccessToken,
        confidenceThreshold:
            confidenceThreshold,
        iouThreshold: iouThreshold,
      );
    } on DiagnosisServiceException catch (error) {
      throw DiagnosisRepositoryException(
        error.message,
      );
    } catch (_) {
      throw const DiagnosisRepositoryException(
        '통합 AI 분석을 완료하지 못했습니다.',
      );
    }
  }
}

final class DiagnosisRepositoryException
    implements Exception {
  const DiagnosisRepositoryException(
    this.message,
  );

  final String message;

  @override
  String toString() {
    return message;
  }
}