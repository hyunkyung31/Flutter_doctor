import 'package:flutter/foundation.dart';

import '../model/patient.dart';
import '../repository/patient_repository.dart';
import '../service/patient_service.dart';

final class PatientListViewModel extends ChangeNotifier {
  PatientListViewModel(
    this._patientRepository,
  );

  final PatientRepository _patientRepository;

  List<Patient> _patients = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Patient> get patients => _patients;

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
      _patients = await _patientRepository.getPatients();
    } on PatientServiceException catch (error) {
      _patients = [];
      _errorMessage = error.message;
    } on PatientRepositoryException catch (error) {
      _patients = [];
      _errorMessage = error.message;
    } on Exception catch (error) {
      debugPrint('환자 ViewModel 오류: $error');

      _patients = [];
      _errorMessage = '환자 목록을 불러오는 중 오류가 발생했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPatients() {
    return loadPatients();
  }
}