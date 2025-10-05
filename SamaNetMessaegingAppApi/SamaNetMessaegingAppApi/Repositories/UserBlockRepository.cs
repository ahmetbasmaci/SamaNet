using Microsoft.EntityFrameworkCore;
using SamaNetMessaegingAppApi.Data;
using SamaNetMessaegingAppApi.Models;
using SamaNetMessaegingAppApi.Repositories.Interfaces;

namespace SamaNetMessaegingAppApi.Repositories
{
    /// <summary>
    /// Repository implementation for UserBlock operations
    /// </summary>
    public class UserBlockRepository : IUserBlockRepository
    {
        private readonly ChatDbContext _context;

        public UserBlockRepository(ChatDbContext context)
        {
            _context = context;
        }

        public async Task<UserBlock> BlockUserAsync(int blockerId, int blockedUserId)
        {
            // Check if already blocked
            var existingBlock = await _context.UserBlocks
                .FirstOrDefaultAsync(ub => ub.BlockerId == blockerId && ub.BlockedUserId == blockedUserId);

            if (existingBlock != null)
            {
                return existingBlock;
            }

            var userBlock = new UserBlock
            {
                BlockerId = blockerId,
                BlockedUserId = blockedUserId,
                BlockedAt = DateTime.UtcNow
            };

            _context.UserBlocks.Add(userBlock);
            await _context.SaveChangesAsync();

            return userBlock;
        }

        public async Task<bool> UnblockUserAsync(int blockerId, int blockedUserId)
        {
            var userBlock = await _context.UserBlocks
                .FirstOrDefaultAsync(ub => ub.BlockerId == blockerId && ub.BlockedUserId == blockedUserId);

            if (userBlock == null)
            {
                return false;
            }

            _context.UserBlocks.Remove(userBlock);
            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<bool> IsUserBlockedAsync(int blockerId, int blockedUserId)
        {
            return await _context.UserBlocks
                .AnyAsync(ub => ub.BlockerId == blockerId && ub.BlockedUserId == blockedUserId);
        }

        public async Task<IEnumerable<UserBlock>> GetBlockedUsersAsync(int blockerId)
        {
            return await _context.UserBlocks
                .Include(ub => ub.BlockedUser)
                .Where(ub => ub.BlockerId == blockerId)
                .OrderByDescending(ub => ub.BlockedAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<UserBlock>> GetBlockersAsync(int blockedUserId)
        {
            return await _context.UserBlocks
                .Include(ub => ub.Blocker)
                .Where(ub => ub.BlockedUserId == blockedUserId)
                .OrderByDescending(ub => ub.BlockedAt)
                .ToListAsync();
        }

        public async Task<bool> IsBlockRelationshipAsync(int userId1, int userId2)
        {
            return await _context.UserBlocks
                .AnyAsync(ub => 
                    (ub.BlockerId == userId1 && ub.BlockedUserId == userId2) ||
                    (ub.BlockerId == userId2 && ub.BlockedUserId == userId1));
        }
    }
}
