import 'package:flutter/foundation.dart';

import '../../consultation/repository/consultation_repository.dart';
import '../model/chat_models.dart';
import '../repository/chat_repository.dart';

final class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required ChatRepository chatRepository,
    required ConsultationRepository consultationRepository,
  }) : _chatRepository = chatRepository,
       _consultationRepository = consultationRepository;

  final ChatRepository _chatRepository;
  final ConsultationRepository _consultationRepository;

  List<ChatDoctor> _doctors = [];
  List<ChatRoom> _rooms = [];
  bool _isDoctorsLoading = false;
  bool _isRoomsLoading = false;
  final Set<String> _loadingRoomIds = {};
  final Set<String> _sendingRoomIds = {};
  final Set<String> _roomsWithLoadedMessages = {};
  String? _doctorsError;
  String? _errorMessage;

  List<ChatDoctor> get doctors => List.unmodifiable(_doctors);
  List<ChatRoom> get rooms => List.unmodifiable(_rooms);
  bool get isDoctorsLoading => _isDoctorsLoading;
  bool get isRoomsLoading => _isRoomsLoading;
  String? get doctorsError => _doctorsError;
  String? get errorMessage => _errorMessage;
  bool isRoomLoading(String id) => _loadingRoomIds.contains(id);
  bool isSending(String id) => _sendingRoomIds.contains(id);

  Future<void> loadRooms({bool force = false}) async {
    if (_isRoomsLoading || (!force && _rooms.isNotEmpty)) return;
    _isRoomsLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final fetchedRooms = await _chatRepository.fetchRooms();
      _rooms = fetchedRooms
          .map((fetchedRoom) {
            if (!_roomsWithLoadedMessages.contains(fetchedRoom.id)) {
              return fetchedRoom;
            }
            final currentRoom = roomById(fetchedRoom.id);
            if (currentRoom == null) return fetchedRoom;
            return fetchedRoom.copyWith(messages: currentRoom.messages);
          })
          .toList(growable: false);
    } on ChatRepositoryException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isRoomsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDoctors({bool force = false}) async {
    if (_isDoctorsLoading || (!force && _doctors.isNotEmpty)) return;
    _isDoctorsLoading = true;
    _doctorsError = null;
    notifyListeners();
    try {
      final doctors = await _consultationRepository.fetchDoctors();
      _doctors = doctors
          .map(
            (doctor) => ChatDoctor(
              id: doctor.doctorId,
              name: doctor.doctorName,
              department: doctor.department,
              hospital: doctor.hospitalName,
            ),
          )
          .where((doctor) => doctor.id.isNotEmpty)
          .toList(growable: false);
    } on ConsultationRepositoryException catch (error) {
      _doctorsError = error.message;
    } finally {
      _isDoctorsLoading = false;
      notifyListeners();
    }
  }

  ChatRoom? roomById(String id) {
    for (final room in _rooms) {
      if (room.id == id) return room;
    }
    return null;
  }

  Future<ChatRoom?> openRoom(ChatDoctor doctor) async {
    for (final room in _rooms) {
      if (room.doctor.id == doctor.id) return room;
    }
    try {
      final room = await _chatRepository.createRoom(doctor.id);
      if (room.id.trim().isEmpty) {
        throw const ChatRepositoryException('채팅방 번호가 응답에 없습니다.');
      }
      _rooms.insert(0, room);
      notifyListeners();
      return room;
    } on ChatRepositoryException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMessages(String roomId, {bool markRead = true}) async {
    if (_loadingRoomIds.contains(roomId)) return;
    _loadingRoomIds.add(roomId);
    _errorMessage = null;
    notifyListeners();
    try {
      final messages = await _chatRepository.fetchMessages(roomId);
      _updateRoom(roomId, messages: messages, unreadCount: 0);
      _roomsWithLoadedMessages.add(roomId);
      if (markRead) await _chatRepository.markRoomRead(roomId);
    } on ChatRepositoryException catch (error) {
      _errorMessage = error.message;
    } finally {
      _loadingRoomIds.remove(roomId);
      notifyListeners();
    }
  }

  Future<bool> sendText(String roomId, String text) async {
    final value = text.trim();
    if (value.isEmpty) return false;
    return _send(roomId, {'message_type': 'text', 'content': value});
  }

  Future<bool> share(
    String roomId, {
    required ChatMessageType type,
    required String content,
    required String patientId,
    int? examId,
    int? aiResultId,
    int? consultationId,
  }) {
    final typeValue = switch (type) {
      ChatMessageType.patient => 'patient',
      ChatMessageType.examination => 'examination',
      ChatMessageType.aiResult => 'ai_result',
      ChatMessageType.consultation => 'consultation',
      ChatMessageType.text => 'text',
    };
    return _send(roomId, {
      'message_type': typeValue,
      'content': content,
      'patient_id': patientId,
      if (examId != null) 'exam_id': examId,
      if (aiResultId != null) 'ai_result_id': aiResultId,
      if (consultationId != null) 'consultation_id': consultationId,
    });
  }

  Future<bool> _send(String roomId, Map<String, dynamic> data) async {
    if (_sendingRoomIds.contains(roomId)) return false;
    _sendingRoomIds.add(roomId);
    _errorMessage = null;
    notifyListeners();
    try {
      final message = await _chatRepository.sendMessage(roomId, data);
      final room = roomById(roomId);
      if (room != null)
        _updateRoom(roomId, messages: [...room.messages, message]);
      return true;
    } on ChatRepositoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _sendingRoomIds.remove(roomId);
      notifyListeners();
    }
  }

  Future<void> markResourceChecked(String roomId, String messageId) =>
      _updateResource(roomId, messageId, 'checked');

  Future<void> markResourceAnswered(String roomId, String messageId) =>
      _updateResource(roomId, messageId, 'answered');

  Future<void> _updateResource(
    String roomId,
    String messageId,
    String status,
  ) async {
    try {
      final updated = await _chatRepository.updateResourceStatus(
        messageId,
        status,
      );
      final room = roomById(roomId);
      if (room == null) return;
      final messages = room.messages
          .map((message) => message.id == messageId ? updated : message)
          .toList(growable: false);
      _updateRoom(roomId, messages: messages);
      notifyListeners();
    } on ChatRepositoryException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    }
  }

  void _updateRoom(
    String roomId, {
    List<ChatMessage>? messages,
    int? unreadCount,
  }) {
    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index < 0) return;
    _rooms[index] = _rooms[index].copyWith(
      messages: messages,
      unreadCount: unreadCount,
    );
  }
}
