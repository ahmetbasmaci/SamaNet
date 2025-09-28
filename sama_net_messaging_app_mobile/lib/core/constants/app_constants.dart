/// API endpoints and configuration
class ApiConstants {
  // Base server URL - Update this to match your local API
  static const String baseServerUrl = 'http://10.0.2.2:7073'; // Android emulator default
  // static const String baseServerUrl = 'http://localhost:7073'; // Localhost (web/desktop)
  // static const String baseServerUrl = 'http://172.24.224.1:7073'; // Real device / LAN
  static const String chatHubUrl = '$baseServerUrl/chatHub';
  static const String baseUrl = '$baseServerUrl/api';

  // User/Authentication endpoints
  static const String login = '/users/login';
  static const String register = '/users/register';
  static const String searchUsers = '/users/search';
  static const String getUserById = '/users';
  static const String updateLastSeen = '/users';

  // Message endpoints
  static const String sendMessage = '/messages/send';
  static const String sendMessageWithAttachment = '/messages/send-with-attachment';
  static const String getConversation = '/messages/conversation';
  static const String markMessageAsRead = '/messages';
  static const String markMessageAsDelivered = '/messages';
  static const String getUnreadCount = '/messages/unread-count';
  static const String deleteMessage = '/messages';
  static const String getRecentConversations = '/messages/recent-conversations';

  // File endpoints
  static const String uploadFile = '/files/upload';
  static const String downloadFile = '/files/download';
  static const String streamFile = '/files/stream';
  static const String deleteFile = '/files/delete';

  // Health check
  static const String healthCheck = '/health';

  // Socket events
  static const String socketConnect = 'connect';
  static const String socketDisconnect = 'disconnect';
  static const String socketJoinRoom = 'join_room';
  static const String socketLeaveRoom = 'leave_room';
  static const String socketNewMessage = 'new_message';
  static const String socketMessageReceived = 'message_received';
  static const String socketMessageSent = 'message_sent';
  static const String socketTyping = 'typing';
  static const String socketStopTyping = 'stop_typing';

  // Request timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}

/// App-wide constants
class AppConstants {
  // Storage keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';

  // Message types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeFile = 'file';

  // Message status
  static const String messageStatusSending = 'sending';
  static const String messageStatusSent = 'sent';
  static const String messageStatusDelivered = 'delivered';
  static const String messageStatusRead = 'read';
  static const String messageStatusFailed = 'failed';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxMessageLength = 1000;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double avatarSize = 48.0;
  static const double smallAvatarSize = 32.0;
}

/// Error messages
class ErrorMessages {
  static const String noInternetConnection = 'No internet connection available';
  static const String serverError = 'Server error occurred. Please try again later';
  static const String invalidCredentials = 'Invalid email or password';
  static const String userNotFound = 'User not found';
  static const String emailAlreadyExists = 'Email already exists';
  static const String weakPassword = 'Password must be at least 6 characters';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidPhone = 'Please enter a valid phone number';
  static const String fieldRequired = 'This field is required';
  static const String messageTooLong = 'Message is too long';
  static const String fileTooLarge = 'File size is too large';
  static const String unsupportedFileType = 'Unsupported file type';
  static const String generalError = 'Something went wrong. Please try again';
}
