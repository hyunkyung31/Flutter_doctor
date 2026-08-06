import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../model/appointment.dart';
import '../repository/appointment_repository.dart';

final class AppointmentViewModel extends ChangeNotifier {
  AppointmentViewModel({
    required AppointmentRepository appointmentRepository,
  }) : _appointmentRepository = appointmentRepository;

  final AppointmentRepository _appointmentRepository;

  List<Appointment> _appointments = <Appointment>[];
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  /// 오늘 기준 신청/확정 예약 수 (홈 현황 카드)
  int get activeTodayCount {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _appointments.where((item) {
      if (!item.isActive) return false;
      return DateFormat('yyyy-MM-dd').format(item.scheduledAt) == today;
    }).length;
  }

  /// 신청+확정 전체 (오늘이 아니어도 포함)
  int get activeCount =>
      _appointments.where((item) => item.isActive).length;

  Future<void> loadAppointments({bool todayOnly = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final date = todayOnly
          ? DateFormat('yyyy-MM-dd').format(DateTime.now())
          : null;
      _appointments = await _appointmentRepository.fetchAppointments(
        date: date,
      );
    } on AppointmentRepositoryException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '예약 목록을 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirm(String appointmentId) {
    return _changeStatus(appointmentId, AppointmentStatus.confirmed);
  }

  Future<bool> complete(String appointmentId) {
    return _changeStatus(appointmentId, AppointmentStatus.completed);
  }

  Future<bool> cancel(String appointmentId) {
    return _changeStatus(appointmentId, AppointmentStatus.cancelled);
  }

  Future<bool> _changeStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    if (_isUpdating) return false;

    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _appointmentRepository.updateStatus(
        appointmentId: appointmentId,
        status: status,
      );
      final index =
          _appointments.indexWhere((item) => item.id == appointmentId);
      if (index >= 0) {
        _appointments = List<Appointment>.from(_appointments)
          ..[index] = updated;
      } else {
        await loadAppointments();
      }
      return true;
    } on AppointmentRepositoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '예약 상태 변경에 실패했습니다.';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}
