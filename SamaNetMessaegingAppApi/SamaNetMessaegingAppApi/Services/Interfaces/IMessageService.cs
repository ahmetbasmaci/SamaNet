using SamaNetMessaegingAppApi.DTOs;
using SamaNetMessaegingAppApi.Models;

namespace SamaNetMessaegingAppApi.Services.Interfaces
{
    /// <summary>
    /// Service interface for message-related operations
    /// </summary>
    public interface IMessageService
    {
        Task<MessageResponseDto> SendMessageAsync(int senderId, SendMessageRequestDto request);
        Task<MessageResponseDto> SendMessageWithAttachmentAsync(int senderId, SendMessageRequestDto request, IFormFile file);
        Task<IEnumerable<MessageResponseDto>> GetConversationAsync(int currentUserId, ConversationRequestDto request);
        Task<bool> MarkMessageAsReadAsync(int userId, int messageId);
        Task<bool> MarkMessageAsDeliveredAsync(int messageId);
        Task<int> GetUnreadCountAsync(int userId);
        Task<MessageResponseDto?> GetMessageByIdAsync(int messageId);
        Task<IEnumerable<ConversationResponseDto>> GetRecentConversationsAsync(int userId, int limit = 20);
    }
}