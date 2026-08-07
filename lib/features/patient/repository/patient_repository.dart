import '../../../core/storage/secure_storage.dart';

import '../model/patient.dart';
import '../model/patient_detail.dart';
import '../service/patient_service.dart';

final class PatientRepository {
  PatientRepository({
    required PatientService patientService,
    required SecureStorage secureStorage,
  }) : _patientService = patientService,
       _secureStorage = secureStorage;

  final PatientService _patientService;
  final SecureStorage _secureStorage;

  Future<List<Patient>> getPatients() async {
    final accessToken = await _secureStorage.readAccessToken();

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const PatientRepositoryException('로그인이 필요합니다.');
    }

    try {
      return await _patientService.fetchPatients(accessToken: accessToken);
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (error) {
      throw const PatientRepositoryException('환자 목록을 불러오지 못했습니다.');
    }
  }

  Future<PatientDetail> getPatientDetail(String patientId) async {
    final accessToken = await _secureStorage.readAccessToken();

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const PatientRepositoryException('로그인이 필요합니다.');
    }

    try {
      return await _patientService.fetchPatientDetail(
        patientId: patientId,
        accessToken: accessToken,
      );
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (error) {
      throw const PatientRepositoryException('환자 상세 정보를 불러오지 못했습니다.');
    }
  }
}

final class PatientRepositoryException implements Exception {
  const PatientRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
