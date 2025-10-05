# User Block Feature Implementation Guide

## Overview
This document describes the implementation of the user block functionality in the SamaNet messaging application, covering both the C# backend API and Flutter mobile frontend.

## Backend Implementation (C#)

### 1. Database Model

**File**: `SamaNetMessaegingAppApi/Models/UserBlock.cs`

```csharp
public class UserBlock
{
    public int Id { get; set; }
    public int BlockerId { get; set; }
    public int BlockedUserId { get; set; }
    public DateTime BlockedAt { get; set; }
    
    // Navigation properties
    public virtual User? Blocker { get; set; }
    public virtual User? BlockedUser { get; set; }
}
```

**Database Table**: `UserBlocks`
- Unique constraint on (BlockerId, BlockedUserId) to prevent duplicate blocks
- Cascade delete when users are deleted
- Indexes for performance on BlockerId and BlockedUserId

### 2. Repository Layer

**Interface**: `Repositories/Interfaces/IUserBlockRepository.cs`

Methods:
- `BlockUserAsync(int blockerId, int blockedUserId)` - Block a user
- `UnblockUserAsync(int blockerId, int blockedUserId)` - Unblock a user
- `IsUserBlockedAsync(int blockerId, int blockedUserId)` - Check if blocked
- `GetBlockedUsersAsync(int blockerId)` - Get list of blocked users
- `GetBlockersAsync(int blockedUserId)` - Get list of users who blocked someone
- `IsBlockRelationshipAsync(int userId1, int userId2)` - Check any block relationship

**Implementation**: `Repositories/UserBlockRepository.cs`

### 3. Service Layer

**Interface**: `Services/Interfaces/IUserService.cs` (Extended)

New methods added:
- `BlockUserAsync(int blockerId, int blockedUserId)`
- `UnblockUserAsync(int blockerId, int blockedUserId)`
- `IsUserBlockedAsync(int blockerId, int blockedUserId)`
- `GetBlockedUsersAsync(int blockerId)`

**Implementation**: `Services/UserService.cs`

Features:
- Validates users exist before blocking
- Prevents self-blocking
- Checks for duplicate blocks
- Returns detailed status responses

### 4. DTOs

**File**: `DTOs/UserBlockDtos.cs`

```csharp
public class BlockUserRequestDto
{
    public int BlockedUserId { get; set; }
}

public class BlockedUserResponseDto
{
    public int Id { get; set; }
    public int BlockerId { get; set; }
    public int BlockedUserId { get; set; }
    public UserResponseDto? BlockedUser { get; set; }
    public DateTime BlockedAt { get; set; }
}

public class BlockStatusResponseDto
{
    public bool IsBlocked { get; set; }
    public string Message { get; set; }
}
```

### 5. API Endpoints

**Controller**: `Controllers/UsersController.cs`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/users/{blockerId}/block` | Block a user |
| DELETE | `/api/users/{blockerId}/unblock/{blockedUserId}` | Unblock a user |
| GET | `/api/users/{blockerId}/is-blocked/{blockedUserId}` | Check block status |
| GET | `/api/users/{blockerId}/blocked-users` | Get blocked users list |

### 6. Database Migration

**File**: `Migrations/20250104000000_AddUserBlockTable.cs`

Creates the UserBlocks table with:
- Primary key on Id
- Foreign keys to Users table (BlockerId, BlockedUserId)
- Unique index on (BlockerId, BlockedUserId)
- Individual indexes for query performance

### 7. Dependency Injection

**File**: `Program.cs`

Register the UserBlockRepository:
```csharp
services.AddScoped<IUserBlockRepository, UserBlockRepository>();
```

The UserService now requires IUserBlockRepository in its constructor.

## Frontend Implementation (Flutter)

### 1. Service Layer

**File**: `lib/data/services/user_block_service.dart`

```dart
class UserBlockService {
  Future<ApiResponse<BlockStatusResponse>> blockUser({
    required int blockerId,
    required int blockedUserId,
  });
  
  Future<ApiResponse<BlockStatusResponse>> unblockUser({
    required int blockerId,
    required int blockedUserId,
  });
  
  Future<ApiResponse<bool>> isUserBlocked({
    required int blockerId,
    required int blockedUserId,
  });
  
