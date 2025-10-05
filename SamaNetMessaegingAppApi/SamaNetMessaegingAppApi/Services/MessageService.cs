using SamaNetMessaegingAppApi.DTOs;
using SamaNetMessaegingAppApi.Models;
using SamaNetMessaegingAppApi.Repositories.Interfaces;
using SamaNetMessaegingAppApi.Repositories;
using SamaNetMessaegingAppApi.Services.Interfaces;

namespace SamaNetMessaegingAppApi.Services
{
    /// <summary>
    /// Service implementation for message-related operations
    /// </summary>
    public class MessageService : IMessageService
    {
        private readonly IMessageRepository _messageRepository;
        private readonly IAttachmentRepository _attachmentRepository;
        private readonly IUserRepository _userRepository;
        private readonly IFileService _fileService;
        private readonly IMessageDeletionRepository _messageDeletionRepository;

        public MessageService(
            IMessageRepository messageRepository,
            IAttachmentRepository attachmentRepository,
            IUserRepository userRepository,
            IFileService fileService,
            IMessageDeletionRepository messageDeletionRepository)
        {
            _messageRepository = messageRepository;
            _attachmentRepository = attachmentRepository;
            _userRepository = userRepository;
            _fileService = fileService;
            _messageDeletionRepository = messageDeletionRepository;
        }

        public async Task<MessageResponseDto> SendMessageAsync(int senderId, SendMessageRequestDto request)
        {
            // Validate users exist
            if (!await _userRepository.ExistsAsync(senderId) || !await _userRepository.ExistsAsync(request.ReceiverId))
            {
                throw new ArgumentException("Invalid sender or receiver");
            }

            var message = new Message
            {
                SenderId = senderId,
                ReceiverId = request.ReceiverId,
                MessageType = request.MessageType,
                Content = request.Content,
                SentAt = DateTime.UtcNow
            };

            var createdMessage = await _messageRepository.CreateAsync(message);
            return MapToMessageResponseDto(createdMessage);
        }

        public async Task<MessageResponseDto> SendMessageWithAttachmentAsync(int senderId, SendMessageRequestDto request, IFormFile file)
        {
            // Validate users exist
            if (!await _userRepository.ExistsAsync(senderId) || !await _userRepository.ExistsAsync(request.ReceiverId))
            {
                throw new ArgumentException("Invalid sender or receiver");
            }

            // Upload file
            var fileResult = await _fileService.SaveFileAsync(file, request.MessageType);
            if (!fileResult.Success)
            {
                throw new InvalidOperationException(fileResult.Message);
            }

            var message = new Message
            {
                SenderId = senderId,
                ReceiverId = request.ReceiverId,
                MessageType = request.MessageType,
                Content = request.Content,
                SentAt = DateTime.UtcNow
            };

            var createdMessage = await _messageRepository.CreateAsync(message);

            // Create attachment
            var attachment = new Attachment
            {
                MessageId = createdMessage.Id,
                FilePath = fileResult.FilePath!,
                FileType = fileResult.FileType!,
                FileSize = fileResult.FileSize
            };

            await _attachmentRepository.CreateAsync(attachment);

            // Reload message with attachments
            var messageWithAttachments = await _messageRepository.GetByIdAsync(createdMessage.Id);
            return MapToMessageResponseDto(messageWithAttachments!);
        }

        public async Task<IEnumerable<MessageResponseDto>> GetConversationAsync(int currentUserId, ConversationRequestDto request)
        {
            var messages = await _messageRepository.GetConversationAsync(
                currentUserId, 
                request.UserId, 
                request.Page, 
                request.PageSize);

            // Get deleted message IDs for current user
            var deletedMessageIds = await _messageDeletionRepository.GetDeletedMessageIdsForUserAsync(currentUserId);
            
            // Filter out messages that are deleted for the current user
            var filteredMessages = messages.Where(m => !deletedMessageIds.Contains(m.Id));

            return filteredMessages.Select(MapToMessageResponseDto);
        }

        public async Task<bool> MarkMessageAsReadAsync(int userId, int messageId)
        {
            var message = await _messageRepository.GetByIdAsync(messageId);
            if (message == null || message.ReceiverId != userId)
            {
                return false;
            }

            await _messageRepository.MarkAsReadAsync(messageId);
            return true;
        }

        public async Task<bool> MarkMessageAsDeliveredAsync(int messageId)
        {
            var message = await _messageRepository.GetByIdAsync(messageId);
            if (message == null)
            {
                return false;
            }

            await _messageRepository.MarkAsDeliveredAsync(messageId);
            return true;
        }

