using Microsoft.EntityFrameworkCore;
using SamaNetMessaegingAppApi.Data;
using SamaNetMessaegingAppApi.Models;
using SamaNetMessaegingAppApi.Repositories.Interfaces;

namespace SamaNetMessaegingAppApi.Repositories
{
    /// <summary>
    /// Repository implementation for Attachment entity operations
    /// </summary>
    public class AttachmentRepository : IAttachmentRepository
    {
        private readonly ChatDbContext _context;

        public AttachmentRepository(ChatDbContext context)
        {
            _context = context;
        }

        public async Task<Attachment?> GetByIdAsync(int id)
        {
            return await _context.Attachments
                .Include(a => a.Message)
                .FirstOrDefaultAsync(a => a.Id == id);
        }

        public async Task<IEnumerable<Attachment>> GetByMessageIdAsync(int messageId)
        {
            return await _context.Attachments
                .Where(a => a.MessageId == messageId)
                .ToListAsync();
        }

        public async Task<Attachment> CreateAsync(Attachment attachment)
        {
            _context.Attachments.Add(attachment);
            await _context.SaveChangesAsync();
            return attachment;
        }

        public async Task DeleteAsync(int id)
        {
            var attachment = await _context.Attachments.FindAsync(id);
            if (attachment != null)
            {
                _context.Attachments.Remove(attachment);
                await _context.SaveChangesAsync();
            }
        }

        public async Task DeleteByMessageIdAsync(int messageId)
        {
            var attachments = await _context.Attachments
                .Where(a => a.MessageId == messageId)
                .ToListAsync();

            if (attachments.Any())
            {
                _context.Attachments.RemoveRange(attachments);
                await _context.SaveChangesAsync();
            }
        }
    }
}