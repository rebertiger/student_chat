import 'dart:async'; // For StreamSubscription
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Import necessary models, repository, exceptions
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/chat_repository.dart'; // Will create this next
import '../../../../features/auth/data/datasources/auth_remote_data_source.dart'; // For ServerException

// Import WebSocket service if separate, or handle within repository
// import '../../../../core/services/websocket_service.dart';

part 'chat_state.dart'; // Include the state definitions

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository chatRepository;
  final int currentRoomId; // Keep track of the room this cubit instance is for
  StreamSubscription? _messageSubscription; // To listen for new messages

  ChatCubit({required this.chatRepository, required this.currentRoomId})
      : super(ChatInitial()) {
    _listenForMessages(); // Start listening when cubit is created
  }

  // Method to load initial message history
  Future<void> loadHistory() async {
    if (state is ChatLoading) return; // Prevent concurrent loading
    emit(ChatLoading());
    try {
      final messages = await chatRepository.getMessageHistory(currentRoomId);
      emit(ChatLoaded(messages: messages));
    } on ServerException catch (e) {
      emit(ChatError(message: e.message));
    } catch (e) {
      emit(ChatError(
          message: 'Failed to load message history: ${e.toString()}'));
    }
  }

  // Method to send a text message (will use WebSocket later)
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    // Placeholder: Directly add to state for UI feedback, real implementation uses WebSocket
    // final tempMessage = ChatMessageModel(...); // Create a temporary message
    // if (state is ChatLoaded) {
    //   emit((state as ChatLoaded).copyWithNewMessage(tempMessage));
    // }
    try {
      await chatRepository.sendTextMessage(roomId: currentRoomId, text: text);
      // Message is sent, UI update will happen when it's received back via WebSocket
    } on ServerException catch (e) {
      emit(ChatError(message: 'Failed to send message: ${e.message}'));
      // TODO: Handle message sending failure (e.g., remove temp message, show error indicator)
    } catch (e) {
      emit(ChatError(
          message:
              'An unexpected error occurred sending message: ${e.toString()}'));
    }
  }

  // Method to send a file message
  Future<void> sendFileMessage(String filePath) async {
    // Optionally emit a specific 'UploadingFile' state
    // emit(ChatUploadingFile()); // Need to define this state
    print("ChatCubit: Sending file $filePath");
    try {
      await chatRepository.sendFileMessage(
          roomId: currentRoomId, filePath: filePath);
      // Success! The backend doesn't broadcast file messages yet,
      // so the UI won't update automatically via WebSocket for this.
      // It will appear on next history load or when WebSocket broadcast is added.
      // We could manually add a temporary message or the returned message if needed.
    } on ServerException catch (e) {
      emit(ChatError(message: 'Failed to send file: ${e.message}'));
    } catch (e) {
      emit(ChatError(
          message:
              'An unexpected error occurred sending file: ${e.toString()}'));
    }
  }

  // Method called by WebSocket listener when a new message arrives
  void receiveNewMessage(ChatMessageModel message) {
    if (state is ChatLoaded) {
      // Add the new message to the existing list
      emit((state as ChatLoaded).copyWithNewMessage(message));
    } else {
      // If messages weren't loaded yet, maybe load them now? Or just hold the message?
      // For simplicity, we might just load history first.
      print(
          "Received message but state is not ChatLoaded. Message: ${message.messageText}");
    }
  }

  // Listen to the message stream from the repository
  void _listenForMessages() {
    print("ChatCubit: Listening for messages in room $currentRoomId");
    _messageSubscription =
        chatRepository.getMessageStream(currentRoomId).listen((message) {
      receiveNewMessage(message);
    }, onError: (error) {
      emit(ChatError(message: 'WebSocket error: ${error.toString()}'));
    }, onDone: () {
      print("ChatCubit: WebSocket connection closed for room $currentRoomId");
      // Optionally emit a state indicating disconnection
      // emit(ChatError(message: 'WebSocket connection closed.'));
    });
  }

  @override
  Future<void> close() {
    print("ChatCubit: Closing cubit for room $currentRoomId");
    _messageSubscription?.cancel(); // Cancel subscription when cubit is closed
    chatRepository.leaveRoom(currentRoomId); // Notify repository to disconnect
    return super.close();
  }
}
