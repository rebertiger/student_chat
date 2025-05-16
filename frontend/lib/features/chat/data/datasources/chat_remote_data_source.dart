import 'package:dio/dio.dart'; // Import Dio
import 'package:http_parser/http_parser.dart'; // Import MediaType
import 'package:path/path.dart' as p; // Import path package

import '../../../../features/auth/data/datasources/auth_remote_data_source.dart'; // For ServerException
import '../models/chat_message_model.dart';
import '../models/report_model.dart';

// Abstract interface for fetching chat data from remote API
abstract class ChatRemoteDataSource {
  /// Calls GET /api/rooms/:roomId/messages endpoint.
  Future<List<ChatMessageModel>> getMessageHistory(int roomId);

  /// Calls POST /api/rooms/:roomId/files endpoint to upload a file.
  /// Returns the newly created ChatMessageModel for the file.
  Future<ChatMessageModel> uploadFile(
      {required int roomId, required String filePath /* or File object */});

  /// Calls POST /api/reports/message endpoint to report a message.
  Future<ReportModel> reportMessage({
    required int messageId,
    int? reportedBy,
    String? reason,
  });

  // Sending text messages will likely be handled via WebSocket, not REST API.
}

// Implementation using Dio
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dioClient;

  ChatRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ChatMessageModel>> getMessageHistory(int roomId) async {
    print("ChatRemoteDataSource: Fetching history for room $roomId");
    try {
      // TODO: Add authentication headers if required by backend middleware later
      final response = await dioClient.get('/rooms/$roomId/messages');
      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = response.data as List<dynamic>;
        return messagesJson
            .map((json) =>
                ChatMessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
            message: 'Failed to fetch messages: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] as String? ??
          e.message ??
          'Unknown error fetching messages';
      throw ServerException(message: message);
    } catch (e) {
      throw ServerException(
          message: 'An unexpected error occurred fetching messages.');
    }
  }

  @override
  Future<ChatMessageModel> uploadFile(
      {required int roomId, required String filePath}) async {
    print("ChatRemoteDataSource: Uploading file '$filePath' to room $roomId");
    try {
      String fileName = filePath.split('/').last;
      String mimeType = 'application/octet-stream'; // Default
      final fileExtension = p.extension(filePath).toLowerCase();
      if (fileExtension == '.pdf') {
        mimeType = 'application/pdf';
      } else if (['.jpg', '.jpeg', '.png', '.gif'].contains(fileExtension)) {
        mimeType = 'image/${fileExtension.substring(1)}';
      }

      FormData formData = FormData.fromMap({
        // Backend expects the file under the key 'file' (based on upload.single('file'))
        "file": await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType:
              MediaType.parse(mimeType), // Belirlenen MIME tipini kullan
        ),
      });

      // TODO: Add authentication headers if required by backend middleware later
      final response = await dioClient.post(
        '/rooms/$roomId/files',
        data: formData,
        // Optional: Add onSendProgress callback for upload progress indication
        // onSendProgress: (int sent, int total) {
        //   print('Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        // },
      );

      if (response.statusCode == 201) {
        // Assuming backend returns { message: '...', messageData: { ... } }
        return ChatMessageModel.fromJson(
            response.data['messageData'] as Map<String, dynamic>);
      } else {
        throw ServerException(
            message: 'File upload failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] as String? ??
          e.message ??
          'Unknown error uploading file';
      throw ServerException(message: message);
    } catch (e) {
      throw ServerException(
          message: 'An unexpected error occurred uploading file.');
    }
  }

  @override
  Future<ReportModel> reportMessage({
    required int messageId,
    int? reportedBy,
    String? reason,
  }) async {
    print("ChatRemoteDataSource: Reporting message $messageId");
    try {
      final response = await dioClient.post(
        '/reports/message',
        data: {
          'messageId': messageId,
          'reportedBy': reportedBy,
          'reason': reason,
        },
      );

      if (response.statusCode == 201) {
        return ReportModel.fromJson(
            response.data['report'] as Map<String, dynamic>);
      } else {
        throw ServerException(
            message: 'Failed to report message: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] as String? ??
          e.message ??
          'Unknown error reporting message';
      throw ServerException(message: message);
    } catch (e) {
      throw ServerException(
          message: 'An unexpected error occurred reporting message.');
    }
  }
}
