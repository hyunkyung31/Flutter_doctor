import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/patient_memo.dart';

final class MemoService {
  const MemoService(this._apiClient);

  final ApiClient _apiClient;

  Options _options(String accessToken) {
    return Options(
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
  }

  Future<List<PatientMemo>> fetchMemos({
    required String accessToken,
    String? patientId,
  }) async {
    try {
      final normalizedPatientId = patientId?.trim();

      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.memos,
        queryParameters: {
          if (normalizedPatientId != null &&
              normalizedPatientId.isNotEmpty)
            'patient_id': normalizedPatientId,
        },
        options: _options(accessToken),
      );

      final items = _items(response.data);

      return items
          .map(PatientMemo.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw MemoServiceException(
        _errorMessage(
          error,
          fallback: '메모 목록을 불러오지 못했습니다.',
        ),
      );
    } catch (_) {
      throw const MemoServiceException(
        '메모 목록을 불러오지 못했습니다.',
      );
    }
  }

  Future<PatientMemo> fetchMemo({
    required String accessToken,
    required int memoId,
  }) async {
    try {
      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.memoDetail(memoId),
        options: _options(accessToken),
      );

      return PatientMemo.fromJson(
        _map(response.data),
      );
    } on DioException catch (error) {
      throw MemoServiceException(
        _errorMessage(
          error,
          fallback: '메모를 불러오지 못했습니다.',
        ),
      );
    } catch (_) {
      throw const MemoServiceException(
        '메모를 불러오지 못했습니다.',
      );
    }
  }

  Future<PatientMemo> createTextMemo({
    required String accessToken,
    required String patientId,
    required String title,
    required String content,
    int? examId,
  }) async {
    try {
      final data = <String, dynamic>{
        'patient_id': patientId.trim(),
        'memo_type': PatientMemoType.text.value,
        'title': title.trim(),
        'content': content.trim(),
      };

      if (examId != null) {
        data['exam_id'] = examId;
      }

      final response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.memos,
        data: data,
        options: _options(accessToken),
      );

      return PatientMemo.fromJson(
        _map(response.data),
      );
    } on DioException catch (error) {
      throw MemoServiceException(
        _errorMessage(
          error,
          fallback: '메모를 저장하지 못했습니다.',
        ),
      );
    } catch (_) {
      throw const MemoServiceException(
        '메모를 저장하지 못했습니다.',
      );
    }
  }

  Future<PatientMemo> createVoiceMemo({
    required String accessToken,
    required String patientId,
    required String audioPath,
    required int durationSeconds,
    String title = '',
    int? examId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'patient_id': patientId.trim(),
        'memo_type': PatientMemoType.voice.value,
        'title': title.trim(),
        'audio_duration_seconds': durationSeconds,
        if (examId != null) 'exam_id': examId,
        'audio_file': await MultipartFile.fromFile(
          audioPath,
          filename: 'voice_memo.m4a',
        ),
      });

      final response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.voiceMemos,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
          contentType: Headers.multipartFormDataContentType,
        ),
      );

      return PatientMemo.fromJson(_map(response.data));
    } on DioException catch (error) {
      throw MemoServiceException(
        _errorMessage(
          error,
          fallback: '음성 메모를 저장하지 못했습니다.',
        ),
      );
    } catch (_) {
      throw const MemoServiceException(
        '음성 메모를 저장하지 못했습니다.',
      );
    }
  }

  Future<PatientMemo> updateTextMemo({
    required String accessToken,
    required int memoId,
    required String title,
    required String content,
    int? examId,
  }) async {
    try {
      final data = <String, dynamic>{
        'memo_type': PatientMemoType.text.value,
        'title': title.trim(),
        'content': content.trim(),
        'exam_id': examId,
      };

      final response = await _apiClient.dio.patch<dynamic>(
        ApiEndpoints.memoDetail(memoId),
        data: data,
        options: _options(accessToken),
      );

      return PatientMemo.fromJson(
        _map(response.data),
      );
    } on DioException catch (error) {
      throw MemoServiceException(
        _errorMessage(
          error,
          fallback: '메모를 수정하지 못했습니다.',
        ),
      );
    } catch (_) {
      throw const MemoServiceException(
        '메모를 수정하지 못했습니다.',
      );
    }
  }

  Future<PatientMemo> updateVoiceMemo({
    required String accessToken,
    required int memoId,
    required String title,
  }) async {
    try {
      final response = await _apiClient.dio.patch<dynamic>(
        ApiEndpoints.memoDetail(memoId),
        data: {'title': title.trim()},
        options: _options(accessToken),
      );

      return PatientMemo.fromJson(_map(response.data));
    } on DioException catch (error) {
      throw MemoServiceException(
        _errorMessage(error, fallback: '음성 메모 제목을 수정하지 못했습니다.'),
      );
    } catch (_) {
      throw const MemoServiceException('음성 메모 제목을 수정하지 못했습니다.');
    }
  }

  Future<void> deleteMemo({
    required String accessToken,
    required int memoId,
  }) async {
    try {
      await _apiClient.dio.delete<dynamic>(
        ApiEndpoints.memoDetail(memoId),
        options: _options(accessToken),
      );
    } on DioException catch (error) {
      throw MemoServiceException(
        _errorMessage(
          error,
          fallback: '메모를 삭제하지 못했습니다.',
        ),
      );
    } catch (_) {
      throw const MemoServiceException(
        '메모를 삭제하지 못했습니다.',
      );
    }
  }

  List<Map<String, dynamic>> _items(dynamic data) {
    final dynamic source;

    if (data is List) {
      source = data;
    } else if (data is Map) {
      source = data['results'] ??
          data['memos'] ??
          data['data'];
    } else {
      source = null;
    }

    if (source is! List) {
      return const [];
    }

    return source
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is! Map) {
      throw const MemoServiceException(
        '메모 API 응답 형식이 올바르지 않습니다.',
      );
    }

    final map = Map<String, dynamic>.from(data);

    final nested = map['data'] ??
        map['result'] ??
        map['memo'];

    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }

    return map;
  }

  String _errorMessage(
    DioException error, {
    required String fallback,
  }) {
    final data = error.response?.data;

    if (data is Map) {
      final detail = data['detail'];

      if (detail != null &&
          detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }

      final message = data['message'];

      if (message != null &&
          message.toString().trim().isNotEmpty) {
        return message.toString();
      }

      for (final entry in data.entries) {
        final value = entry.value;

        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value != null &&
            value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return fallback;
  }
}

final class MemoServiceException implements Exception {
  const MemoServiceException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
