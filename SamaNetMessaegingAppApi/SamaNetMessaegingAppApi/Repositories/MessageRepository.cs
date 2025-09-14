using Microsoft.EntityFrameworkCore;
using SamaNetMessaegingAppApi.Data;
using SamaNetMessaegingAppApi.Models;
using SamaNetMessaegingAppApi.Repositories.Interfaces;

namespace SamaNetMessaegingAppApi.Repositories
{
    /// <summary>
    /// Repository implementation for Message entity operations
    /// </summary>
    public class MessageRepository : IMessageRepository
    {
        private readonly ChatDbContext _context;

        public MessageRepository(ChatDbContext context)
        {
            _context = context;
        }

        public async Task<Message?> GetByIdAsync(int id)
        {
            return await _context.Messages
                .Include(m => m.Sender)
                .Include(m => m.Receiver)
                .Include(m => m.Attachments)
                .FirstOrDefaultAsync(m => m.Id == id);
        }

        public async Task<IEnumerable<Message>> GetConversationAsync(int user1Id, int user2Id, int page = 1, int pageSize = 50)
        {
            var skip = (page - 1) * pageSize;

            return await _context.Messages
                .Include(m => m.Sender)
                .Include(m => m.Receiver)
                .Include(m => m.Attachments)
                .Where(m => (m.SenderId == user1Id && m.ReceiverId == user2Id) ||
                           (m.SenderId == user2Id && m.ReceiverId == user1Id))
                .OrderBy(m => m.SentAt)
                .Skip(skip)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<IEnumerable<Message>> GetMessagesForUserAsync(int userId)
        {
            return await _context.Messages
                .Include(m => m.Sender)
                .Include(m => m.Receiver)
                .Include(m => m.Attachments)
                .Where(m => m.SenderId == userId || m.ReceiverId == userId)
                .OrderByDescending(m => m.SentAt)
                .ToListAsync();
        }

        public async Task<Message> CreateAsync(Message message)
        {
            _context.Messages.Add(message);
            await _context.SaveChangesAsync();

            // Load navigation properties
            await _context.Entry(message)
                .Reference(m => m.Sender)
                .LoadAsync();
            await _context.Entry(message)
                .Reference(m => m.Receiver)
                .LoadAsync();
            await _context.Entry(message)
                .Collection(m => m.Attachments)
                .LoadAsync();

            return message;
        }

        public async Task<Message> UpdateAsync(Message message)
        {
            _context.Messages.Update(message);
            await _context.SaveChangesAsync();
            return message;
        }

        public async Task DeleteAsync(int id)
        {
            var message = await _context.Messages.FindAsync(id);
            if (message != null)
            {
                _context.Messages.Remove(message);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<IEnumerable<Message>> GetUndeliveredMessagesAsync(int userId)
        {
            return await _context.Messages
                .Include(m => m.Sender)
                .Include(m => m.Attachments)
                .Where(m => m.ReceiverId == userId && m.DeliveredAt == null)
                .ToListAsync();
        }

        public async Task<IEnumerable<Message>> GetUnreadMessagesAsync(int userId)
        {
            return await _context.Messages
                .Include(m => m.Sender)
                .Include(m => m.Attachments)
                .Where(m => m.ReceiverId == userId && m.ReadAt == null)
                .ToListAsync();
        }

        public async Task MarkAsDeliveredAsync(int messageId)
        {
            var message = await _context.Messages.FindAsync(messageId);
            if (message != null && message.DeliveredAt == null)
            {
                message.DeliveredAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }
        }

        public async Task MarkAsReadAsync(int messageId)
        {
            var message = await _context.Messages.FindAsync(messageId);
            if (message != null && message.ReadAt == null)
            {
                message.ReadAt = DateTime.UtcNow;
                if (message.DeliveredAt == null)
                {
                    message.DeliveredAt = DateTime.UtcNow;
                }
                await _context.SaveChangesAsync();
            }
        }

        public async Task<int> GetUnreadCountAsync(int userId)
        {
            return await _context.Messages
                .CountAsync(m => m.ReceiverId == userId && m.ReadAt == null);
        }
    }
}