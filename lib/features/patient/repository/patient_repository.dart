import '../../../core/storage/secure_storage.dart';
import '../model/patient.dart';
import '../service/patient_service.dart';

final class PatientRepository {
  PatientRepository(
    this._patientService,
    this._secureStorage,
  );

  final PatientService _patientService;
  final SecureStorage _secureStorage;

  Future<List<Patient>> getPatients() async {
    final accessToken =
        await _secureStorage.readAccessToken();

    if (accessToken == null ||
        accessToken.trim().isEmpty) {
      throw const PatientRepositoryException(
        '로그인 정보가 없습니다. 다시 로그인해 주세요.',
      );
    }

    return _patientService.fetchPatients(
      accessToken: accessToken,
    );
  }
}

final class PatientRepositoryException
    implements Exception {
  const PatientRepositoryException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}