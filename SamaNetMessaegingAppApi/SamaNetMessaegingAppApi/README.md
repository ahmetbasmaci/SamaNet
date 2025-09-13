# Chat Application API

A real-time chat application backend built with ASP.NET Core Web API, Entity Framework Core, and SQLite.

## Features

- **User Authentication**: Login and registration with username/password
- **Real-time Messaging**: WebSocket-based messaging using SignalR
- **File Attachments**: Support for images, videos, audio, and documents (up to 200MB)
- **Message Status Tracking**: Delivery and read receipts
- **User Search**: Find users by phone number
- **Conversation Management**: Paginated message history
- **Online Status**: Real-time user presence indicators
- **Typing Indicators**: See when users are typing

## Technology Stack

- **Framework**: ASP.NET Core 8.0 Web API
- **Database**: SQLite with Entity Framework Core
- **Real-time Communication**: SignalR
- **Authentication**: BCrypt password hashing
- **File Storage**: Local file system
- **Documentation**: Swagger/OpenAPI

## Database Schema

The application uses three main tables:

### Users
- Id (Primary Key)
- Username (Unique)
- PasswordHash
- PhoneNumber (Unique)
- DisplayName
- CreatedAt
- LastSeen

### Messages
- Id (Primary Key)
- SenderId (Foreign Key)
- ReceiverId (Foreign Key)
- MessageType (text, image, audio, video, file)
- Content
- SentAt
- DeliveredAt
- ReadAt

### Attachments
- Id (Primary Key)
- MessageId (Foreign Key)
- FilePath
- FileType
- FileSize

## API Endpoints

### Authentication & Users
- `POST /api/users/login` - User login
- `POST /api/users/register` - User registration
- `GET /api/users/search?phoneNumber={phone}` - Search users by phone
- `GET /api/users/{id}` - Get user by ID
- `PUT /api/users/{id}/last-seen` - Update last seen timestamp

### Messages (Require X-User-Id header)
- `GET /api/messages/status` - Get Messages API status
- `POST /api/messages/send` - Send text message (requires X-User-Id header)
- `POST /api/messages/send-with-attachment` - Send message with file (requires X-User-Id header)
- `GET /api/messages/conversation` - Get conversation history (requires X-User-Id header)
- `PUT /api/messages/{id}/read` - Mark message as read (requires X-User-Id header)
- `PUT /api/messages/{id}/delivered` - Mark message as delivered
- `GET /api/messages/unread-count` - Get unread message count (requires X-User-Id header)
- `GET /api/messages/{id}` - Get specific message

### Files
- `POST /api/files/upload` - Upload file
- `GET /api/files/download?filePath={path}` - Download file
- `GET /api/files/stream?filePath={path}` - Stream file for viewing
- `DELETE /api/files/delete?filePath={path}` - Delete file
- `POST /api/files/validate` - Validate file before upload
- `GET /api/files/info?filePath={path}` - Get file information

### Health Check
- `GET /api/health` - Basic health check
- `GET /api/health/detailed` - Detailed system information

## SignalR Hub

Connect to `/chatHub` for real-time messaging:

### Client Events (Send to Hub)
- `JoinChat(userId)` - Join chat with user ID
- `SendMessage(messageRequest)` - Send message to another user
- `MarkMessageAsRead(messageId)` - Mark message as read
- `StartTyping(receiverId)` - Indicate typing to user
- `StopTyping(receiverId)` - Stop typing indicator

### Server Events (Receive from Hub)
- `MessageSent(message)` - Confirmation of sent message
- `MessageReceived(message)` - New message received
- `MessageDelivered(data)` - Message delivery confirmation
- `MessageRead(data)` - Message read confirmation
- `UserOnline(userId)` - User came online
- `UserOffline(userId)` - User went offline
- `UserStartedTyping(userId)` - User started typing
- `UserStoppedTyping(userId)` - User stopped typing
- `Error(message)` - Error occurred

## Setup Instructions

1. **Install .NET 8 SDK**
2. **Clone the repository**
3. **Restore packages**:dotnet restore4. **Run the application**:dotnet run5. **Access the API**:
   - Swagger UI: `https://localhost:7000` (or your configured port)
   - API Base URL: `https://localhost:7000/api`
   - SignalR Hub: `https://localhost:7000/chatHub`

## Configuration

Edit `appsettings.json` to configure:
- Database connection string
- File upload limits and allowed types
- Logging levels
- CORS settings

## File Upload Guidelines

### Supported File Types
- **Images**: JPEG, PNG, GIF, WebP
- **Videos**: MP4, AVI, MOV, WMV
- **Audio**: MP3, WAV, OGG, MPEG
- **Documents**: PDF, DOC, DOCX, TXT

### File Size Limits
- Maximum file size: 200MB
- Recommended for optimal performance: Under 50MB

## Security Considerations

- Passwords are hashed using BCrypt
- File uploads are validated for type and size
- SQL injection protection via Entity Framework
- CORS configured for specific origins
- File paths are sanitized to prevent directory traversal

## Error Handling

The API returns appropriate HTTP status codes:
- `200 OK` - Success
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Authentication failed
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

Error responses include descriptive messages to help with debugging.

## Development

### Project StructureSamaNetMessaegingAppApi/
??? Controllers/          # API controllers
??? Data/                # Database context
??? DTOs/                # Data transfer objects
??? Hubs/                # SignalR hubs
??? Models/              # Entity models
??? Repositories/        # Data access layer
??? Services/            # Business logic layer
??? uploads/             # File storage (created at runtime)
??? Program.cs           # Application entry point
### Adding New Features
1. Create DTOs for request/response models
2. Add repository methods for data access
3. Implement service layer for business logic
4. Create controller endpoints
5. Update SignalR hub if real-time features needed
6. Add appropriate error handling and validation

## Testing

Use tools like:
- **Postman** for API testing
- **SignalR Client** for real-time testing
- **Browser** for file upload/download testing

## Deployment

For production deployment:
1. Update connection string for production database
2. Configure CORS for your domain
3. Set up HTTPS certificates
4. Configure file storage (consider cloud storage)
5. Set appropriate logging levels
6. Configure reverse proxy (IIS, Nginx, etc.)

## Support

For issues or questions, please check the API documentation in Swagger UI or contact the development team.