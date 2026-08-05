import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/create_emr_sign_off_request.dart';
import '../model/emr_sign_off.dart';
import '../model/update_emr_sign_off_request.dart';

final class EmrSignOffService {
  const EmrSignOffService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<EmrSignOff>> fetchEmrSignOffs({
    required String accessToken,
  }) async {
    try {
      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.emrSignOffs,
        options: _authorizedOptions(accessToken),
      );

      final items = _responseList(response.data);

      return items
          .whereType<Map>()
          .map((item) => EmrSignOff.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw EmrSignOffServiceException(
        _messageFromDioException(
          error,
          defaultMessage: '임상 보고서 목록을 불러오지 못했습니다.',
        ),
      );
    } on FormatException catch (error) {
      throw EmrSignOffServiceException(error.message);
    } on EmrSignOffServiceException {
      rethrow;
    } catch (_) {
      throw const EmrSignOffServiceException('임상 보고서 목록을 불러오지 못했습니다.');
    }
  }

  Future<EmrSignOff> fetchEmrSignOff({
    required int signOffId,
    required String accessToken,
  }) async {
    _validateSignOffId(signOffId);

    try {
      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.emrSignOffDetail(signOffId),
        options: _authorizedOptions(accessToken),
      );

      return _parseEmrSignOff(response.data);
    } on DioException catch (error) {
      throw EmrSignOffServiceException(
        _messageFromDioException(error, defaultMessage: '임상 보고서를 불러오지 못했습니다.'),
      );
    } on FormatException catch (error) {
      throw EmrSignOffServiceException(error.message);
    } on EmrSignOffServiceException {
      rethrow;
    } catch (_) {
      throw const EmrSignOffServiceException('임상 보고서를 불러오지 못했습니다.');
    }
  }

  Future<EmrSignOff> createEmrSignOff({
    required CreateEmrSignOffRequest request,
    required String accessToken,
  }) async {
    _validateCreateRequest(request);

    try {
      final response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.emrSignOffs,
        data: request.toJson(),
        options: _authorizedOptions(accessToken),
      );

      return _parseEmrSignOff(response.data);
    } on DioException catch (error) {
      throw EmrSignOffServiceException(
        _messageFromDioException(
          error,
          defaultMessage: '의료진 소견 초안을 저장하지 못했습니다.',
        ),
      );
    } on FormatException catch (error) {
      throw EmrSignOffServiceException(error.message);
    } on EmrSignOffServiceException {
      rethrow;
    } catch (_) {
      throw const EmrSignOffServiceException('의료진 소견 초안을 저장하지 못했습니다.');
    }
  }

  Future<EmrSignOff> updateEmrSignOff({
    required int signOffId,
    required UpdateEmrSignOffRequest request,
    required String accessToken,
  }) async {
    _validateSignOffId(signOffId);

    if (request.isEmpty) {
      throw const EmrSignOffServiceException('수정할 임상 보고서 내용이 없습니다.');
    }

    try {
      final response = await _apiClient.dio.patch<dynamic>(
        ApiEndpoints.emrSignOffDetail(signOffId),
        data: request.toJson(),
        options: _authorizedOptions(accessToken),
      );

      return _parseEmrSignOff(response.data);
    } on DioException catch (error) {
      throw EmrSignOffServiceException(
        _messageFromDioException(error, defaultMessage: '임상 보고서를 수정하지 못했습니다.'),
      );
    } on FormatException catch (error) {
      throw EmrSignOffServiceException(error.message);
    } on EmrSignOffServiceException {
      rethrow;
    } catch (_) {
      throw const EmrSignOffServiceException('임상 보고서를 수정하지 못했습니다.');
    }
  }

  Options _authorizedOptions(String accessToken) {
    final normalizedAccessToken = accessToken.trim();

    if (normalizedAccessToken.isEmpty) {
      throw const EmrSignOffServiceException('로그인 정보가 없습니다.');
    }

    return Options(
      headers: {
        'Authorization': 'Bearer $normalizedAccessToken',
        'Content-Type': 'application/json',
      },
    );
  }

  List<dynamic> _responseList(Object? data) {
    if (data is List<dynamic>) {
      return data;
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final items = map['results'] ?? map['emr_signoffs'] ?? map['data'];

      if (items is List<dynamic>) {
        return items;
      }
    }

    throw const EmrSignOffServiceException('임상 보고서 목록 응답 형식이 올바르지 않습니다.');
  }

  EmrSignOff _parseEmrSignOff(Object? data) {
    if (data is! Map) {
      throw const EmrSignOffServiceException('임상 보고서 응답 형식이 올바르지 않습니다.');
    }

    return EmrSignOff.fromJson(Map<String, dynamic>.from(data));
  }

  void _validateSignOffId(int signOffId) {
    if (signOffId <= 0) {
      throw const EmrSignOffServiceException('임상 보고서 ID가 올바르지 않습니다.');
    }
  }

  void _validateCreateRequest(CreateEmrSignOffRequest request) {
    if (request.patientId.trim().isEmpty) {
      throw const EmrSignOffServiceException('환자 ID가 없습니다.');
    }

    if (request.examId <= 0) {
      throw const EmrSignOffServiceException('검사 ID가 올바르지 않습니다.');
    }

    if (request.finalized && request.finalResult.trim().isEmpty) {
      throw const EmrSignOffServiceException('최종 승인하려면 의료진 소견을 입력해 주세요.');
    }
  }

  String _messageFromDioException(
    DioException error, {
    required String defaultMessage,
  }) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return '임상 보고서 서버 응답 시간이 초과되었습니다.';

      case DioExceptionType.connectionError:
        return '임상 보고서 서버에 연결할 수 없습니다.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final serverMessage = _responseMessage(error.response?.data);

        if (statusCode == 400) {
          return serverMessage ?? '임상 보고서 입력값을 확인해 주세요.';
        }

        if (statusCode == 401 || statusCode == 403) {
          return '로그인 정보가 만료되었거나 접근 권한이 없습니다.';
        }

        if (statusCode == 404) {
          return serverMessage ?? '임상 보고서를 찾을 수 없습니다.';
        }

        if (statusCode == 409) {
          return serverMessage ?? '이미 처리된 임상 보고서입니다.';
        }

        if (statusCode != null && statusCode >= 500) {
          return serverMessage ?? '임상 보고서 서버 오류가 발생했습니다.';
        }

        return serverMessage ?? defaultMessage;

      case DioExceptionType.cancel:
        return '임상 보고서 요청이 취소되었습니다.';

      case DioExceptionType.badCertificate:
        return '임상 보고서 서버 인증서를 확인할 수 없습니다.';

      case DioExceptionType.unknown:
        return '임상 보고서 처리 중 네트워크 오류가 발생했습니다.';
    }
  }

  String? _responseMessage(Object? data) {
    if (data is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(data);

    for (final key in const ['detail', 'message', 'error']) {
      final value = map[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    for (final value in map.values) {
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }
}

final class EmrSignOffServiceException implements Exception {
  const EmrSignOffServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
