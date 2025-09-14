using Microsoft.EntityFrameworkCore;
using SamaNetMessaegingAppApi.Data;
using SamaNetMessaegingAppApi.Models;

namespace SamaNetMessaegingAppApi.Repositories
{
    /// <summary>
    /// Repository implementation for MessageDeletion operations
    /// </summary>
    public class MessageDeletionRepository : IMessageDeletionRepository
    {
        private readonly ChatDbContext _context;

        public MessageDeletionRepository(ChatDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Add a message deletion record (mark message as deleted for specific user)
        /// </summary>
        public async Task<MessageDeletion> AddAsync(MessageDeletion messageDeletion)
        {
            // Check if deletion record already exists
            var existing = await _context.MessageDeletions
                .FirstOrDefaultAsync(md => md.MessageId == messageDeletion.MessageId && 
                                          md.UserId == messageDeletion.UserId);

            if (existing != null)
            {
                // Update existing record
                existing.DeletedAt = DateTime.UtcNow;
                _context.MessageDeletions.Update(existing);
                await _context.SaveChangesAsync();
                return existing;
            }

            // Add new deletion record
            _context.MessageDeletions.Add(messageDeletion);
            await _context.SaveChangesAsync();
            return messageDeletion;
        }

        /// <summary>
        /// Check if a message is deleted for a specific user
        /// </summary>
        public async Task<bool> IsMessageDeletedForUserAsync(int messageId, int userId)
        {
            return await _context.MessageDeletions
                .AnyAsync(md => md.MessageId == messageId && md.UserId == userId);
        }

        /// <summary>
        /// Get all deleted message IDs for a specific user
        /// </summary>
        public async Task<List<int>> GetDeletedMessageIdsForUserAsync(int userId)
        {
            return await _context.MessageDeletions
                .Where(md => md.UserId == userId)
                .Select(md => md.MessageId)
                .ToListAsync();
        }

        /// <summary>
        /// Remove deletion record (restore message for user)
        /// </summary>
        public async Task<bool> RemoveAsync(int messageId, int userId)
        {
            var deletion = await _context.MessageDeletions
                .FirstOrDefaultAsync(md => md.MessageId == messageId && md.UserId == userId);

            if (deletion == null)
                return false;

            _context.MessageDeletions.Remove(deletion);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
