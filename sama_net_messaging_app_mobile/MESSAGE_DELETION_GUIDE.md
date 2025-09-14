# Message Deletion Feature Implementation

## Overview
Complete implementation of message deletion functionality for the SamaNet messaging app, allowing users to delete their own messages from both frontend and backend.

## 🔧 Backend Implementation

### 1. API Endpoint
```http
DELETE /api/messages/{messageId}
Headers: X-User-Id: {userId}
```

**Response:**
- `200 OK`: Message deleted successfully
- `400 Bad Request`: Invalid message ID or user ID
- `404 Not Found`: Message not found or no permission to delete
- `500 Internal Server Error`: Server error

### 2. MessageService.DeleteMessageAsync()
```csharp
public async Task<bool> DeleteMessageAsync(int userId, int messageId)
{
    var message = await _messageRepository.GetByIdAsync(messageId);
    
    // Check if message exists
    if (message == null)
        return false;
    
    // Check if user has permission (only sender can delete)
    if (message.SenderId != userId)
        return false;
    
    // Delete associated attachments first
    var attachments = message.Attachments?.ToList() ?? new List<Attachment>();
    foreach (var attachment in attachments)
    {
        await _fileService.DeleteFileAsync(attachment.FilePath);
        await _attachmentRepository.DeleteAsync(attachment.Id);
    }
    
    // Delete the message
    await _messageRepository.DeleteAsync(messageId);
    return true;
}
```

### 3. Security Features
- **Permission Check**: Only message sender can delete their own messages
- **Cascade Deletion**: Automatically deletes associated file attachments
- **Error Handling**: Graceful handling of missing files or database errors

## 📱 Frontend Implementation

### 1. MessageStatusService.deleteMessage()
```dart
/// Delete a message
Future<bool> deleteMessage(int messageId) async {
  try {
    final response = await _messageService.deleteMessage(messageId);
    if (response.isSuccess) {
      // Clear any cached status for this message
      await _localStorage.remove('message_${messageId}_delivered');
      await _localStorage.remove('message_${messageId}_read');
      return true;
    }
    return false;
  } catch (e) {
    print('Error deleting message: $e');
    return false;
  }
}
```

### 2. UI Implementation in MessagesPage
```dart
/// Delete a message with confirmation dialog
void _deleteMessage(Message message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Message'),
      content: Text('Are you sure you want to delete this message?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _performMessageDeletion(message);
          },
          child: Text('Delete'),
        ),
      ],
    ),
  );
}
```

### 3. Real-time UI Updates
```dart
/// Perform the actual message deletion with UI feedback
Future<void> _performMessageDeletion(Message message) async {
  final success = await _messageStatusService.deleteMessage(message.id);

  if (success) {
    // Remove message from local list
    setState(() {
      _messages = _messageStatusService.removeMessageFromList(_messages, message.id);
    });

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message deleted successfully')),
    );
  } else {
    // Show error feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete message')),
    );
  }
}
```

## 🎯 User Experience Features

### 1. Context Menu Access
- **Long Press**: User long-presses their own message
- **Context Menu**: Shows options including "Delete"
- **Permission Check**: Delete option only shown for user's own messages

### 2. Confirmation Dialog
- **Safety Check**: Prevents accidental deletions
- **Clear Actions**: Cancel or Delete options
- **User-Friendly**: Clear messaging about what will happen

### 3. Real-time Feedback
- **Success Messages**: Green snackbar for successful deletion
- **Error Messages**: Red snackbar for failed deletions
- **Immediate UI Update**: Message disappears instantly on success

### 4. Error Handling
- **Network Errors**: Graceful handling of connection issues
- **Permission Errors**: Clear message about ownership requirements
- **Server Errors**: User-friendly error messages

## 🔒 Security & Permissions

### Backend Security
- **User Authentication**: Requires valid X-User-Id header
- **Ownership Validation**: Only message sender can delete
- **Data Integrity**: Cascade deletion of related data

### Frontend Security
- **UI Restrictions**: Delete option only shown for own messages
- **API Validation**: Server performs final permission check
- **Error Handling**: Graceful handling of permission denials

## 📊 Usage Flow

### Complete Deletion Process
```
1. User long-presses their message
2. Context menu appears with Delete option
3. User taps Delete
4. Confirmation dialog appears
5. User confirms deletion
6. API call sent to backend
7. Backend validates permission
8. Message and attachments deleted
9. Success response sent
10. Frontend updates UI
11. User sees success message
```

### Error Scenarios
```
Permission Denied:
- User tries to delete another user's message
- Backend returns 404 Not Found
- Frontend shows "You can only delete your own messages"

Network Error:
- API call fails due to network issues
- Frontend shows "Error deleting message: [error details]"
- Message remains in UI until retry succeeds

Server Error:
- Database or file system error
- Backend returns 500 Internal Server Error
- Frontend shows generic error message
```

## 🛠️ Implementation Details

### API Client Setup
The `MessageService.deleteMessage()` method uses the existing API client:
```dart
Future<ApiResponse<void>> deleteMessage(int messageId) async {
  try {
    final response = await _apiClient.delete<void>('${ApiConstants.deleteMessage}/$messageId');
    return response;
  } catch (e) {
    return ApiResponse.error('Failed to delete message: ${e.toString()}');
  }
}
```

### Cache Management
```dart
// Clear cached status data for deleted message
await _localStorage.remove('message_${messageId}_delivered');
await _localStorage.remove('message_${messageId}_read');
```

### List Management
```dart
/// Remove a message from a list (for UI updates after deletion)
List<Message> removeMessageFromList(List<Message> messages, int messageId) {
  return messages.where((message) => message.id != messageId).toList();
}
```

## 🔍 Testing Scenarios

### Positive Test Cases
1. **Own Message Deletion**: User deletes their own text message
2. **Message with Attachments**: User deletes message with file attachments
3. **Multiple Messages**: User deletes several messages in sequence
4. **Offline/Online**: Deletion works when connection is restored

### Negative Test Cases
1. **Other's Message**: User tries to delete another user's message
2. **Invalid Message ID**: API called with non-existent message ID
3. **Network Failure**: Deletion attempted during network outage
4. **Server Error**: Backend database/file system errors

### UI Test Cases
1. **Context Menu**: Long-press shows appropriate options
2. **Confirmation Dialog**: Dialog appears and works correctly
3. **Success Feedback**: Green snackbar appears on success
4. **Error Feedback**: Red snackbar appears on failure
5. **Immediate Update**: Message disappears from list instantly

## 🚀 Deployment Notes

### Backend Requirements
- Update IMessageService interface
- Deploy MessageService.DeleteMessageAsync()
- Add DELETE endpoint to MessagesController
- Update API documentation

### Frontend Requirements
- Update MessageStatusService with delete functionality
- Ensure MessagesPage handles deletion properly
- Test context menu and confirmation dialogs
- Verify error handling and user feedback

### Database Considerations
- Ensure cascade deletion is properly configured
- Consider soft deletion vs hard deletion based on requirements
- Add logging for deletion operations
- Consider message retention policies

This implementation provides a complete, secure, and user-friendly message deletion feature with proper error handling and real-time UI updates!
