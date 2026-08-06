import '../../../core/storage/secure_storage.dart';
import '../model/appointment.dart';
import '../service/appointment_service.dart';

final class AppointmentRepository {
  const AppointmentRepository({
    required AppointmentService appointmentService,
    required SecureStorage secureStorage,
  })  : _appointmentService = appointmentService,
        _secureStorage = secureStorage;

  final AppointmentService _appointmentService;
  final SecureStorage _secureStorage;

  Future<String> _requireToken() async {
    final accessToken = await _secureStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const AppointmentRepositoryException(
        '로그인 정보가 없습니다. 다시 로그인해 주세요.',
      );
    }
    return accessToken;
  }

  Future<List<Appointment>> fetchAppointments({
    String? status,
    String? date,
  }) async {
    final accessToken = await _requireToken();
    try {
      return await _appointmentService.fetchAppointments(
        accessToken: accessToken,
        status: status,
        date: date,
      );
    } on AppointmentServiceException catch (error) {
      throw AppointmentRepositoryException(error.message);
    }
  }

  Future<Appointment> updateStatus({
    required String appointmentId,
    required AppointmentStatus status,
  }) async {
    final accessToken = await _requireToken();
    try {
      return await _appointmentService.updateStatus(
        accessToken: accessToken,
        appointmentId: appointmentId,
        status: status,
      );
    } on AppointmentServiceException catch (error) {
      throw AppointmentRepositoryException(error.message);
    }
  }
}

final class AppointmentRepositoryException implements Exception {
  const AppointmentRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
