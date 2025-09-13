using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SamaNetMessaegingAppApi.Models
{
    /// <summary>
    /// Attachment entity for file attachments in messages
    /// </summary>
    public class Attachment
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int MessageId { get; set; }

        [Required]
        public string FilePath { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string FileType { get; set; } = string.Empty;

        [Required]
        public long FileSize { get; set; }

        // Navigation property
        [ForeignKey("MessageId")]
        public virtual Message Message { get; set; } = null!;
    }
}