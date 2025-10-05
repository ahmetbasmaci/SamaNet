using SamaNetMessaegingAppApi.Models;

namespace SamaNetMessaegingAppApi.Repositories.Interfaces
{
    /// <summary>
    /// Repository interface for UserBlock operations
    /// </summary>
    public interface IUserBlockRepository
    {
        /// <summary>
        /// Block a user
        /// </summary>
        Task<UserBlock> BlockUserAsync(int blockerId, int blockedUserId);

        /// <summary>
        /// Unblock a user
        /// </summary>
        Task<bool> UnblockUserAsync(int blockerId, int blockedUserId);

        /// <summary>
        /// Check if a user is blocked
        /// </summary>
        Task<bool> IsUserBlockedAsync(int blockerId, int blockedUserId);

        /// <summary>
        /// Get list of blocked users by a user
        /// </summary>
        Task<IEnumerable<UserBlock>> GetBlockedUsersAsync(int blockerId);

        /// <summary>
        /// Get list of users who blocked a specific user
        /// </summary>
        Task<IEnumerable<UserBlock>> GetBlockersAsync(int blockedUserId);

        /// <summary>
        /// Check if there is a mutual block between two users
        /// </summary>
        Task<bool> IsBlockRelationshipAsync(int userId1, int userId2);
    }
}
