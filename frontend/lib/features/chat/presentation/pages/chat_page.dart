import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'dart:io' show Platform; // Add Platform import
import '../../../../core/di/injection_container.dart'; // Import GetIt
import '../../data/models/chat_message_model.dart'; // Import model for type check
import '../cubit/chat_cubit.dart'; // Import ChatCubit
import '../widgets/report_bottom_sheet.dart'; // Import our new report bottom sheet
import 'package:flutter/foundation.dart';

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
    // Platform-specific base URL
    final String baseUrl = Platform.isAndroid
        ? 'http://10.0.2.2:3000' // Android emulator
        : 'http://localhost:3000'; // iOS simulator

    if (message.messageType == 'image' && message.fileUrl != null) {
      // Display image from network with tap to preview
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Stack(
                  children: [
                    // Full screen image
                    InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        baseUrl + message.fileUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return const Icon(Icons.broken_image, size: 50);
                        },
                      ),
                    ),
                    // Close button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              baseUrl + message.fileUrl!,
              height: 150,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return const Icon(Icons.broken_image, size: 50);
              },
            ),
          ),
        ),
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
              child: Text(
                message.messageText ?? 'View PDF',
                style: const TextStyle(
                    decoration: TextDecoration.underline, color: Colors.blue),
                overflow: TextOverflow.ellipsis,
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
        title: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    widget.roomName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (state is ChatLoaded)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.totalMessages} messages',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
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
                                gradient: isMe
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF8E2DE2),
                                          Color(0xFF4A00E0)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFFF8F8F8),
                                          Color(0xFFEDEDED)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(isMe ? 16 : 4),
                                  topRight: Radius.circular(isMe ? 4 : 16),
                                  bottomLeft: const Radius.circular(16),
                                  bottomRight: const Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: isMe
                                    ? null
                                    : Border.all(
                                        color:
                                            Colors.deepPurple.withOpacity(0.08),
                                        width: 1),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              margin: EdgeInsets.only(
                                top: 6,
                                bottom: 6,
                                left: isMe ? 40 : 0,
                                right: isMe ? 0 : 40,
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
                                              : Colors.deepPurple,
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
                                  // Move the report button below the message content, outside the message bubble if desired
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.flag_outlined,
                                            size: 16),
                                        tooltip: 'Report Message',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          ReportBottomSheet.show(
                                            context,
                                            messageId: message.messageId,
                                            chatCubit:
                                                context.read<ChatCubit>(),
                                            messageText: message.messageText,
                                            senderName: message.senderFullName,
                                          );
                                        },
                                      )
                                    ],
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