        public async Task<int> GetUnreadCountAsync(int userId)
        {
            return await _messageRepository.GetUnreadCountAsync(userId);
        }

        public async Task<MessageResponseDto?> GetMessageByIdAsync(int messageId)
        {
            var message = await _messageRepository.GetByIdAsync(messageId);
            return message != null ? MapToMessageResponseDto(message) : null;
        }

        private static MessageResponseDto MapToMessageResponseDto(Message message)
        {
            return new MessageResponseDto
            {
                Id = message.Id,
                SenderId = message.SenderId,
                ReceiverId = message.ReceiverId,
                MessageType = message.MessageType,
                Content = message.Content,
                SentAt = message.SentAt,
                DeliveredAt = message.DeliveredAt,
                ReadAt = message.ReadAt,
                Attachments = message.Attachments.Select(a => new AttachmentResponseDto
                {
                    Id = a.Id,
                    FilePath = a.FilePath,
                    FileType = a.FileType,
                    FileSize = a.FileSize
                }).ToList(),
                SenderUsername = message.Sender?.Username,
                ReceiverUsername = message.Receiver?.Username
            };
        }

        public async Task<bool> DeleteMessageForMeAsync(int userId, int messageId)
        {
            var message = await _messageRepository.GetByIdAsync(messageId);
            
            // Check if message exists
            if (message == null)
                return false;
            
            // Check if user has permission to delete (sender or receiver can delete for themselves)
            if (message.SenderId != userId && message.ReceiverId != userId)
                return false;
            
            // Create deletion record for this user
            var messageDeletion = new MessageDeletion
            {
                MessageId = messageId,
                UserId = userId,
                DeletedAt = DateTime.UtcNow
            };
            
            await _messageDeletionRepository.AddAsync(messageDeletion);
            return true;
        }

        public async Task<IEnumerable<ConversationResponseDto>> GetRecentConversationsAsync(int userId, int limit = 20)
        {
            // Get all messages where the user is either sender or receiver
            var userMessages = await _messageRepository.GetMessagesForUserAsync(userId);

            // Get deleted message IDs for current user
            var deletedMessageIds = await _messageDeletionRepository.GetDeletedMessageIdsForUserAsync(userId);
            
            // Filter out messages that are deleted for the current user
            var filteredMessages = userMessages.Where(m => !deletedMessageIds.Contains(m.Id));

            // Group messages by conversation partner
            var conversationGroups = filteredMessages
                .GroupBy(m => m.SenderId == userId ? m.ReceiverId : m.SenderId)
                .Where(g => g.Key != userId) // Exclude conversations with self
                .Select(g => new
                {
                    OtherUserId = g.Key,
                    Messages = g.OrderByDescending(m => m.SentAt).ToList()
                })
                .Where(g => g.Messages.Any()) // Only include conversations with remaining messages
                .Take(limit)
                .ToList();

            var conversations = new List<ConversationResponseDto>();

            foreach (var group in conversationGroups)
            {
                var otherUser = await _userRepository.GetByIdAsync(group.OtherUserId);
                if (otherUser == null) continue;

                var lastMessage = group.Messages.First();
                var unreadCount = group.Messages.Count(m => m.ReceiverId == userId && m.ReadAt == null);

                conversations.Add(new ConversationResponseDto
                {
                    Id = group.OtherUserId, // Using other user's ID as conversation ID
                    OtherUser = new UserResponseDto
                    {
                        Id = otherUser.Id,
                        Username = otherUser.Username,
                        PhoneNumber = otherUser.PhoneNumber,
                        DisplayName = otherUser.DisplayName,
                        CreatedAt = otherUser.CreatedAt,
                        LastSeen = otherUser.LastSeen,
                        IsOnline = otherUser.LastSeen.HasValue && 
                                  DateTime.UtcNow.Subtract(otherUser.LastSeen.Value).TotalMinutes <= 5
                    },
                    LastMessage = new MessageResponseDto
                    {
                        Id = lastMessage.Id,
                        SenderId = lastMessage.SenderId,
                        ReceiverId = lastMessage.ReceiverId,
                        MessageType = lastMessage.MessageType,
                        Content = lastMessage.Content,
                        SentAt = lastMessage.SentAt,
                        DeliveredAt = lastMessage.DeliveredAt,
                        ReadAt = lastMessage.ReadAt,
                        SenderUsername = lastMessage.Sender?.Username,
                        ReceiverUsername = lastMessage.Receiver?.Username
                    },
                    UnreadCount = unreadCount,
                    LastActivity = lastMessage.SentAt
                });
            }

            return conversations.OrderByDescending(c => c.LastActivity);
        }
    }
}