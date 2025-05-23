import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import '../../../../core/di/injection_container.dart'; // Import GetIt
import '../../data/models/chat_message_model.dart'; // Import model for type check
import '../cubit/chat_cubit.dart'; // Import ChatCubit
import '../widgets/report_bottom_sheet.dart'; // Import our new report bottom sheet

// The main page for displaying chat messages and input
class ChatPage extends StatelessWidget {
  final int roomId;
  final String roomName;

  const ChatPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context) {
    // Provide ChatCubit instance, passing the necessary roomId
    return BlocProvider(
      // Create ChatCubit here, passing the repository and roomId
      create: (_) => ChatCubit(
        chatRepository: sl(), // Get repository from GetIt
        currentRoomId: roomId,
      )..loadHistory(), // Load history when the page is created
      child: ChatView(roomName: roomName), // Pass roomName to the view
    );
  }
}

// The view part of the ChatPage, handling UI based on ChatState
class ChatView extends StatefulWidget {
  final String roomName;
  const ChatView({super.key, required this.roomName});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // To scroll list

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatCubit>().sendTextMessage(text);
      _messageController.clear();
      // Optional: Scroll to bottom after sending
      // _scrollToBottom();
    }
  }

  // --- File Picking Logic ---
  void _attachFile() async {
    // Pick file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'pdf'
      ], // Allow images and PDFs
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      print("File picked: $filePath");
      // Call cubit method to handle upload (Need to add this method to Cubit)
      // ignore: use_build_context_synchronously
      context
          .read<ChatCubit>()
          .sendFileMessage(filePath); // Assuming sendFileMessage exists
    } else {
      // User canceled the picker or path is null
      print("File picking cancelled or failed.");
    }
  }
  // --- End File Picking Logic ---

  // Helper to scroll to the bottom of the list
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- Helper to build message content based on type ---
  Widget _buildMessageContent(BuildContext context, ChatMessageModel message) {
    // TODO: Get base URL properly (maybe from DI or config)
    const String baseUrl =
        'http://localhost:3000'; // Match backend static serving

    if (message.messageType == 'image' && message.fileUrl != null) {
      // Display image from network
      // Add error handling for Image.network if needed
      return Image.network(
        baseUrl + message.fileUrl!,
        // Optional: Add width, height, fit, loadingBuilder, errorBuilder
        height: 150, // Example height
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 50);
        },
      );
    } else if (message.messageType == 'pdf' && message.fileUrl != null) {
      // Display an icon and text, make it tappable to launch URL
      return InkWell(
        onTap: () => _launchURL(baseUrl + message.fileUrl!),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              // Use Expanded to prevent overflow
              child: Text(
                message.messageText ?? 'View PDF',
                style: const TextStyle(
                    decoration: TextDecoration.underline, color: Colors.blue),
                overflow: TextOverflow.ellipsis, // Handle long filenames
              ),
            ),
          ],
        ),
      );
    } else {
      // Default to text message
      return Text(message.messageText ?? '');
    }
  }

  // Helper to launch URL
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Use external app
      print('Could not launch $urlString');
      // Optionally show a snackbar to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $urlString')),
        );
      }
    }
  }
  // --- End Helper Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.roomName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Room settings or additional actions
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100], // Light background for chat
        ),
        child: Column(
          children: [
            // Message List Area
            Expanded(
              child: BlocConsumer<ChatCubit, ChatState>(
                listener: (context, state) {
                  if (state is ChatLoaded) {
                    // Scroll to bottom when new messages are loaded/added
                    _scrollToBottom();
                  } else if (state is ChatError) {
                    // Show error messages if needed (e.g., for sending failures)
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                          SnackBar(content: Text('Error: ${state.message}')));
                  }
                },
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    );
                  } else if (state is ChatLoaded) {
                    if (state.messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet. Start the conversation!',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final isMe = message.senderId ==
                            'currentUserId'; // Replace with actual user ID check

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.deepPurple : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        message.senderFullName ?? 'Unknown',
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  DefaultTextStyle(
                                    style: TextStyle(
                                      color:
                                          isMe ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                    child:
                                        _buildMessageContent(context, message),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else if (state is ChatError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(child: Text('Connecting to chat...'));
                },
              ),
            ),
            // Input Area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.attach_file,
                      color: Colors.deepPurple,
                    ),
                    onPressed: _attachFile,
                    tooltip: 'Attach File',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.deepPurple,
                    ),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
