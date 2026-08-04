import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/chat_models.dart';

final class ChatService {
  const ChatService(this._apiClient);

  final ApiClient _apiClient;

  Options _options(String token) => Options(
        headers: {'Authorization': 'Bearer $token'},
      );

  Future<List<ChatRoom>> fetchRooms(String token) async {
    return _request(() async {
      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.chatRooms,
        options: _options(token),
      );
      final items = _items(response.data);
      return items.map(ChatRoom.fromJson).toList(growable: false);
    }, '채팅방 목록을 불러오지 못했습니다.');
  }

  Future<ChatRoom> createRoom(String token, String doctorId) async {
    return _request(() async {
      final response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.chatRooms,
        data: {'doctor_id': doctorId},
        options: _options(token),
      );
      return ChatRoom.fromJson(_map(response.data));
    }, '채팅방을 만들지 못했습니다.');
  }

  Future<List<ChatMessage>> fetchMessages(String token, String roomId) async {
    return _request(() async {
      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.chatMessages(roomId),
        options: _options(token),
      );
      return _items(response.data)
          .map(ChatMessage.fromJson)
          .toList(growable: false);
    }, '메시지를 불러오지 못했습니다.');
  }

  Future<ChatMessage> sendMessage(
    String token,
    String roomId,
    Map<String, dynamic> data,
  ) async {
    return _request(() async {
      final response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.chatMessages(roomId),
        data: data,
        options: _options(token),
      );
      return ChatMessage.fromJson(_map(response.data));
    }, '메시지를 전송하지 못했습니다.');
  }

  Future<void> markRoomRead(String token, String roomId) async {
    await _request(() async {
      await _apiClient.dio.patch<dynamic>(
        ApiEndpoints.chatRoomRead(roomId),
        options: _options(token),
      );
    }, '메시지를 읽음 처리하지 못했습니다.');
  }

  Future<ChatMessage> updateResourceStatus(
    String token,
    String messageId,
    String status,
  ) async {
    return _request(() async {
      final response = await _apiClient.dio.patch<dynamic>(
        ApiEndpoints.chatResourceStatus(messageId),
        data: {'resource_status': status},
        options: _options(token),
      );
      return ChatMessage.fromJson(_map(response.data));
    }, '공유 자료 상태를 변경하지 못했습니다.');
  }

  Future<T> _request<T>(Future<T> Function() action, String fallback) async {
    try {
      return await action();
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        throw ChatServiceException(data['detail'].toString());
      }
      throw ChatServiceException(fallback);
    } on ChatServiceException {
      rethrow;
    } catch (_) {
      throw ChatServiceException(fallback);
    }
  }

  List<Map<String, dynamic>> _items(dynamic data) {
    final source = data is List
        ? data
        : data is Map
            ? data['results'] ?? data['data']
            : null;
    if (source is! List) return const [];
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ChatServiceException('채팅 API 응답 형식이 올바르지 않습니다.');
  }
}

final class ChatServiceException implements Exception {
  const ChatServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}
