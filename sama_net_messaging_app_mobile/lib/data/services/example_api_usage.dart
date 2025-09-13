import 'package:sama_net_messaging_app_mobile/data/services/api_client.dart';

import '../models/auth.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../services/file_service.dart';
import '../services/chat_service.dart';
import '../../core/constants/app_constants.dart';

/// Example service that demonstrates how to use the updated API endpoints
class ExampleApiUsage {
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final MessageService _messageService;
  late final FileService _fileService;
  late final ChatService _chatService;

  ExampleApiUsage() {
    _apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);
    _authService = AuthService(_apiClient);
    _messageService = MessageService(_apiClient);
    _fileService = FileService(_apiClient);
    _chatService = ChatService(_apiClient);
  }

  /// Example: User registration and login flow
  Future<void> exampleAuthFlow() async {
    // Register a new user
    final registerRequest = RegisterRequest(
      username: 'john_doe',
      password: 'securePassword123',
      phoneNumber: '+1234567890',
      displayName: 'John Doe',
    );

    final registerResponse = await _authService.register(registerRequest);
    if (registerResponse.isSuccess) {
      print('Registration successful: ${registerResponse.data?.message}');
      // Token and user ID are automatically set in ApiClient
    } else {
      print('Registration failed: ${registerResponse.error}');
      return;
    }

    // Or login with existing credentials
    final loginRequest = LoginRequest(username: 'john_doe', password: 'securePassword123');

    final loginResponse = await _authService.login(loginRequest);
    if (loginResponse.isSuccess) {
      print('Login successful: ${loginResponse.data?.user?.name}');
    } else {
      print('Login failed: ${loginResponse.error}');
    }
  }

  /// Example: Search for users and start a conversation
  Future<void> exampleUserSearch() async {
    // Search for users by phone number
    final searchResponse = await _authService.searchUsers('+1987654321');
    if (searchResponse.isSuccess) {
      final users = searchResponse.data ?? [];
      print('Found ${users.length} users');

      for (final user in users) {
        print('User: ${user.name} (${user.phoneNumber})');
      }
    } else {
      print('Search failed: ${searchResponse.error}');
    }
  }

  /// Example: Send different types of messages
  Future<void> exampleMessageFlow() async {
    const receiverId = 2; // Example receiver ID

    // Send a text message
    final textResponse = await _messageService.sendMessage(
      receiverId: receiverId,
      content: 'Hello! How are you?',
      messageType: 'text',
    );

    if (textResponse.isSuccess) {
      print('Text message sent: ${textResponse.data?.id}');
    } else {
      print('Failed to send text message: ${textResponse.error}');
    }

    // Send an image with attachment
    final imageResponse = await _messageService.sendMessageWithAttachment(
      receiverId: receiverId,
      content: 'Check out this image!',
      messageType: 'image',
      filePath: '/path/to/image.jpg',
    );

    if (imageResponse.isSuccess) {
      print('Image message sent: ${imageResponse.data?.id}');
    } else {
      print('Failed to send image: ${imageResponse.error}');
    }
  }

  /// Example: File upload and management
  Future<void> exampleFileOperations() async {
    const filePath = '/path/to/document.pdf';

    // Check if file is supported and within size limits
    if (!_fileService.isFileTypeSupported(filePath)) {
      print('File type not supported');
      return;
    }

    final fileSize = await _fileService.getFileSize(filePath);
    if (!_fileService.isFileSizeValid(fileSize)) {
      print('File size too large');
      return;
    }

    // Upload file
    final messageType = _fileService.getMessageTypeFromFile(filePath);
    final uploadResponse = await _fileService.uploadFile(filePath: filePath, messageType: messageType);

    if (uploadResponse.isSuccess) {
      print('File uploaded: ${uploadResponse.data?.filePath}');

      // Get stream URL for viewing
      final streamUrl = _fileService.getStreamUrl(uploadResponse.data!.filePath!);
      print('Stream URL: $streamUrl');
    } else {
      print('File upload failed: ${uploadResponse.error}');
    }
  }

  /// Example: Get and manage conversations
  Future<void> exampleConversationFlow() async {
    // Get recent conversations
    final conversationsResponse = await _chatService.getRecentConversations(limit: 10);
    if (conversationsResponse.isSuccess) {
      final conversations = conversationsResponse.data ?? [];
      print('Found ${conversations.length} recent conversations');

      for (final conversation in conversations) {
        print('Conversation with ${conversation.otherUser.name}');
        print('Unread messages: ${conversation.unreadCount}');
        if (conversation.lastMessage != null) {
          print('Last message: ${conversation.lastMessage!.content}');
        }
      }
    }

    // Get messages from a specific conversation
    const otherUserId = 2;
    final messagesResponse = await _chatService.getConversation(otherUserId: otherUserId, page: 1, pageSize: 50);

    if (messagesResponse.isSuccess) {
      final messages = messagesResponse.data ?? [];
      print('Found ${messages.length} messages in conversation');

      for (final message in messages) {
        print('${message.senderUsername}: ${message.content}');
        print('Status: ${message.status.value}');
      }
    }
  }

  /// Example: Message status management
  Future<void> exampleMessageStatus() async {
    const messageId = 123;

    // Mark message as delivered
    final deliveredResponse = await _messageService.markMessageAsDelivered(messageId);
    if (deliveredResponse.isSuccess) {
      print('Message marked as delivered');
    }

    // Mark message as read
    final readResponse = await _messageService.markMessageAsRead(messageId);
    if (readResponse.isSuccess) {
      print('Message marked as read');
    }

    // Get unread message count
    final unreadResponse = await _messageService.getUnreadCount();
    if (unreadResponse.isSuccess) {
      print('Unread messages: ${unreadResponse.data}');
    }
  }

  /// Example: User status management
  Future<void> exampleUserStatus() async {
    const userId = 1;

    // Update last seen
    final lastSeenResponse = await _authService.updateLastSeen(userId);
    if (lastSeenResponse.isSuccess) {
      print('Last seen updated');
    }

    // Get user info
    final userResponse = await _authService.getUserById(userId);
    if (userResponse.isSuccess) {
      final user = userResponse.data!;
      print('User: ${user.name}');
      print('Online: ${user.isOnline}');
      print('Last seen: ${user.lastSeen}');
    }
  }

  /// Example: Error handling patterns
  Future<void> exampleErrorHandling() async {
    final response = await _messageService.sendMessage(
      receiverId: 999, // Non-existent user
      content: 'Test message',
    );

    if (response.isSuccess) {
      // Handle success
      final message = response.data!;
      print('Message sent successfully: ${message.id}');
    } else {
      // Handle error
      final error = response.error!;
      print('Error occurred: $error');

      // You can check for specific error types
      if (error.contains('not found')) {
        // Handle user not found
        print('Recipient not found');
      } else if (error.contains('Network error')) {
        // Handle network issues
        print('Network connectivity issue');
      } else {
        // Handle other errors
        print('Unknown error occurred');
      }
    }
  }

  /// Clean up resources
  void dispose() {
    // Clear authentication when done
    _authService.logout();
  }
}

/// Usage example
void main() async {
  final example = ExampleApiUsage();

  try {
    await example.exampleAuthFlow();
    await example.exampleUserSearch();
    await example.exampleMessageFlow();
    await example.exampleFileOperations();
    await example.exampleConversationFlow();
    await example.exampleMessageStatus();
    await example.exampleUserStatus();
    await example.exampleErrorHandling();
  } finally {
    example.dispose();
  }
}
