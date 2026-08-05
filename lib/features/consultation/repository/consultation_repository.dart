import '../../../core/storage/secure_storage.dart';
import '../model/consultation_doctor.dart';
import '../model/consultation_request.dart';
import '../service/consultation_service.dart';

final class ConsultationRepository {
  const ConsultationRepository({
    required ConsultationService consultationService,
    required SecureStorage secureStorage,
  })  : _consultationService = consultationService,
        _secureStorage = secureStorage;

  final ConsultationService _consultationService;
  final SecureStorage _secureStorage;

  Future<List<ConsultationDoctor>> fetchDoctors() async {
    final accessToken = await _secureStorage.readAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw const ConsultationRepositoryException(
        '로그인 정보가 없습니다. 다시 로그인해 주세요.',
      );
    }

    try {
      return await _consultationService.fetchDoctors(
        accessToken: accessToken,
      );
    } on ConsultationServiceException catch (error) {
      throw ConsultationRepositoryException(error.message);
    }
  }

  Future<void> createConsultation({
    required String patientId,
    required String receiverId,
    required String reason,
    required String priority,
    required String memo,
    required List<String> referenceTypes,
    String? examId,
  }) async {
    final accessToken = await _secureStorage.readAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw const ConsultationRepositoryException(
        '로그인 정보가 없습니다. 다시 로그인해 주세요.',
      );
    }

    try {
      await _consultationService.createConsultation(
        accessToken: accessToken,
        patientId: patientId,
        receiverId: receiverId,
        reason: reason,
        priority: priority,
        memo: memo,
        referenceTypes: referenceTypes,
        examId: examId,
      );
    } on ConsultationServiceException catch (error) {
      throw ConsultationRepositoryException(error.message);
    }
  }

  Future<List<ConsultationRequest>> fetchReceivedConsultations() async {
    final accessToken = await _secureStorage.readAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw const ConsultationRepositoryException(
        '로그인 정보가 없습니다. 다시 로그인해 주세요.',
      );
    }

    try {
      return await _consultationService.fetchReceivedConsultations(
        accessToken: accessToken,
      );
    } on ConsultationServiceException catch (error) {
      throw ConsultationRepositoryException(error.message);
    }
  }

  Future<ConsultationRequest> updateConsultationStatus({
    required String consultationId,
    required String status,
  }) async {
    final accessToken = await _secureStorage.readAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw const ConsultationRepositoryException(
        '로그인 정보가 없습니다. 다시 로그인해 주세요.',
      );
    }

    try {
      return await _consultationService.updateConsultationStatus(
        accessToken: accessToken,
        consultationId: consultationId,
        status: status,
      );
    } on ConsultationServiceException catch (error) {
      throw ConsultationRepositoryException(error.message);
    }
  }

  Future<List<ConsultationRequest>> fetchSentConsultations() async {
    final accessToken = await _secureStorage.readAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw const ConsultationRepositoryException(
        '로그인 정보가 없습니다. 다시 로그인해 주세요.',
      );
    }

    try {
      return await _consultationService.fetchSentConsultations(
        accessToken: accessToken,
      );
    } on ConsultationServiceException catch (error) {
      throw ConsultationRepositoryException(error.message);
    }
  }

  Future<ConsultationRequest> completeConsultation({
    required String consultationId,
    required String responseMemo,
  }) async {
    final accessToken = await _secureStorage.readAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw const ConsultationRepositoryException(
        '로그인 정보가 없습니다. 다시 로그인해 주세요.',
      );
    }

    try {
      return await _consultationService.completeConsultation(
        accessToken: accessToken,
        consultationId: consultationId,
        responseMemo: responseMemo,
      );
    } on ConsultationServiceException catch (error) {
      throw ConsultationRepositoryException(error.message);
    }
  }
}

final class ConsultationRepositoryException implements Exception {
  const ConsultationRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
