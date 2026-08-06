import 'package:flutter/foundation.dart';

import '../model/create_emr_sign_off_request.dart';
import '../model/emr_sign_off.dart';
import '../model/update_emr_sign_off_request.dart';
import '../repository/emr_sign_off_repository.dart';

final class EmrSignOffViewModel extends ChangeNotifier {
  EmrSignOffViewModel(this._emrSignOffRepository);

  final EmrSignOffRepository _emrSignOffRepository;

  List<EmrSignOff> _signOffs = const <EmrSignOff>[];
  EmrSignOff? _selectedSignOff;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isGeneratingReport = false;
  bool _isDownloadingReport = false;
  bool _isTransmitting = false;
  String? _errorMessage;

  List<EmrSignOff> get signOffs => List<EmrSignOff>.unmodifiable(_signOffs);

  EmrSignOff? get selectedSignOff => _selectedSignOff;

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  bool get isGeneratingReport => _isGeneratingReport;

  bool get isDownloadingReport => _isDownloadingReport;

  bool get isTransmitting => _isTransmitting;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  bool get isBusy {
    return _isLoading ||
        _isSubmitting ||
        _isGeneratingReport ||
        _isDownloadingReport ||
        _isTransmitting;
  }

  EmrSignOff? findSignOffByExamId({
    required String patientId,
    required int examId,
  }) {
    final normalizedPatientId = patientId.trim();

    if (normalizedPatientId.isEmpty || examId <= 0) {
      return null;
    }

    for (final signOff in _signOffs) {
      final signOffExamId = signOff.aiResult?.examId;

      if (signOff.patientId == normalizedPatientId && signOffExamId == examId) {
        return signOff;
      }
    }

    return null;
  }

  bool hasSignOffForExam({required String patientId, required int examId}) {
    return findSignOffByExamId(patientId: patientId, examId: examId) != null;
  }

  bool isExamFinalized({required String patientId, required int examId}) {
    final signOff = findSignOffByExamId(patientId: patientId, examId: examId);

    return signOff?.finalized ?? false;
  }

  Future<bool> loadSignOffs() async {
    if (_isLoading) {
      return false;
    }

    _setLoading(true);
    _clearError(notify: false);

    try {
      _signOffs = await _emrSignOffRepository.fetchEmrSignOffs();
      return true;
    } on EmrSignOffRepositoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '임상 보고서 목록을 불러오지 못했습니다.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loadSignOff({required int signOffId}) async {
    if (_isLoading) {
      return false;
    }

    _setLoading(true);
    _clearError(notify: false);

    try {
      final signOff = await _emrSignOffRepository.fetchEmrSignOff(
        signOffId: signOffId,
      );

      _selectedSignOff = signOff;
      _replaceOrInsert(signOff);

      return true;
    } on EmrSignOffRepositoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '임상 보고서를 불러오지 못했습니다.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<EmrSignOff?> createSignOff({
    required CreateEmrSignOffRequest request,
  }) async {
    if (_isSubmitting) {
      return null;
    }

    _setSubmitting(true);
    _clearError(notify: false);

    try {
      final signOff = await _emrSignOffRepository.createEmrSignOff(
        request: request,
      );

      _selectedSignOff = signOff;
      _replaceOrInsert(signOff);

      return signOff;
    } on EmrSignOffRepositoryException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = '의료진 소견을 저장하지 못했습니다.';
      return null;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<EmrSignOff?> updateSignOff({
    required int signOffId,
    required UpdateEmrSignOffRequest request,
  }) async {
    if (_isSubmitting) {
      return null;
    }

    _setSubmitting(true);
    _clearError(notify: false);

    try {
      final signOff = await _emrSignOffRepository.updateEmrSignOff(
        signOffId: signOffId,
        request: request,
      );

      _selectedSignOff = signOff;
      _replaceOrInsert(signOff);

      return signOff;
    } on EmrSignOffRepositoryException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = '의료진 소견을 수정하지 못했습니다.';
      return null;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<EmrSignOff?> generateReport({required int signOffId}) async {
    if (_isGeneratingReport) {
      return null;
    }

    _setGeneratingReport(true);
    _clearError(notify: false);

    try {
      final signOff = await _emrSignOffRepository.generateReport(
        signOffId: signOffId,
      );

      _selectedSignOff = signOff;
      _replaceOrInsert(signOff);

      return signOff;
    } on EmrSignOffRepositoryException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = '임상 보고서 PDF를 생성하지 못했습니다.';
      return null;
    } finally {
      _setGeneratingReport(false);
    }
  }

  Future<Uint8List?> downloadReport({required int signOffId}) async {
    if (_isDownloadingReport) {
      return null;
    }

    _setDownloadingReport(true);
    _clearError(notify: false);

    try {
      return await _emrSignOffRepository.downloadReport(signOffId: signOffId);
    } on EmrSignOffRepositoryException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = '임상 보고서 PDF를 다운로드하지 못했습니다.';
      return null;
    } finally {
      _setDownloadingReport(false);
    }
  }

  Future<EmrSignOff?> transmitReport({required int signOffId}) async {
    if (_isTransmitting) {
      return null;
    }

    _setTransmitting(true);
    _clearError(notify: false);

    try {
      final signOff = await _emrSignOffRepository.transmitReport(
        signOffId: signOffId,
      );

      _selectedSignOff = signOff;
      _replaceOrInsert(signOff);

      return signOff;
    } on EmrSignOffRepositoryException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = '임상 보고서를 전달하지 못했습니다.';
      return null;
    } finally {
      _setTransmitting(false);
    }
  }

  void selectSignOff(EmrSignOff? signOff) {
    if (identical(_selectedSignOff, signOff)) {
      return;
    }

    _selectedSignOff = signOff;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  void _replaceOrInsert(EmrSignOff signOff) {
    final index = _signOffs.indexWhere((item) => item.id == signOff.id);

    if (index < 0) {
      _signOffs = <EmrSignOff>[signOff, ..._signOffs];
      return;
    }

    final updatedItems = List<EmrSignOff>.of(_signOffs);
    updatedItems[index] = signOff;
    _signOffs = updatedItems;
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    if (_isSubmitting == value) {
      return;
    }

    _isSubmitting = value;
    notifyListeners();
  }

  void _setGeneratingReport(bool value) {
    if (_isGeneratingReport == value) {
      return;
    }

    _isGeneratingReport = value;
    notifyListeners();
  }

  void _setDownloadingReport(bool value) {
    if (_isDownloadingReport == value) {
      return;
    }

    _isDownloadingReport = value;
    notifyListeners();
  }

  void _setTransmitting(bool value) {
    if (_isTransmitting == value) {
      return;
    }

    _isTransmitting = value;
    notifyListeners();
  }

  void _clearError({bool notify = true}) {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;

    if (notify) {
      notifyListeners();
    }
  }
}
