import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/patient.dart';

class PatientService {
  PatientService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  // Django 서버 기본 주소
  static const String baseUrl = 'http://34.80.83.7:8000';

  final http.Client _client;

  Future<List<Patient>> fetchPatients({
    String? search,
    String? gender,
    int? minAge,
    int? maxAge,
  }) async {
    final queryParameters = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (gender != null && gender.isNotEmpty) {
      queryParameters['gender'] = gender;
    }

    if (minAge != null) {
      queryParameters['min_age'] = minAge.toString();
    }

    if (maxAge != null) {
      queryParameters['max_age'] = maxAge.toString();
    }

    final uri = Uri.parse('$baseUrl/api/patients/').replace(
      queryParameters: queryParameters,
    );

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        '환자 목록 조회 실패 (${response.statusCode})',
      );
    }

    final dynamic decodedData = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    List<dynamic> patientJsonList;

    // 응답이 배열 형태인 경우
    if (decodedData is List) {
      patientJsonList = decodedData;

      // 응답이 {"results": [...]} 형태인 경우
    } else if (decodedData is Map<String, dynamic> &&
        decodedData['results'] is List) {
      patientJsonList = decodedData['results'] as List;

      // 응답이 {"patients": [...]} 형태인 경우
    } else if (decodedData is Map<String, dynamic> &&
        decodedData['patients'] is List) {
      patientJsonList = decodedData['patients'] as List;
    } else {
      throw const FormatException(
        '환자 목록 응답 형식이 올바르지 않습니다.',
      );
    }

    return patientJsonList
        .whereType<Map<String, dynamic>>()
        .map(Patient.fromJson)
        .toList();
  }

  void dispose() {
    _client.close();
  }
}