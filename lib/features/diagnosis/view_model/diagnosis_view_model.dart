import 'package:flutter/material.dart';

import '../../ai_result/model/integrated_analysis_result.dart';
import '../model/ai_analysis_type.dart';
import '../model/diagnosis_entry_args.dart';
import '../model/diagnosis_examination.dart';
import '../model/diagnosis_phase.dart';
import '../repository/diagnosis_repository.dart';

final class DiagnosisViewModel extends ChangeNotifier {
  DiagnosisViewModel(
    this._diagnosisRepository, {
      DiagnosisEntryArgs entryArgs =
          const DiagnosisEntryArgs(),
  })  : _patientId = entryArgs.normalizedPatientId,
        _initialExamId = entryArgs.examId;

  final DiagnosisRepository _diagnosisRepository;
  final int? _initialExamId;

  String? _patientId;
  List<DiagnosisExamination> _examinations =
      const <DiagnosisExamination>[];
  DiagnosisExamination? _selectedExamination;
  AiAnalysisType? _selectedAnalysisType;
  DiagnosisPhase _phase = DiagnosisPhase.idle;
  IntegratedAnalysisResult? _analysisResult;
  String? _errorMessage;
  bool _showBoundingBox = false;
  bool _showHeatmap = false;
  bool _isDisposed = false;

  String? get patientId {
    return _patientId;
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
    return _phase.hasCompletedAnalysis &&
        _analysisResult != null;
  }

  bool get canRunAnalysis {
    final examination = _selectedExamination;

    return !isBusy &&
        examination != null &&
        examination.canRunIntegratedAnalysis &&
        _selectedAnalysisType != null;
  }

  void initialize() {
    if (_phase != DiagnosisPhase.idle) {
      return;
    }

    _phase = DiagnosisPhase.selecting;
    _notifyListeners();
  }

  void setPatientId(String? patientId) {
    if (isBusy) {
      return;
    }

    final normalizedPatientId =
        _normalizeString(patientId);

    if (_patientId == normalizedPatientId) {
      return;
    }

    _patientId = normalizedPatientId;
    _examinations =
        const <DiagnosisExamination>[];
    _selectedExamination = null;

    _clearAnalysisState();
    _updateSelectionPhase();
    _notifyListeners();
  }

  void setExaminations(
    Iterable<DiagnosisExamination> examinations,
  ) {
    if (isBusy) {
      return;
    }

    _examinations = List<DiagnosisExamination>
        .unmodifiable(examinations);

    final currentExamId =
        _selectedExamination?.examId;

    if (currentExamId != null) {
      _selectedExamination =
          _findExamination(currentExamId);
    }

    if (_selectedExamination == null &&
        _initialExamId != null) {
      _selectedExamination =
          _findExamination(_initialExamId);
    }

    _clearAnalysisState();
    _updateSelectionPhase();
    _notifyListeners();
  }

  void selectExamination(
    DiagnosisExamination? examination,
  ) {
    if (isBusy ||
        _selectedExamination?.examId ==
            examination?.examId) {
      return;
    }

    _selectedExamination = examination;

    if (examination?.patientId != null) {
      _patientId = examination!.patientId!.trim();
    }

    _clearAnalysisState();
    _updateSelectionPhase();
    _notifyListeners();
  }

  void selectAnalysisType(
    AiAnalysisType analysisType,
  ) {
    if (isBusy ||
        _selectedAnalysisType == analysisType) {
      return;
    }

    _selectedAnalysisType = analysisType;

    _clearAnalysisState();
    _applyDefaultOverlayState();
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
      _setFailure(
        '분석할 검사를 선택해 주세요.',
      );
      return;
    }

    if (analysisType == null) {
      _setFailure(
        '확인할 분석 결과 유형을 선택해 주세요.',
      );
      return;
    }

    if (!examination.canRunIntegratedAnalysis) {
      _setFailure(
        '키프레임이 있는 검사만 AI 분석을 실행할 수 있습니다.',
      );
      return;
    }

    _phase = DiagnosisPhase.submitting;
    _analysisResult = null;
    _errorMessage = null;
    _applyDefaultOverlayState();
    _notifyListeners();

    try {
      final result = await _diagnosisRepository
          .runIntegratedAnalysis(
        examId: examination.examId,
      );

      if (_isDisposed) {
        return;
      }

      _analysisResult = result;
      _showBoundingBox =
          analysisType.supportsBoundingBox &&
              result.canShowBoundingBox;
      _showHeatmap =
          analysisType.supportsHeatmap &&
              result.canShowHeatmap;
      _phase = DiagnosisPhase.completed;
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      _analysisResult = null;
      _errorMessage =
          _cleanErrorMessage(error);
      _phase = DiagnosisPhase.failed;
    }

    _notifyListeners();
  }

  Future<void> retryAnalysis() async {
    await runAnalysis();
  }

  void setBoundingBoxVisible(bool visible) {
    final analysisType = _selectedAnalysisType;
    final result = _analysisResult;

    if (analysisType == null ||
        !analysisType.supportsBoundingBox) {
      return;
    }

    if (visible &&
        (result == null ||
            !result.canShowBoundingBox)) {
      return;
    }

    if (_showBoundingBox == visible) {
      return;
    }

    _showBoundingBox = visible;
    _notifyListeners();
  }

  void setHeatmapVisible(bool visible) {
    final analysisType = _selectedAnalysisType;
    final result = _analysisResult;

    if (analysisType == null ||
        !analysisType.supportsHeatmap) {
      return;
    }

    if (visible &&
        (result == null ||
            !result.canShowHeatmap)) {
      return;
    }

    if (_showHeatmap == visible) {
      return;
    }

    _showHeatmap = visible;
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

    _selectedExamination = null;
    _selectedAnalysisType = null;
    _analysisResult = null;
    _errorMessage = null;
    _showBoundingBox = false;
    _showHeatmap = false;
    _phase = DiagnosisPhase.selecting;

    _notifyListeners();
  }

  DiagnosisExamination? _findExamination(
    int examId,
  ) {
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

  void _applyDefaultOverlayState() {
    final analysisType = _selectedAnalysisType;

    _showBoundingBox =
        analysisType?.supportsBoundingBox ?? false;
    _showHeatmap =
        analysisType?.supportsHeatmap ?? false;
  }

  void _updateSelectionPhase() {
    if (isBusy) {
      return;
    }

    if (_selectedExamination != null &&
        _selectedAnalysisType != null) {
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
      return '통합 AI 분석 중 오류가 발생했습니다.';
    }

    return message
        .replaceFirst(
          'DiagnosisRepositoryException: ',
          '',
        )
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  String? _normalizeString(String? value) {
    final normalizedValue = value?.trim();

    if (normalizedValue == null ||
        normalizedValue.isEmpty) {
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