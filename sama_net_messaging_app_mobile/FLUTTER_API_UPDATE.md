# Flutter API Endpoints Update

This document describes the updates made to the Flutter mobile app services to match the actual API implementation.

## Summary of Changes

### 1. API Constants Updated (`app_constants.dart`)

**Previous endpoints:**
- `/auth/login`, `/auth/register`, `/auth/refresh`, `/auth/logout`
- `/user/profile`, `/user/contacts`
- `/chats`, `/chats/{chatId}/messages`

**New endpoints (matching API):**
- `/users/login`, `/users/register`, `/users/search`, `/users/{id}`, `/users/{id}/last-seen`
- `/messages/send`, `/messages/send-with-attachment`, `/messages/conversation`
- `/messages/{id}/read`, `/messages/{id}/delivered`, `/messages/unread-count`
- `/files/upload`, `/files/download`, `/files/stream`, `/files/delete`

### 2. API Client Enhanced (`api_client.dart`)

**New features:**
- Added `setUserId()` method to handle `X-User-Id` header required by API
- Added `postMultipart()` method for file uploads with multipart/form-data
- Enhanced header management to include both Authorization and X-User-Id headers

### 3. Authentication Models Updated (`auth.dart`)

**Changes:**
- `LoginRequest`: Changed from `identifier` to `username` field
- `AuthResponse`: Updated to match API response format with `success`, `message`, `user`, `token` fields
- `RegisterRequest`: Updated to use `username`, `phoneNumber`, `displayName` fields
- Removed `UpdateProfileRequest` (not supported by current API)

### 4. User Model Restructured (`user.dart`)

**Previous fields:**
```dart
String id, name, email, phone, profileImageUrl, status
DateTime lastSeen
bool isOnline
```

**New fields (matching API):**
```dart
int id
String username, phoneNumber, displayName
DateTime createdAt, lastSeen
```

**New computed properties:**
- `name` getter returns `displayName` or `username`
- `isOnline` getter checks if `lastSeen` is within 5 minutes

### 5. Message Model Redesigned (`message.dart`)

**Previous structure:**
- String-based IDs
- Chat-based messaging
- Simple file attachments

**New structure (matching API):**
- Integer IDs for message, sender, receiver
- Direct user-to-user messaging
- Structured attachments with `MessageAttachment` model
- Timestamp-based status (sent, delivered, read)
- Support for multiple message types (text, image, video, audio, file)

### 6. New Models Added

#### `Conversation` model (`conversation.dart`)
```dart
class Conversation {
  final int id;
  final User otherUser;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime lastActivity;
}
```

#### `MessageAttachment` model (in `message.dart`)
```dart
class MessageAttachment {
  final int id;
  final String filePath;
  final String fileType;
  final int fileSize;
}
```

### 7. Services Restructured

#### `AuthService` (`auth_service.dart`)
**New methods:**
- `searchUsers(String phoneNumber)` - Search users by phone
- `getUserById(int userId)` - Get user details
- `updateLastSeen(int userId)` - Update user's last seen timestamp
- `setUserId(String? userId)` - Set user ID for API calls
- `logout()` - Clear authentication data

**Removed methods:**
- `refreshToken()`, `getProfile()`, `updateProfile()` - Not supported by API

#### `MessageService` (`message_service.dart`) - NEW
Dedicated service for message operations:
- `sendMessage()` - Send text messages
- `sendMessageWithAttachment()` - Send messages with files
- `getConversation()` - Get conversation history
- `markMessageAsRead()` / `markMessageAsDelivered()` - Update message status
- `getUnreadCount()` - Get unread message count
- `deleteMessage()` - Delete messages
- `getRecentConversations()` - Get recent conversation list

#### `FileService` (`file_service.dart`) - NEW
New service for file operations:
- `uploadFile()` - Upload files to server
- `downloadFile()` - Download files (basic implementation)
- `getStreamUrl()` - Get URL for streaming files
- `deleteFile()` - Delete files from server
- `isFileTypeSupported()` - Validate file types
- `getMessageTypeFromFile()` - Determine message type from file extension
- `getFileSize()` / `isFileSizeValid()` - File size validation

#### `ChatService` (`chat_service.dart`) - UPDATED
Updated to use new API endpoints while maintaining some backward compatibility:
- Simplified to focus on conversation management
- Uses new message and user models
- Delegates complex operations to MessageService and AuthService

### 8. Example Usage (`example_api_usage.dart`)

Created comprehensive example showing:
- Authentication flow (register/login)
- User search and management
- Message sending (text and files)
- File upload and management
- Conversation handling
- Message status updates
- Error handling patterns

## Migration Guide

### For existing code using AuthService:

```dart
// OLD
final loginRequest = LoginRequest(identifier: 'user@email.com', password: 'pass');

// NEW
final loginRequest = LoginRequest(username: 'username', password: 'pass');
```

### For existing code using ChatService:

```dart
// OLD - Chat-based messaging
await chatService.sendMessage(chatId, content);

// NEW - Direct user messaging
await messageService.sendMessage(receiverId: userId, content: content);
```

### For file operations:

```dart
// NEW - Proper file handling
final fileService = FileService(apiClient);
if (fileService.isFileTypeSupported(filePath)) {
  final response = await fileService.uploadFile(
    filePath: filePath,
    messageType: fileService.getMessageTypeFromFile(filePath),
  );
}
```

## API Headers Required

The API requires the `X-User-Id` header for most operations. This is automatically handled by:

1. Setting user ID after successful login:
```dart
// Automatically set in AuthService after login/register
_apiClient.setUserId(response.data!.user.id.toString());
```

2. The ApiClient automatically includes it in requests:
```dart
if (_userId != null) {
  headers['X-User-Id'] = _userId!;
}
```

## Error Handling

All services return `ApiResponse<T>` objects with consistent error handling:

```dart
final response = await service.someMethod();
if (response.isSuccess) {
  final data = response.data!;
  // Handle success
} else {
  final error = response.error!;
  // Handle error
}
```

## Breaking Changes

1. **User ID type changed** from `String` to `int`
2. **Message structure completely changed** - no longer chat-based
3. **Authentication response format changed**
4. **File handling requires new FileService**
5. **Some endpoints removed** (refresh token, profile management)

## Next Steps

1. Update existing UI code to use new models
2. Replace old service calls with new methods
3. Test file upload/download functionality
4. Implement proper error handling throughout the app
5. Update state management (BLoCs/Providers) to work with new models
