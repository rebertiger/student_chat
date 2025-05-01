part of 'chat_cubit.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

// Initial state
class ChatInitial extends ChatState {}

// State while loading message history
class ChatLoading extends ChatState {}

// State when messages are loaded or updated
class ChatLoaded extends ChatState {
  final List<ChatMessageModel> messages;

  const ChatLoaded({required this.messages});

  @override
  List<Object?> get props => [messages]; // Compare based on the list content

  // Helper for adding a new message immutably
  ChatLoaded copyWithNewMessage(ChatMessageModel newMessage) {
    // Eğer aynı messageId'ye sahip bir mesaj zaten varsa ekleme
    if (messages.any((msg) => msg.messageId == newMessage.messageId)) {
      return this;
    }
    return ChatLoaded(messages: List.unmodifiable([...messages, newMessage]));
  }

  // Helper for adding multiple messages immutably
  ChatLoaded copyWithMessages(List<ChatMessageModel> newMessages) {
    // Simple append, could add sorting/deduplication later if needed
    return ChatLoaded(
        messages: List.unmodifiable([...messages, ...newMessages]));
  }
}

// State when sending a message (optional, could just update ChatLoaded)
// class ChatSending extends ChatState {}

// State when an error occurs
class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}
