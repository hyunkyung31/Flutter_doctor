import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../ai_result/model/integrated_analysis_result.dart';

final class DiagnosisService {
  DiagnosisService(this._apiClient);

  final ApiClient _apiClient;

  Future<IntegratedAnalysisResult> runIntegratedAnalysis({
    required int examId,
    required String accessToken,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
  }) async {
    if (examId <= 0) {
      throw const DiagnosisServiceException(
        '검사 ID가 올바르지 않습니다.',
      );
    }

    final normalizedAccessToken = accessToken.trim();

    if (normalizedAccessToken.isEmpty) {
      throw const DiagnosisServiceException(
        '로그인 정보가 없습니다.',
      );
    }

    if (!_isValidThreshold(confidenceThreshold) ||
        !_isValidThreshold(iouThreshold)) {
      throw const DiagnosisServiceException(
        '분석 임계값은 0부터 1 사이여야 합니다.',
      );
    }

    try {
      final response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.examAiRun(examId),
        queryParameters: {
          'confidence_threshold': confidenceThreshold,
          'iou_threshold': iouThreshold,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $normalizedAccessToken',
          },
          receiveTimeout: const Duration(
            seconds: 200,
          ),
        ),
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw const DiagnosisServiceException(
          '통합 AI 분석 응답 형식이 올바르지 않습니다.',
        );
      }

      return IntegratedAnalysisResult.fromJson(
        Map<String, dynamic>.from(responseData),
      );
    } on DioException catch (error) {
      throw DiagnosisServiceException(
        _messageFromDioException(error),
      );
    } on DiagnosisServiceException {
      rethrow;
    } on FormatException catch (error) {
      throw DiagnosisServiceException(
        error.message,
      );
    } catch (_) {
      throw const DiagnosisServiceException(
        '통합 AI 분석 중 오류가 발생했습니다.',
      );
    }
  }

  bool _isValidThreshold(double value) {
    return value >= 0.0 && value <= 1.0;
  }

  String _messageFromDioException(
    DioException error,
  ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'AI 분석 서버 연결 시간이 초과되었습니다.';

      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'AI 분석 시간이 초과되었습니다. 잠시 후 다시 시도해 주세요.';

      case DioExceptionType.connectionError:
        return 'AI 분석 서버에 연결할 수 없습니다.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final serverMessage = _responseDetail(
          error.response?.data,
        );

        if (statusCode == 400) {
          return serverMessage ??
              '분석할 검사 정보가 올바르지 않습니다.';
        }

        if (statusCode == 401 ||
            statusCode == 403) {
          return '로그인 정보가 만료되었습니다. 다시 로그인해 주세요.';
        }

        if (statusCode == 404) {
          return serverMessage ??
              '검사 또는 키프레임을 찾을 수 없습니다.';
        }

        if (statusCode == 502) {
          return serverMessage ??
              'AI 분석 서버가 응답하지 않습니다.';
        }

        if (statusCode != null &&
            statusCode >= 500) {
          return serverMessage ??
              'AI 분석 서버 내부 오류가 발생했습니다.';
        }

        return serverMessage ??
            '통합 AI 분석 요청을 완료하지 못했습니다.';

      case DioExceptionType.cancel:
        return '통합 AI 분석 요청이 취소되었습니다.';

      case DioExceptionType.badCertificate:
        return 'AI 분석 서버 인증서를 확인할 수 없습니다.';

      case DioExceptionType.unknown:
        return 'AI 분석 중 네트워크 오류가 발생했습니다.';
    }
  }

  String? _responseDetail(Object? data) {
    if (data is! Map) {
      return null;
    }

    final detail = data['detail'];

    if (detail == null) {
      return null;
    }

    final message = detail.toString().trim();

    return message.isEmpty ? null : message;
  }
}

final class DiagnosisServiceException
    implements Exception {
  const DiagnosisServiceException(
    this.message,
  );

  final String message;

  @override
  String toString() {
    return message;
  }
}