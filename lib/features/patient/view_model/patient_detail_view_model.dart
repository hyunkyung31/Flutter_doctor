import 'package:flutter/material.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../model/patient_detail.dart';
import '../repository/patient_repository.dart';

final class PatientDetailViewModel
    extends ChangeNotifier {
  PatientDetailViewModel({
    required PatientRepository patientRepository,
    required SecureStorage secureStorage,
  })  : _patientRepository = patientRepository,
        _secureStorage = secureStorage;

  final PatientRepository _patientRepository;
  final SecureStorage _secureStorage;

  PatientDetail? _patientDetail;
  bool _isLoading = false;
  String? _errorMessage;
  String? _accessToken;

  PatientDetail? get patientDetail {
    return _patientDetail;
  }

  bool get isLoading {
    return _isLoading;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  String? get accessToken {
    return _accessToken;
  }

  bool get hasAccessToken {
    return _accessToken != null &&
        _accessToken!.trim().isNotEmpty;
  }

  Map<String, String> get mediaHeaders {
    final token = _accessToken;

    if (token == null ||
        token.trim().isEmpty) {
      return const {
        'Accept': '*/*',
      };
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': '*/*',
    };
  }

  Future<void> loadPatientDetail(
    String patientId,
  ) async {
    if (_isLoading) {
      return;
    }

    final normalizedPatientId =
        patientId.trim();

    if (normalizedPatientId.isEmpty) {
      _errorMessage =
          '환자 ID가 올바르지 않습니다.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadAccessToken();

      _patientDetail =
          await _patientRepository
              .getPatientDetail(
        normalizedPatientId,
      );
    } catch (error) {
      _patientDetail = null;
      _errorMessage =
          _cleanErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPatientDetail(
    String patientId,
  ) async {
    final normalizedPatientId =
        patientId.trim();

    if (normalizedPatientId.isEmpty) {
      _errorMessage =
          '환자 ID가 올바르지 않습니다.';
      notifyListeners();
      return;
    }

    _errorMessage = null;

    try {
      await _loadAccessToken();

      _patientDetail =
          await _patientRepository
              .getPatientDetail(
        normalizedPatientId,
      );
    } catch (error) {
      _errorMessage =
          _cleanErrorMessage(error);
    }

    notifyListeners();
  }

  Future<void> reloadAccessToken() async {
    try {
      await _loadAccessToken();
    } catch (error) {
      _accessToken = null;
      _errorMessage =
          _cleanErrorMessage(error);
    }

    notifyListeners();
  }

  String resolveMediaUrl(
    String? value,
  ) {
    final mediaPath =
        value?.trim() ?? '';

    if (mediaPath.isEmpty) {
      return '';
    }

    final uri =
        Uri.tryParse(mediaPath);

    if (uri != null &&
        (uri.scheme == 'http' ||
            uri.scheme == 'https')) {
      return mediaPath;
    }

    final baseUrl =
        ApiEndpoints.baseUrl.endsWith('/')
            ? ApiEndpoints.baseUrl
                .substring(
                0,
                ApiEndpoints
                        .baseUrl.length -
                    1,
              )
            : ApiEndpoints.baseUrl;

    if (mediaPath.startsWith('/')) {
      return '$baseUrl$mediaPath';
    }

    return '$baseUrl/$mediaPath';
  }

  void clearPatientDetail() {
    _patientDetail = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAccessToken() async {
    final token =
        await _secureStorage
            .readAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      _accessToken = null;

      throw const PatientDetailViewModelException(
        '로그인 정보가 없습니다. 다시 로그인해 주세요.',
      );
    }

    _accessToken = token.trim();
  }

  String _cleanErrorMessage(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'PatientRepositoryException: ',
          '',
        )
        .replaceFirst(
          'PatientDetailViewModelException: ',
          '',
        )
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }
}

final class PatientDetailViewModelException
    implements Exception {
  const PatientDetailViewModelException(
    this.message,
  );

  final String message;

  @override
  String toString() {
    return message;
  }
}