using SamaNetMessaegingAppApi.DTOs;
using SamaNetMessaegingAppApi.Models;
using SamaNetMessaegingAppApi.Repositories.Interfaces;
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

        public MessageService(
            IMessageRepository messageRepository,
            IAttachmentRepository attachmentRepository,
            IUserRepository userRepository,
            IFileService fileService)
        {
            _messageRepository = messageRepository;
            _attachmentRepository = attachmentRepository;
            _userRepository = userRepository;
            _fileService = fileService;
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

            return messages.Select(MapToMessageResponseDto);
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
    }
}