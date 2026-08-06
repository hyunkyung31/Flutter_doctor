import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/appointment.dart';
import '../repository/appointment_repository.dart';

final class AppointmentViewModel extends ChangeNotifier {
  AppointmentViewModel({
    required AppointmentRepository appointmentRepository,
  }) : _appointmentRepository = appointmentRepository;

  final AppointmentRepository _appointmentRepository;

  final List<Appointment> _appointments = [];

  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  List<Appointment> get appointments => List.unmodifiable(_appointments);

  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  int get todayActiveCount {
    final today = DateUtils.dateOnly(DateTime.now());

    return _appointments.where((appointment) {
      final scheduledDay = DateUtils.dateOnly(appointment.scheduledAt);
      return scheduledDay == today && appointment.isActive;
    }).length;
  }

  List<Appointment> appointmentsForDate(DateTime date) {
    final targetDay = DateUtils.dateOnly(date);

    return _appointments.where((appointment) {
      return DateUtils.dateOnly(appointment.scheduledAt) == targetDay;
    }).toList();
  }

  Future<void> loadAppointments({
    String? date,
    String? status,
  }) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final appointments = await _appointmentRepository.fetchAppointments(
        date: date,
        status: status,
      );

      appointments.sort(
        (left, right) => left.scheduledAt.compareTo(right.scheduledAt),
      );

      _appointments
        ..clear()
        ..addAll(appointments);
    } on AppointmentRepositoryException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '예약 목록을 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAppointments({
    String? date,
    String? status,
  }) async {
    _errorMessage = null;

    try {
      final appointments = await _appointmentRepository.fetchAppointments(
        date: date,
        status: status,
      );

      appointments.sort(
        (left, right) => left.scheduledAt.compareTo(right.scheduledAt),
      );

      _appointments
        ..clear()
        ..addAll(appointments);
    } on AppointmentRepositoryException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '예약 목록을 불러오지 못했습니다.';
    }

    notifyListeners();
  }

  Future<Appointment?> updateStatus({
    required int appointmentId,
    required String status,
  }) async {
    if (_isUpdating) {
      return null;
    }

    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _appointmentRepository.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: status,
      );

      final index = _appointments.indexWhere(
        (appointment) => appointment.id == appointmentId,
      );

      if (index >= 0) {
        _appointments[index] = updated;
      }

      return updated;
    } on AppointmentRepositoryException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = '예약 상태를 변경하지 못했습니다.';
      return null;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}
