import '../models/message.dart';
import '../models/user.dart';
import '../models/conversation.dart';
import '../../core/constants/app_constants.dart';
import 'api_client.dart';

/// Chat service for handling chat operations (legacy - use MessageService for new implementations)
class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  /// Search for users by phone number
  Future<ApiResponse<List<User>>> searchUsers(String phoneNumber) async {
    try {
      final response = await _apiClient.get<List<User>>(
        ApiConstants.searchUsers,
        queryParams: {'phoneNumber': phoneNumber},
        fromJson: (json) {
          final usersData = json as List<dynamic>? ?? [];
          return usersData.map((userJson) => User.fromJson(userJson as Map<String, dynamic>)).toList();
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to search users: ${e.toString()}');
    }
  }

  /// Get recent conversations
  Future<ApiResponse<List<Conversation>>> getRecentConversations({int limit = 20}) async {
    try {
      final response = await _apiClient.get<List<Conversation>>(
        ApiConstants.getRecentConversations,
        queryParams: {'limit': limit.toString()},
        fromJson: (json) {
          final conversationsData = json as List<dynamic>? ?? [];
          return conversationsData.map((convJson) => Conversation.fromJson(convJson as Map<String, dynamic>)).toList();
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get conversations: ${e.toString()}');
    }
  }

  /// Get conversation messages between current user and another user
  Future<ApiResponse<List<Message>>> getConversation({
    required int otherUserId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.get<List<Message>>(
        ApiConstants.getConversation,
        queryParams: {'otherUserId': otherUserId.toString(), 'page': page.toString(), 'pageSize': pageSize.toString()},
        fromJson: (json) {
          final messagesData = json as List<dynamic>? ?? [];
          return messagesData.map((messageJson) => Message.fromJson(messageJson as Map<String, dynamic>)).toList();
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get conversation: ${e.toString()}');
    }
  }

  /// Send a text message
  Future<ApiResponse<Message>> sendMessage({
    required int receiverId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final response = await _apiClient.post<Message>(
        ApiConstants.sendMessage,
        body: {'receiverId': receiverId, 'content': content, 'messageType': messageType},
        fromJson: (json) => Message.fromJson(json),
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to send message: ${e.toString()}');
    }
  }

  /// Send a message with file attachment
  Future<ApiResponse<Message>> sendMessageWithAttachment({
    required int receiverId,
    required String content,
    required String messageType,
    required String filePath,
  }) async {
    try {
      final response = await _apiClient.postMultipart<Message>(
        ApiConstants.sendMessageWithAttachment,
        fields: {'receiverId': receiverId.toString(), 'content': content, 'messageType': messageType},
        filePath: filePath,
        fileFieldName: 'file',
        fromJson: (json) => Message.fromJson(json),
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to send message with attachment: ${e.toString()}');
    }
  }

  /// Mark messages as read
  Future<ApiResponse<void>> markMessageAsRead(int messageId) async {
    try {
      final response = await _apiClient.put<void>('${ApiConstants.markMessageAsRead}/$messageId/read');
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to mark message as read: ${e.toString()}');
    }
  }

  /// Get unread message count
  Future<ApiResponse<int>> getUnreadCount() async {
    try {
      final response = await _apiClient.get<int>(
        ApiConstants.getUnreadCount,
        fromJson: (json) => json['count'] as int? ?? 0,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get unread count: ${e.toString()}');
    }
  }
}
