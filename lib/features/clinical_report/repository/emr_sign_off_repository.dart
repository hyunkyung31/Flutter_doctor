import 'dart:typed_data';

import '../../../core/storage/secure_storage.dart';
import '../model/create_emr_sign_off_request.dart';
import '../model/emr_sign_off.dart';
import '../model/update_emr_sign_off_request.dart';
import '../service/emr_sign_off_service.dart';

final class EmrSignOffRepository {
  const EmrSignOffRepository({
    required this._emrSignOffService,
    required this._secureStorage,
  });

  final EmrSignOffService _emrSignOffService;
  final SecureStorage _secureStorage;

  Future<List<EmrSignOff>> fetchEmrSignOffs() async {
    // 목록 조회
    final accessToken = await _readAccessToken();

    try {
      return await _emrSignOffService.fetchEmrSignOffs(
        accessToken: accessToken,
      );
    } on EmrSignOffServiceException catch (error) {
      throw EmrSignOffRepositoryException(error.message);
    }
  }

  Future<EmrSignOff> fetchEmrSignOff({required int signOffId}) async {
    // 상세 조회
    final accessToken = await _readAccessToken();

    try {
      return await _emrSignOffService.fetchEmrSignOff(
        signOffId: signOffId,
        accessToken: accessToken,
      );
    } on EmrSignOffServiceException catch (error) {
      throw EmrSignOffRepositoryException(error.message);
    }
  }

  Future<EmrSignOff> createEmrSignOff({
    required CreateEmrSignOffRequest request,
  }) async {
    // 생성
    final accessToken = await _readAccessToken();

    try {
      return await _emrSignOffService.createEmrSignOff(
        request: request,
        accessToken: accessToken,
      );
    } on EmrSignOffServiceException catch (error) {
      throw EmrSignOffRepositoryException(error.message);
    }
  }

  Future<EmrSignOff> updateEmrSignOff({
    required int signOffId,
    required UpdateEmrSignOffRequest request,
  }) async {
    // 수정
    final accessToken = await _readAccessToken();

    try {
      return await _emrSignOffService.updateEmrSignOff(
        signOffId: signOffId,
        request: request,
        accessToken: accessToken,
      );
    } on EmrSignOffServiceException catch (error) {
      throw EmrSignOffRepositoryException(error.message);
    }
  }

  Future<EmrSignOff> generateReport({required int signOffId}) async {
    // PDF 생성
    final accessToken = await _readAccessToken();

    try {
      return await _emrSignOffService.generateReport(
        signOffId: signOffId,
        accessToken: accessToken,
      );
    } on EmrSignOffServiceException catch (error) {
      throw EmrSignOffRepositoryException(error.message);
    }
  }

  Future<Uint8List> downloadReport({required int signOffId}) async {
    // PDF 다운로드
    final accessToken = await _readAccessToken();

    try {
      return await _emrSignOffService.downloadReport(
        signOffId: signOffId,
        accessToken: accessToken,
      );
    } on EmrSignOffServiceException catch (error) {
      throw EmrSignOffRepositoryException(error.message);
    }
  }

  Future<EmrSignOff> transmitReport({required int signOffId}) async {
    // 전달 처리
    final accessToken = await _readAccessToken();

    try {
      return await _emrSignOffService.transmitReport(
        signOffId: signOffId,
        accessToken: accessToken,
      );
    } on EmrSignOffServiceException catch (error) {
      throw EmrSignOffRepositoryException(error.message);
    }
  }

  Future<String> _readAccessToken() async {
    // 내부 토큰 읽기
    final accessToken = await _secureStorage.readAccessToken();
    final normalizedAccessToken = accessToken?.trim();

    if (normalizedAccessToken == null || normalizedAccessToken.isEmpty) {
      throw const EmrSignOffRepositoryException('로그인 정보가 없습니다. 다시 로그인해 주세요.');
    }

    return normalizedAccessToken;
  }
}

final class EmrSignOffRepositoryException implements Exception {
  const EmrSignOffRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
