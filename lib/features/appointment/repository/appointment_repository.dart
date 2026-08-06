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

  Future<List<Appointment>> fetchAppointments({
    String? date,
    String? status,
  }) async {
    final accessToken = await _accessToken();

    try {
      return await _appointmentService.fetchAppointments(
        accessToken: accessToken,
        date: date,
        status: status,
      );
    } on AppointmentServiceException catch (error) {
      throw AppointmentRepositoryException(error.message);
    }
  }

  Future<Appointment> updateAppointmentStatus({
    required int appointmentId,
    required String status,
  }) async {
    final accessToken = await _accessToken();

    try {
      return await _appointmentService.updateAppointmentStatus(
        accessToken: accessToken,
        appointmentId: appointmentId,
        status: status,
      );
    } on AppointmentServiceException catch (error) {
      throw AppointmentRepositoryException(error.message);
    }
  }

  Future<String> _accessToken() async {
    final accessToken = await _secureStorage.readAccessToken();

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const AppointmentRepositoryException(
        '로그인 정보가 없습니다. 다시 로그인해 주세요.',
      );
    }

    return accessToken;
  }
}

final class AppointmentRepositoryException implements Exception {
  const AppointmentRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
