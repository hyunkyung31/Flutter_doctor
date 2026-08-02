import 'package:flutter/material.dart';

import '../model/patient.dart';
import '../repository/patient_repository.dart';

final class PatientListViewModel
    extends ChangeNotifier {
  PatientListViewModel({
    required PatientRepository patientRepository,
  }) : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  final List<Patient> _patients = [];
  final List<Patient> _recentPatients = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Patient> get patients {
    return List.unmodifiable(_patients);
  }

  List<Patient> get recentPatients {
    return List.unmodifiable(_recentPatients);
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> loadPatients() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final patients =
          await _patientRepository.getPatients();

      _patients
        ..clear()
        ..addAll(patients);
    } catch (error) {
      _errorMessage = _cleanErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPatients() async {
    _errorMessage = null;

    try {
      final patients =
          await _patientRepository.getPatients();

      _patients
        ..clear()
        ..addAll(patients);
    } catch (error) {
      _errorMessage = _cleanErrorMessage(error);
    }

    notifyListeners();
  }

  void addRecentPatient(Patient patient) {
    _recentPatients.removeWhere(
      (item) =>
          item.patientId == patient.patientId,
    );

    _recentPatients.insert(0, patient);

    if (_recentPatients.length > 10) {
      _recentPatients.removeLast();
    }

    notifyListeners();
  }

  void clearRecentPatients() {
    _recentPatients.clear();
    notifyListeners();
  }

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst(
          'PatientRepositoryException: ',
          '',
        )
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }
}