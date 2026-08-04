import '../../../core/storage/secure_storage.dart';

import '../model/consultation_doctor.dart';
import '../service/consultation_service.dart';

final class ConsultationRepository {
  ConsultationRepository({
    required ConsultationService consultationService,
    required SecureStorage secureStorage,
  }) : _consultationService = consultationService,
       _secureStorage = secureStorage;

  final ConsultationService _consultationService;
  final SecureStorage _secureStorage;

  Future<List<ConsultationDoctor>> getDoctors() async {
    final accessToken = await _secureStorage.readAccessToken();

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const ConsultationRepositoryException('로그인이 필요합니다.');
    }

    try {
      return await _consultationService.fetchDoctors(accessToken: accessToken);
    } on ConsultationServiceException catch (error) {
      throw ConsultationRepositoryException(error.message);
    } catch (error) {
      throw const ConsultationRepositoryException('의사 목록을 불러오지 못했습니다.');
    }
  }
}

final class ConsultationRepositoryException implements Exception {
  const ConsultationRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
