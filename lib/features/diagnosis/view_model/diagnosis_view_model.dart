import 'package:flutter/material.dart';
import '../../ai_result/model/integrated_analysis_result.dart';
import '../../patient/model/patient.dart';
import '../../patient/repository/patient_repository.dart';
import '../model/ai_analysis_type.dart';
import '../model/diagnosis_entry_args.dart';
import '../model/diagnosis_examination.dart';
import '../model/diagnosis_phase.dart';
import '../repository/diagnosis_repository.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';

final class DiagnosisViewModel extends ChangeNotifier {
  DiagnosisViewModel(
    this._diagnosisRepository,
    this._patientRepository, {
    required this._secureStorage,
    DiagnosisEntryArgs entryArgs = const DiagnosisEntryArgs(),
  }) : _initialPatientId = entryArgs.normalizedPatientId,
       _patientId = entryArgs.normalizedPatientId,
       _initialExamId = entryArgs.examId;

  final DiagnosisRepository _diagnosisRepository;
  final PatientRepository _patientRepository;
  final SecureStorage _secureStorage;

  final String? _initialPatientId;
  final int? _initialExamId;

  String? _patientId;
  Patient? _selectedPatient;
  String? _accessToken;

  List<DiagnosisExamination> _examinations = const <DiagnosisExamination>[];

  DiagnosisExamination? _selectedExamination;
  AiAnalysisType? _selectedAnalysisType;
  DiagnosisPhase _phase = DiagnosisPhase.idle;
  IntegratedAnalysisResult? _analysisResult;
  String? _errorMessage;

  bool _showBoundingBox = false;
  bool _showHeatmap = false;
  bool _isLoadingExaminations = false;
  bool _isDisposed = false;

  int _patientLoadRequestId = 0;
  bool _hasAppliedInitialExamId = false;

  String? get patientId {
    return _patientId;
  }

  Patient? get selectedPatient {
    return _selectedPatient;
  }

  bool get hasSelectedPatient {
    return _selectedPatient != null && _patientId != null;
  }

  bool get isLoadingExaminations {
    return _isLoadingExaminations;
  }

  int? get initialExamId {
    return _initialExamId;
  }

  List<DiagnosisExamination> get examinations {
    return _examinations;
  }

  DiagnosisExamination? get selectedExamination {
    return _selectedExamination;
  }

  AiAnalysisType? get selectedAnalysisType {
    return _selectedAnalysisType;
  }

  DiagnosisPhase get phase {
    return _phase;
  }

