import 'package:flutter/foundation.dart';

import '../model/consultation_doctor.dart';
import '../model/consultation_request.dart';
import '../repository/consultation_repository.dart';

final class ConsultationViewModel extends ChangeNotifier {
  ConsultationViewModel({
    required ConsultationRepository consultationRepository,
  }) : _consultationRepository = consultationRepository;

  final ConsultationRepository _consultationRepository;

  List<ConsultationDoctor> _doctors =
      <ConsultationDoctor>[];
  List<ConsultationRequest> _receivedRequests = <ConsultationRequest>[];
  List<ConsultationRequest> _sentRequests = <ConsultationRequest>[];

  bool _isLoading = false;
  bool _isRequestsLoading = false;
  bool _isSubmitting = false;

  String? _errorMessage;

  List<ConsultationDoctor> get doctors =>
      List.unmodifiable(_doctors);
  List<ConsultationRequest> get receivedRequests =>
      List.unmodifiable(_receivedRequests);
  List<ConsultationRequest> get sentRequests => List.unmodifiable(_sentRequests);

  bool get isLoading => _isLoading;
  bool get isRequestsLoading => _isRequestsLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  int get pendingCount =>
      _receivedRequests.where((request) => request.isPending).length;
  ConsultationRequest? requestById(String consultationId) {
    for (final request in [..._receivedRequests, ..._sentRequests]) {
      if (request.consultationId == consultationId) {
        return request;
      }
    }

    return null;
  }

  List<String> get departments {
    final values = _doctors
        .map((doctor) => doctor.department.trim())
        .where((department) => department.isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return values;
  }

  List<ConsultationDoctor> doctorsByDepartment(
    String department,
  ) {
    return _doctors
        .where(
          (doctor) => doctor.department == department,
        )
        .toList();
  }

  Future<void> loadDoctors() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _doctors =
          await _consultationRepository.fetchDoctors();
    } on ConsultationRepositoryException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '의사 목록을 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDoctors() async {
    await loadDoctors();
  }

  Future<void> loadReceivedRequests() async {
    if (_isRequestsLoading) {
      return;
    }

    _isRequestsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _receivedRequests =
          await _consultationRepository.fetchReceivedConsultations();
    } on ConsultationRepositoryException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '받은 협진 요청을 불러오지 못했습니다.';
    } finally {
      _isRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshReceivedRequests() async {
    await loadReceivedRequests();
  }

  Future<void> loadAllRequests() async {
    if (_isRequestsLoading) return;

    _isRequestsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _consultationRepository.fetchReceivedConsultations(),
        _consultationRepository.fetchSentConsultations(),
      ]);
      _receivedRequests = results[0];
      _sentRequests = results[1];
    } on ConsultationRepositoryException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '협진 내역을 불러오지 못했습니다.';
    } finally {
      _isRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAllRequests() => loadAllRequests();

  Future<ConsultationRequest?> markAsReviewing(
    String consultationId,
  ) async {
    final request = requestById(consultationId);

    if (request == null) {
      return null;
    }

    if (!request.isPending) {
      return request;
    }

    final success = await updateStatus(
      consultationId: consultationId,
      status: 'in_progress',
    );

    return success ? requestById(consultationId) : null;
  }

  Future<bool> updateStatus({
    required String consultationId,
    required String status,
  }) async {
    final index = _receivedRequests.indexWhere(
      (request) => request.consultationId == consultationId,
    );

    if (index == -1) {
      _errorMessage = '협진 요청을 찾을 수 없습니다.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;

    try {
      final updatedRequest =
          await _consultationRepository.updateConsultationStatus(
        consultationId: consultationId,
        status: status,
      );

      _receivedRequests[index] = updatedRequest;
      notifyListeners();
      return true;
    } on ConsultationRepositoryException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = '협진 상태를 변경하지 못했습니다.';
      notifyListeners();
      return false;
    }
  }
  Future<bool> completeConsultation({
    required String consultationId,
    required String responseMemo,
  }) async {
    final index = _receivedRequests.indexWhere(
      (request) => request.consultationId == consultationId,
    );

    if (index == -1) {
      _errorMessage = '협진 요청을 찾을 수 없습니다.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final updatedRequest =
          await _consultationRepository.completeConsultation(
        consultationId: consultationId,
        responseMemo: responseMemo,
      );

      _receivedRequests[index] = updatedRequest;
      notifyListeners();

      return true;
    } on ConsultationRepositoryException catch (error) {
      _errorMessage = error.message;
      notifyListeners();

      return false;
    } catch (_) {
      _errorMessage = '소견을 전송하지 못했습니다.';
      notifyListeners();

      return false;
    }
  }

  Future<bool> createConsultation({
    required String patientId,
    required String receiverId,
    required String reason,
    required String priority,
    required String memo,
    required List<String> referenceTypes,
    String? examId,
  }) async {
    if (_isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _consultationRepository.createConsultation(
        patientId: patientId,
        receiverId: receiverId,
        reason: reason,
        priority: priority,
        memo: memo,
        referenceTypes: referenceTypes,
        examId: examId,
      );

      return true;
    } on ConsultationRepositoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '협진 요청 전송에 실패했습니다.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
