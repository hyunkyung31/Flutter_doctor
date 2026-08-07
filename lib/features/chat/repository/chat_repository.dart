import '../../../core/storage/secure_storage.dart';
import '../model/chat_models.dart';
import '../service/chat_service.dart';

final class ChatRepository {
  const ChatRepository({
    required ChatService service,
    required SecureStorage storage,
  }) : _service = service,
       _storage = storage;

  final ChatService _service;
  final SecureStorage _storage;

  Future<String> _token() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ChatRepositoryException('로그인 정보가 없습니다. 다시 로그인해 주세요.');
    }
    return token;
  }

  Future<List<ChatRoom>> fetchRooms() =>
      _call((token) => _service.fetchRooms(token));
  Future<ChatRoom> createRoom(String doctorId) =>
      _call((token) => _service.createRoom(token, doctorId));
  Future<List<ChatMessage>> fetchMessages(String roomId) =>
      _call((token) => _service.fetchMessages(token, roomId));
  Future<ChatMessage> sendMessage(String roomId, Map<String, dynamic> data) =>
      _call((token) => _service.sendMessage(token, roomId, data));
  Future<void> markRoomRead(String roomId) =>
      _call((token) => _service.markRoomRead(token, roomId));
  Future<ChatMessage> updateResourceStatus(String messageId, String status) =>
      _call((token) => _service.updateResourceStatus(token, messageId, status));

  Future<T> _call<T>(Future<T> Function(String token) action) async {
    try {
      return await action(await _token());
    } on ChatServiceException catch (error) {
      throw ChatRepositoryException(error.message);
    }
  }
}

final class ChatRepositoryException implements Exception {
  const ChatRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}