  IntegratedAnalysisResult? get analysisResult {
    return _analysisResult;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  // 인증이 필요한 이미지 요청에 사용할 HTTP 헤더를 반환한다.
  Map<String, String> get mediaHeaders {
    final token = _accessToken?.trim();

    if (token == null || token.isEmpty) {
      return const <String, String>{'Accept': '*/*'};
    }

    return <String, String>{'Authorization': 'Bearer $token', 'Accept': '*/*'};
  }

  String resolveMediaUrl(String? value) {
    final mediaPath = value?.trim() ?? '';

    if (mediaPath.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(mediaPath);

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return mediaPath;
    }

    final configuredBaseUrl = ApiEndpoints.baseUrl.trim();

    if (configuredBaseUrl.isEmpty) {
      return mediaPath;
    }

    final baseUrl = configuredBaseUrl.endsWith('/')
        ? configuredBaseUrl.substring(0, configuredBaseUrl.length - 1)
        : configuredBaseUrl;

    // GCS 내부 경로는 Django 미디어 중계 API 주소로 변환한다.
    if (mediaPath.startsWith('gs://')) {
      final encodedPath = Uri.encodeQueryComponent(mediaPath);

      return '$baseUrl/api/media/gcs/?path=$encodedPath';
    }

    if (mediaPath.startsWith('/')) {
      return '$baseUrl$mediaPath';
    }

    return '$baseUrl/$mediaPath';
  }

  bool get showBoundingBox {
    return _showBoundingBox;
  }

  bool get showHeatmap {
    return _showHeatmap;
  }

  bool get isBusy {
    return _phase.isBusy;
  }

  bool get hasCompletedAnalysis {
    return _phase.hasCompletedAnalysis && _analysisResult != null;
  }

  bool get canRunAnalysis {
    final examination = _selectedExamination;

    return !isBusy &&
        !_isLoadingExaminations &&
        examination != null &&
        examination.canRunIntegratedAnalysis &&
        _selectedAnalysisType != null;
  }

  Future<void> initialize() async {
    if (_phase != DiagnosisPhase.idle) {
      return;
    }

    _phase = DiagnosisPhase.selecting;
    _notifyListeners();

    await _loadMediaAccessToken();

    final initialPatientId = _initialPatientId;

    if (initialPatientId != null) {
      await loadPatient(initialPatientId);
    }
  }

  Future<void> selectPatient(Patient patient) async {
    await loadPatient(patient.patientId, patient: patient);
  }

  Future<void> loadPatient(String patientId, {Patient? patient}) async {
    if (isBusy) {
      return;
    }

    final normalizedPatientId = _normalizeString(patientId);

    if (normalizedPatientId == null) {
      _setFailure('환자 ID가 올바르지 않습니다.');
      return;
    }

    final requestId = ++_patientLoadRequestId;

    _patientId = normalizedPatientId;
    _selectedPatient = patient;
    _isLoadingExaminations = true;
    _examinations = const <DiagnosisExamination>[];
    _selectedExamination = null;

    _clearAnalysisState();
    _phase = DiagnosisPhase.selecting;
    _notifyListeners();

    try {
      final patientDetail = await _patientRepository.getPatientDetail(
        normalizedPatientId,
      );

      if (_isDisposed || requestId != _patientLoadRequestId) {
        return;
      }

      final resolvedPatientId =
          _normalizeString(patientDetail.patient.patientId) ??
          normalizedPatientId;

      final examinations = _convertExaminations(
        patientDetail.examinations,
        patientId: resolvedPatientId,
      );

      _patientId = resolvedPatientId;
      _selectedPatient = patientDetail.patient;
      _examinations = List<DiagnosisExamination>.unmodifiable(examinations);

      _applyInitialExamination();
      _updateSelectionPhase();
    } catch (error) {
      if (_isDisposed || requestId != _patientLoadRequestId) {
        return;
      }

      _examinations = const <DiagnosisExamination>[];
      _selectedExamination = null;
      _analysisResult = null;
      _errorMessage = _cleanErrorMessage(error);
      _phase = DiagnosisPhase.failed;
    } finally {
      if (!_isDisposed && requestId == _patientLoadRequestId) {
        _isLoadingExaminations = false;
        _notifyListeners();
      }
    }
  }

  Future<void> refreshSelectedPatient() async {
    final currentPatientId = _patientId;

    if (currentPatientId == null) {
      _setFailure('선택된 환자가 없습니다.');
      return;
    }

    await loadPatient(currentPatientId, patient: _selectedPatient);
  }

  void setExaminations(Iterable<DiagnosisExamination> examinations) {
    if (isBusy) {
      return;
    }

    _examinations = List<DiagnosisExamination>.unmodifiable(examinations);

    final currentExamId = _selectedExamination?.examId;

    if (currentExamId != null) {
      _selectedExamination = _findExamination(currentExamId);
    }

    if (_selectedExamination == null) {
      _applyInitialExamination();
    }

    _clearAnalysisState();
    _updateSelectionPhase();
    _notifyListeners();
  }

  void selectExamination(DiagnosisExamination? examination) {
    if (isBusy || _selectedExamination?.examId == examination?.examId) {
      return;
    }

    _selectedExamination = examination;

    final examinationPatientId = _normalizeString(examination?.patientId);

    if (examinationPatientId != null) {
      _patientId = examinationPatientId;
    }

    _clearAnalysisState();
    _updateSelectionPhase();
    _notifyListeners();
  }

  void selectAnalysisType(AiAnalysisType analysisType) {
    if (isBusy || _selectedAnalysisType == analysisType) {
      return;
    }

    _selectedAnalysisType = analysisType;

    _clearAnalysisState();
    _updateSelectionPhase();
    _notifyListeners();
  }

  Future<void> runAnalysis() async {
    if (isBusy) {
      return;
    }

    final examination = _selectedExamination;
    final analysisType = _selectedAnalysisType;

    if (examination == null) {
      _setFailure('분석할 검사를 선택해 주세요.');
      return;
    }

    if (analysisType == null) {
      _setFailure('확인할 분석 결과 유형을 선택해 주세요.');
      return;
    }

    if (!examination.canRunIntegratedAnalysis) {
      _setFailure('키프레임이 있는 검사만 AI 분석을 실행할 수 있습니다.');
      return;
    }

    _phase = DiagnosisPhase.submitting;
    _analysisResult = null;
    _errorMessage = null;
    _applyDefaultOverlayState();
    _notifyListeners();

    try {
      final result = await _diagnosisRepository.runIntegratedAnalysis(
        examId: examination.examId,
      );

      await _loadMediaAccessToken();

      if (_isDisposed) {
        return;
      }

      _analysisResult = result;

      _showBoundingBox = false; //분석 직후에는 원본 영상표시, 의료진이 직접 박스,grad-cam 선택

      _showHeatmap = false;

      _phase = DiagnosisPhase.completed;
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      _analysisResult = null;
      _errorMessage = _cleanErrorMessage(error);
      _phase = DiagnosisPhase.failed;
    }

    _notifyListeners();
  }

  Future<void> retryAnalysis() async {
    await runAnalysis();
  }

  void showOriginalMedia() {
    if (!_showBoundingBox && !_showHeatmap) {
      return;
    }

    _showBoundingBox = false;
    _showHeatmap = false;
    _notifyListeners();
  }

  void setBoundingBoxVisible(bool visible) {
    final analysisType = _selectedAnalysisType;
    final result = _analysisResult;

    if (analysisType == null || !analysisType.supportsBoundingBox) {
      return;
    }

    if (visible && (result == null || !result.canShowBoundingBox)) {
      return;
    }

    final nextShowBoundingBox = visible;
    final nextShowHeatmap = visible ? false : _showHeatmap;

    if (_showBoundingBox == nextShowBoundingBox &&
        _showHeatmap == nextShowHeatmap) {
      return;
    }

    _showBoundingBox = nextShowBoundingBox;
    _showHeatmap = nextShowHeatmap;
    _notifyListeners();
  }

  void setHeatmapVisible(bool visible) {
    final analysisType = _selectedAnalysisType;
    final result = _analysisResult;

    if (analysisType == null || !analysisType.supportsHeatmap) {
      return;
    }

    if (visible && (result == null || !result.canShowHeatmap)) {
      return;
    }

    final nextShowHeatmap = visible;
    final nextShowBoundingBox = visible ? false : _showBoundingBox;

    if (_showHeatmap == nextShowHeatmap &&
        _showBoundingBox == nextShowBoundingBox) {
      return;
    }

    _showHeatmap = nextShowHeatmap;
    _showBoundingBox = nextShowBoundingBox;
    _notifyListeners();
  }

  void clearAnalysisResult() {
    if (isBusy) {
      return;
    }

    _clearAnalysisState();
    _updateSelectionPhase();
    _notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;

    if (_phase == DiagnosisPhase.failed) {
      _updateSelectionPhase();
    }

    _notifyListeners();
  }

  void reset() {
    if (isBusy) {
      return;
    }

    ++_patientLoadRequestId;

    _patientId = null;
    _selectedPatient = null;
    _examinations = const <DiagnosisExamination>[];
    _selectedExamination = null;
    _selectedAnalysisType = null;
    _analysisResult = null;
    _errorMessage = null;
    _showBoundingBox = false;
    _showHeatmap = false;
    _isLoadingExaminations = false;
    _hasAppliedInitialExamId = true;
    _phase = DiagnosisPhase.selecting;

    _notifyListeners();
  }

  List<DiagnosisExamination> _convertExaminations(
    List<Map<String, dynamic>> values, {
    required String patientId,
  }) {
    final examinations = <DiagnosisExamination>[];

    for (var index = 0; index < values.length; index++) {
      final data = Map<String, dynamic>.from(values[index]);

      final examinationPatientId = _normalizeString(
        data['patient_id']?.toString() ?? data['patientId']?.toString(),
      );

      if (examinationPatientId == null) {
        data['patient_id'] = patientId;
      }

      try {
        examinations.add(DiagnosisExamination.fromJson(data));
      } on FormatException catch (error) {
        throw DiagnosisViewModelException(
          '검사 목록의 ${index + 1}번째 데이터가 올바르지 않습니다. '
          '${error.message}',
        );
      }
    }

    return examinations;
  }

  void _applyInitialExamination() {
    if (_hasAppliedInitialExamId || _initialExamId == null) {
      return;
    }

    if (_initialPatientId != null && _patientId != _initialPatientId) {
      return;
    }

    final examination = _findExamination(_initialExamId);

    if (examination == null) {
      return;
    }

    _selectedExamination = examination;
    _hasAppliedInitialExamId = true;
  }

  DiagnosisExamination? _findExamination(int examId) {
    for (final examination in _examinations) {
      if (examination.examId == examId) {
        return examination;
      }
    }

    return null;
  }

  void _clearAnalysisState() {
    _analysisResult = null;
    _errorMessage = null;
    _applyDefaultOverlayState();
  }

  Future<void> _loadMediaAccessToken() async {
    final token = await _secureStorage.readAccessToken();

    final normalizedToken = token?.trim();

    _accessToken = normalizedToken == null || normalizedToken.isEmpty
        ? null
        : normalizedToken;
  }

  void _applyDefaultOverlayState() {
    _showBoundingBox = false;
    _showHeatmap = false;
  }

  void _updateSelectionPhase() {
    if (isBusy) {
      return;
    }

    if (_selectedExamination != null && _selectedAnalysisType != null) {
      _phase = DiagnosisPhase.ready;
      return;
    }

    _phase = DiagnosisPhase.selecting;
  }

  void _setFailure(String message) {
    _analysisResult = null;
    _errorMessage = message;
    _phase = DiagnosisPhase.failed;
    _notifyListeners();
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString().trim();

    if (message.isEmpty) {
      return 'AI 분석 화면 데이터를 불러오는 중 오류가 발생했습니다.';
    }

    return message
        .replaceFirst('DiagnosisRepositoryException: ', '')
        .replaceFirst('PatientRepositoryException: ', '')
        .replaceFirst('DiagnosisViewModelException: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }

  String? _normalizeString(String? value) {
    final normalizedValue = value?.trim();

    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }

    return normalizedValue;
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

final class DiagnosisViewModelException implements Exception {
  const DiagnosisViewModelException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