  Future<ApiResponse<List<BlockedUser>>> getBlockedUsers({
    required int blockerId,
  });
}
```

### 2. Models

**BlockStatusResponse**:
```dart
class BlockStatusResponse {
  final bool isBlocked;
  final String message;
}
```

**BlockedUser**:
```dart
class BlockedUser {
  final int id;
  final int blockerId;
  final int blockedUserId;
  final User? blockedUser;
  final DateTime blockedAt;
}
```

### 3. Dependency Injection

**File**: `lib/core/di/service_locator.dart`

Register UserBlockService:
```dart
serviceLocator.registerSingleton<UserBlockService>(
  UserBlockService(serviceLocator.get<ApiClient>())
);
```

### 4. UI Integration

**File**: `lib/presentation/pages/messages_page.dart`

Features:
- Block option in chat menu (three dots)
- Confirmation dialog before blocking
- Loading indicator during block operation
- Success/error messages via SnackBar
- Automatically navigates back after successful block
- Uses current user ID from LocalStorage

Implementation:
```dart
void _blockUser() async {
  // Show confirmation dialog
  // Get current user ID
  // Call UserBlockService.blockUser()
  // Show result and navigate back
}
```

### 5. Localization

**File**: `lib/core/constants/arabic_strings.dart`

New Arabic strings:
- `blockUser` - "حظر المستخدم"
- `unblockUser` - "إلغاء حظر المستخدم"
- `blockUserConfirm` - "هل تريد حظر هذا المستخدم؟"
- `userBlocked` - "تم حظر المستخدم بنجاح"
- `blockUserFailed` - "فشل حظر المستخدم"
- `blockedUsers` - "المستخدمون المحظورون"
- `noBlockedUsers` - "لا يوجد مستخدمون محظورون"
- `cannotSendToBlockedUser` - "لا يمكن إرسال رسائل لمستخدم محظور"

## Usage Examples

### Backend (C#)

```csharp
// Block a user
var result = await _userService.BlockUserAsync(userId: 1, blockedUserId: 2);
if (result.IsBlocked) {
    // User blocked successfully
}

// Check if blocked
bool isBlocked = await _userService.IsUserBlockedAsync(blockerId: 1, blockedUserId: 2);

// Get blocked users
var blockedUsers = await _userService.GetBlockedUsersAsync(blockerId: 1);
```

### Frontend (Flutter)

```dart
// Block a user
final response = await _userBlockService.blockUser(
  blockerId: currentUser.id,
  blockedUserId: targetUser.id,
);

if (response.isSuccess) {
  // Show success message
} else {
  // Show error message
}

// Get blocked users
final blockedResponse = await _userBlockService.getBlockedUsers(
  blockerId: currentUser.id,
);
```

## Future Enhancements

1. **Message Filtering**: Automatically filter messages from blocked users
2. **Search Filtering**: Hide blocked users from search results
3. **Blocked Users Page**: Dedicated UI to manage blocked users
4. **Mutual Block Detection**: UI indication when both users blocked each other
5. **Block Notifications**: Optional notifications when blocked/unblocked
6. **Block Reason**: Optional reason field for blocking
7. **Block Duration**: Temporary blocks with auto-expiry

## Testing

### Backend Tests
- Test blocking a user
- Test unblocking a user
- Test duplicate block prevention
- Test self-block prevention
- Test cascade deletion
- Test block status checks

### Frontend Tests
- Test block UI flow
- Test confirmation dialogs
- Test API integration
- Test error handling
- Test navigation after block

## Security Considerations

1. Users can only block/unblock using their own user ID
2. Authentication required for all block operations
3. Validation of user existence before blocking
4. Prevention of SQL injection through parameterized queries
5. Rate limiting should be considered for block operations

## Performance Considerations

1. Database indexes on BlockerId and BlockedUserId
2. Unique constraint prevents duplicate records
3. Efficient queries using Entity Framework
4. Lazy loading of navigation properties
5. Consider caching blocked user lists for frequent checks

## API Response Examples

### Block User Success
```json
{
  "isBlocked": true,
  "message": "User blocked successfully"
}
```

### Block User Error
```json
{
  "isBlocked": false,
  "message": "User not found"
}
```

### Get Blocked Users
```json
[
  {
    "id": 1,
    "blockerId": 1,
    "blockedUserId": 2,
    "blockedUser": {
      "id": 2,
      "username": "john_doe",
      "displayName": "John Doe",
      "phoneNumber": "+1234567890",
      "avatarPath": null,
      "createdAt": "2025-01-01T00:00:00Z",
      "lastSeen": "2025-01-04T10:30:00Z"
    },
    "blockedAt": "2025-01-04T12:00:00Z"
  }
]
```

## Database Schema

```sql
CREATE TABLE UserBlocks (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    BlockerId INTEGER NOT NULL,
    BlockedUserId INTEGER NOT NULL,
    BlockedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (BlockerId) REFERENCES Users(Id) ON DELETE CASCADE,
    FOREIGN KEY (BlockedUserId) REFERENCES Users(Id) ON DELETE CASCADE,
    UNIQUE(BlockerId, BlockedUserId)
);

CREATE INDEX IDX_UserBlocks_Blocker ON UserBlocks(BlockerId);
CREATE INDEX IDX_UserBlocks_Blocked ON UserBlocks(BlockedUserId);
CREATE UNIQUE INDEX IDX_UserBlocks_Unique ON UserBlocks(BlockerId, BlockedUserId);
```

## Migration Instructions

1. **Backend**: Run EF Core migrations or apply the migration script
2. **Frontend**: Update dependencies with `flutter pub get`
3. **Database**: Apply migration to create UserBlocks table
4. **Testing**: Verify block functionality in development environment
5. **Deployment**: Deploy backend and frontend updates together

---

**Implementation Date**: January 4, 2025
**Version**: 1.0.0
**Status**: ✅ Complete
