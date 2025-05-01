import 'dart:async'; // For StreamController, Stream
// import 'package:web_socket_channel/web_socket_channel.dart'; // Removed
import 'package:socket_io_client/socket_io_client.dart' as IO; // Added
import '../../../../features/auth/data/datasources/auth_remote_data_source.dart'; // For ServerException
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_message_model.dart';

// Abstract interface for the Chat Repository
abstract class ChatRepository {
  /// Fetches historical messages for a given room.
  Future<List<ChatMessageModel>> getMessageHistory(int roomId);

  /// Sends a text message (likely via WebSocket).
  Future<void> sendTextMessage({required int roomId, required String text});

  /// Sends a file message (likely via HTTP POST).
  Future<void> sendFileMessage(
      {required int roomId, required String filePath /* or File object */});

  /// Provides a stream of incoming messages for a room (from WebSocket).
  Stream<ChatMessageModel> getMessageStream(int roomId);

  /// Cleans up resources or notifies backend when leaving a room.
  void leaveRoom(int roomId);
}

// Implementation of the Chat Repository
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  // WebSocketChannel? _channel; // WebSocket channel instance - Removed
  IO.Socket? _socket; // Socket.IO client instance - Added
  StreamController<ChatMessageModel>?
      _messageStreamController; // Controller for broadcasting messages
  int? _currentRoomId; // Track the current room

  // TODO: Get WebSocket URL from config/env
  // Use ws://localhost:3000/ws for iOS simulator if backend is on localhost:3000
  // Use ws://10.0.2.2:3000/ws for Android emulator
  // Assuming the backend WebSocket server listens on the /ws path
  // final String _webSocketUrl = 'ws://10.0.2.2:3000/ws'; // Changed to http for Socket.IO
  final String _socketIoUrl = 'http://localhost:3000'; // Changed for Socket.IO

  ChatRepositoryImpl({
    required this.remoteDataSource,
  });

  // Helper to initialize WebSocket connection and stream controller
  void _connect(int roomId) {
    // if (_channel != null && _currentRoomId == roomId) { // Changed
    if (_socket != null && _currentRoomId == roomId && _socket!.connected) {
      // Changed
      print("Already connected to Socket.IO for room $roomId");
      return; // Already connected to this room
    }
    _disconnect(); // Disconnect from previous room if any

    // print("Connecting to WebSocket for room $roomId at $_webSocketUrl"); // Changed
    print(
        "Connecting to Socket.IO for room $roomId at $_socketIoUrl"); // Changed
    _currentRoomId = roomId;
    _messageStreamController = StreamController<ChatMessageModel>.broadcast();
    // _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl)); // Removed

    // Configure Socket.IO options
    _socket = IO.io(_socketIoUrl, <String, dynamic>{
      'transports': ['websocket'], // Use WebSocket transport
      'autoConnect': false, // Connect manually
      // Add any other options needed, e.g., query parameters for auth
    });

    // Connect to the server
    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket.IO connected');
      // Emit joinRoom event immediately after connection
      // _channel!.sink.add(jsonEncode({'event': 'joinRoom', 'data': roomId})); // Removed
      _socket!.emit('joinRoom', roomId); // Changed for Socket.IO
      print("Sent joinRoom event for room $roomId via Socket.IO");
    });

    // Listen for incoming messages ('newMessage' event)
    _socket!.on('newMessage', (data) {
      print("Socket.IO 'newMessage' received: $data");
      try {
        // Assuming data is already the message object Map<String, dynamic>
        if (data is Map<String, dynamic>) {
          final chatMessage = ChatMessageModel.fromJson(data);
          _messageStreamController?.add(chatMessage); // Add to stream
        } else {
          print("Received unexpected data format for 'newMessage': $data");
        }
      } catch (e) {
        print("Error processing 'newMessage' data: $e");
        // Optionally add error to stream: _messageStreamController?.addError(e);
      }
    });

    _socket!.onDisconnect((_) {
      print("Socket.IO connection closed for room $_currentRoomId");
      _messageStreamController?.close();
      _socket = null;
      _currentRoomId = null;
    });

    _socket!.onError((error) {
      print("Socket.IO error for room $_currentRoomId: $error");
      _messageStreamController?.addError(error); // Add error to stream
      _disconnect(); // Attempt to clean up on error
    });

    _socket!.onConnectError((error) {
      print("Socket.IO connection error: $error");
      _messageStreamController?.addError("Connection Error: $error");
      _disconnect();
    });

    // Listen for incoming messages - Old WebSocket logic removed
    /*
    _channel!.stream.listen(
      (message) {
        print("WebSocket message received: $message");
        try {
          final decoded = jsonDecode(message as String);
          // Assuming server sends {'event': 'newMessage', 'data': messageObject}
          if (decoded is Map<String, dynamic> &&
              decoded['event'] == 'newMessage') {
            final messageData = decoded['data'] as Map<String, dynamic>;
            final chatMessage = ChatMessageModel.fromJson(messageData);
            _messageStreamController?.add(chatMessage); // Add to stream
          } else {
            print("Received unknown WebSocket message format: $decoded");
          }
        } catch (e) {
          print("Error decoding WebSocket message: $e");
          // Optionally add error to stream: _messageStreamController?.addError(e);
        }
      },
      onDone: () {
        print("WebSocket connection closed for room $_currentRoomId");
        _messageStreamController?.close();
        _channel = null;
        _currentRoomId = null;
      },
      onError: (error) {
        print("WebSocket error for room $_currentRoomId: $error");
        _messageStreamController?.addError(error); // Add error to stream
        _disconnect(); // Attempt to clean up on error
      },
      cancelOnError: true, // Close stream on error
    );
    */
  }

  // Helper to disconnect WebSocket
  void _disconnect() {
    // if (_channel != null) { // Changed
    if (_socket != null) {
      // Changed
      // print("Disconnecting WebSocket for room $_currentRoomId"); // Changed
      print("Disconnecting Socket.IO for room $_currentRoomId"); // Changed
      // _channel!.sink.close(); // Removed
      _socket!.disconnect(); // Changed for Socket.IO
      _messageStreamController?.close();
      // _channel = null; // Removed
      _socket = null; // Added
      _messageStreamController = null;
      _currentRoomId = null;
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessageHistory(int roomId) async {
    // Optional: Check network connectivity first
    try {
      final messages = await remoteDataSource.getMessageHistory(roomId);
      // Map to domain entities if needed
      return messages;
    } on ServerException catch (e) {
      // Handle or re-throw specific exceptions
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<void> sendTextMessage(
      {required int roomId, required String text}) async {
    // if (_channel == null || _currentRoomId != roomId) { // Changed
    // Removed !_socket!.connected check - let Socket.IO buffer if needed
    if (_socket == null || _currentRoomId != roomId) {
      // Changed
      // print("WebSocket not connected to room $roomId. Cannot send message."); // Changed
      print(
          "Socket.IO not connected to room $roomId. Cannot send message."); // Changed
      // Optionally try to reconnect or throw error
      // _connect(roomId); // Attempt reconnect? Risky if called rapidly.
      throw ServerException(message: "Not connected to chat room $roomId");
    }
    // print("ChatRepository: Sending text '$text' via WebSocket to room $roomId"); // Changed
    print(
        "ChatRepository: Sending text '$text' via Socket.IO to room $roomId"); // Changed
    try {
      // Send message structure expected by backend
      /* // Old WebSocket logic removed
      _channel!.sink.add(jsonEncode({
        'event': 'sendMessage',
        'data': {
          'roomId': roomId,
          'messageText': text,
        }
      }));
      */
      // Emit 'sendMessage' event with data object for Socket.IO
      _socket!.emit('sendMessage', {
        'roomId': roomId,
        'messageText': text,
      }); // Changed for Socket.IO
    } catch (e) {
      // print("Error sending message via WebSocket: $e"); // Changed
      print("Error sending message via Socket.IO: $e"); // Changed
      // throw ServerException(message: "Failed to send message via WebSocket."); // Changed
      throw ServerException(
          message: "Failed to send message via Socket.IO."); // Changed
    }
  }

  @override
  Future<void> sendFileMessage(
      {required int roomId, required String filePath}) async {
    // Optional: Check network connectivity first
    try {
      // Call the remote data source to upload the file.
      // The backend currently doesn't broadcast file messages via WebSocket upon upload.
      // The message will appear when history is reloaded or WebSocket broadcast is added later.
      final ChatMessageModel uploadedMessage =
          await remoteDataSource.uploadFile(
        roomId: roomId,
        filePath: filePath,
      );
      print(
          "ChatRepository: File uploaded successfully, message ID: ${uploadedMessage.messageId}");
      // Optionally, could manually add the returned message to the stream controller
      // if immediate UI update without WebSocket broadcast is desired (less ideal).
      // _messageStreamController?.add(uploadedMessage);
    } on ServerException catch (e) {
      // Handle or re-throw specific exceptions
      print("ChatRepository: Error uploading file: ${e.message}");
      throw ServerException(message: e.message);
    } catch (e) {
      print("ChatRepository: Unexpected error uploading file: $e");
      throw ServerException(message: 'Unexpected error uploading file.');
    }
  }

  @override
  Stream<ChatMessageModel> getMessageStream(int roomId) {
    _connect(roomId); // Ensure connection is established for this room
    if (_messageStreamController == null) {
      // Should not happen if _connect works, but handle defensively
      print("Error: Message stream controller is null after connect attempt.");
      return Stream.error(
          "Failed to initialize message stream"); // Return error stream
    }
    print("ChatRepository: Returning message stream for room $roomId");
    return _messageStreamController!.stream;
  }

  @override
  void leaveRoom(int roomId) {
    if (_currentRoomId == roomId) {
      print("ChatRepository: Leaving room $roomId, disconnecting Socket.IO");
      // Optionally emit a 'leaveRoom' event to the backend if needed
      // _socket?.emit('leaveRoom', roomId);
      _disconnect();
    } else {
      print("ChatRepository: Not currently in room $roomId, cannot leave.");
    }
  }

  // Consider adding a dispose method if this repository is long-lived
  // void dispose() {
  //   _disconnect();
  // }
}
