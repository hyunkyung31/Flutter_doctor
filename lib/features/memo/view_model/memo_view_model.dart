import 'package:flutter/foundation.dart';

import '../model/patient_memo.dart';
import '../repository/memo_repository.dart';

enum MemoFilter {
  all,
  text,
  voice,
}

final class MemoViewModel extends ChangeNotifier {
  MemoViewModel({
    required MemoRepository memoRepository,
  }) : _memoRepository = memoRepository;

  final MemoRepository _memoRepository;

  List<PatientMemo> _memos = [];
  PatientMemo? _selectedMemo;

  MemoFilter _filter = MemoFilter.all;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  String? _errorMessage;

  List<PatientMemo> get memos {
    return List.unmodifiable(_memos);
  }

  PatientMemo? get selectedMemo {
    return _selectedMemo;
  }

  MemoFilter get filter {
    return _filter;
  }

  bool get isLoading {
    return _isLoading;
  }

  bool get isSaving {
    return _isSaving;
  }

  bool get isDeleting {
    return _isDeleting;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  List<PatientMemo> get filteredMemos {
    return switch (_filter) {
      MemoFilter.all => List.unmodifiable(_memos),
      MemoFilter.text => List.unmodifiable(
          _memos.where((memo) => memo.isTextMemo),
        ),
      MemoFilter.voice => List.unmodifiable(
          _memos.where((memo) => memo.isVoiceMemo),
        ),
    };
  }

  int get totalCount {
    return _memos.length;
  }

  int get textCount {
    return _memos.where((memo) => memo.isTextMemo).length;
  }

  int get voiceCount {
    return _memos.where((memo) => memo.isVoiceMemo).length;
  }

  void changeFilter(MemoFilter value) {
    if (_filter == value) {
      return;
    }

    _filter = value;
    notifyListeners();
  }

  Future<void> loadMemos({
    required String patientId,
  }) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _memoRepository.fetchMemos(
        patientId: patientId,
      );

      _memos = [...items]..sort(_compareByLatest);
    } on MemoRepositoryException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '메모 목록을 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMemos({
    required String patientId,
  }) {
    return loadMemos(patientId: patientId);
  }

  Future<bool> loadMemo({
    required int memoId,
  }) async {
    if (_isLoading) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final memo = await _memoRepository.fetchMemo(
        memoId: memoId,
      );

      _selectedMemo = memo;
      _replaceMemo(memo);

      return true;
    } on MemoRepositoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '메모를 불러오지 못했습니다.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTextMemo({
    required String patientId,
    required String title,
    required String content,
    int? examId,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedContent = content.trim();

    if (normalizedContent.isEmpty) {
      _errorMessage = '메모 내용을 입력해 주세요.';
      notifyListeners();
      return false;
    }

    if (_isSaving) {
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final memo = await _memoRepository.createTextMemo(
        patientId: patientId,
        title: normalizedTitle,
        content: normalizedContent,
        examId: examId,
      );

      _memos.insert(0, memo);
      _memos.sort(_compareByLatest);
      _selectedMemo = memo;

      return true;
    } on MemoRepositoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '메모를 저장하지 못했습니다.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateTextMemo({
    required int memoId,
    required String title,
    required String content,
    int? examId,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedContent = content.trim();

    if (normalizedContent.isEmpty) {
      _errorMessage = '메모 내용을 입력해 주세요.';
      notifyListeners();
      return false;
    }

    if (_isSaving) {
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final memo = await _memoRepository.updateTextMemo(
        memoId: memoId,
        title: normalizedTitle,
        content: normalizedContent,
        examId: examId,
      );

      _replaceMemo(memo);
      _selectedMemo = memo;

      return true;
    } on MemoRepositoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '메모를 수정하지 못했습니다.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMemo({
    required int memoId,
  }) async {
    if (_isDeleting) {
      return false;
    }

    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _memoRepository.deleteMemo(
        memoId: memoId,
      );

      _memos.removeWhere((memo) => memo.id == memoId);

      if (_selectedMemo?.id == memoId) {
        _selectedMemo = null;
      }

      return true;
    } on MemoRepositoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '메모를 삭제하지 못했습니다.';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  PatientMemo? memoById(int memoId) {
    for (final memo in _memos) {
      if (memo.id == memoId) {
        return memo;
      }
    }

    return null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedMemo() {
    _selectedMemo = null;
    notifyListeners();
  }

  void _replaceMemo(PatientMemo updatedMemo) {
    final index = _memos.indexWhere(
      (memo) => memo.id == updatedMemo.id,
    );

    if (index == -1) {
      _memos.add(updatedMemo);
    } else {
      _memos[index] = updatedMemo;
    }

    _memos.sort(_compareByLatest);
  }

  int _compareByLatest(
    PatientMemo first,
    PatientMemo second,
  ) {
    final firstDate =
        first.updatedAt ??
        first.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final secondDate =
        second.updatedAt ??
        second.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return secondDate.compareTo(firstDate);
  }
}