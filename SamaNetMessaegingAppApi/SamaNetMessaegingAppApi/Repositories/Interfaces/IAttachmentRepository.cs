using SamaNetMessaegingAppApi.Models;

namespace SamaNetMessaegingAppApi.Repositories.Interfaces
{
    /// <summary>
    /// Repository interface for Attachment entity operations
    /// </summary>
    public interface IAttachmentRepository
    {
        Task<Attachment?> GetByIdAsync(int id);
        Task<IEnumerable<Attachment>> GetByMessageIdAsync(int messageId);
        Task<Attachment> CreateAsync(Attachment attachment);
        Task DeleteAsync(int id);
        Task DeleteByMessageIdAsync(int messageId);
    }
}