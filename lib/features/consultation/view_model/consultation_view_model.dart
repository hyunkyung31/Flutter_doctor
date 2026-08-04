import 'package:flutter/material.dart';

import '../model/consultation_doctor.dart';
import '../repository/consultation_repository.dart';

final class ConsultationViewModel extends ChangeNotifier {
  ConsultationViewModel({
    required ConsultationRepository consultationRepository,
  }) : _consultationRepository = consultationRepository;

  final ConsultationRepository _consultationRepository;

  final List<ConsultationDoctor> _doctors = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<ConsultationDoctor> get doctors {
    return List.unmodifiable(_doctors);
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<String> get departments {
    final values = _doctors
        .map((doctor) => doctor.department.trim())
        .where((department) => department.isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return values;
  }

  List<ConsultationDoctor> doctorsByDepartment(String department) {
    return _doctors.where((doctor) {
      return doctor.department.trim() == department.trim();
    }).toList();
  }

  Future<void> loadDoctors() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doctors = await _consultationRepository.getDoctors();

      _doctors
        ..clear()
        ..addAll(doctors);
    } catch (error) {
      _errorMessage = _cleanErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDoctors() async {
    _errorMessage = null;

    try {
      final doctors = await _consultationRepository.getDoctors();

      _doctors
        ..clear()
        ..addAll(doctors);
    } catch (error) {
      _errorMessage = _cleanErrorMessage(error);
    }

    notifyListeners();
  }

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('ConsultationRepositoryException: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }
}
