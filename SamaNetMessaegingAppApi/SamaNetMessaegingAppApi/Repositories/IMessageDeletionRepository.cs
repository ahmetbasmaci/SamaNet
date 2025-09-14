using SamaNetMessaegingAppApi.Models;

namespace SamaNetMessaegingAppApi.Repositories
{
    /// <summary>
    /// Repository interface for MessageDeletion operations
    /// </summary>
    public interface IMessageDeletionRepository
    {
        /// <summary>
        /// Add a message deletion record (mark message as deleted for specific user)
        /// </summary>
        Task<MessageDeletion> AddAsync(MessageDeletion messageDeletion);

        /// <summary>
        /// Check if a message is deleted for a specific user
        /// </summary>
        Task<bool> IsMessageDeletedForUserAsync(int messageId, int userId);

        /// <summary>
        /// Get all deleted message IDs for a specific user
        /// </summary>
        Task<List<int>> GetDeletedMessageIdsForUserAsync(int userId);

        /// <summary>
        /// Remove deletion record (restore message for user)
        /// </summary>
        Task<bool> RemoveAsync(int messageId, int userId);
    }
}
