using SamaNetMessaegingAppApi.Models;

namespace SamaNetMessaegingAppApi.Repositories.Interfaces
{
    /// <summary>
    /// Repository interface for Message entity operations
    /// </summary>
    public interface IMessageRepository
    {
        Task<Message?> GetByIdAsync(int id);
        Task<IEnumerable<Message>> GetConversationAsync(int user1Id, int user2Id, int page = 1, int pageSize = 50);
        Task<Message> CreateAsync(Message message);
        Task<Message> UpdateAsync(Message message);
        Task DeleteAsync(int id);
        Task<IEnumerable<Message>> GetUndeliveredMessagesAsync(int userId);
        Task<IEnumerable<Message>> GetUnreadMessagesAsync(int userId);
        Task MarkAsDeliveredAsync(int messageId);
        Task MarkAsReadAsync(int messageId);
        Task<int> GetUnreadCountAsync(int userId);
    }
}