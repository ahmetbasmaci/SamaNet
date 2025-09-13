using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SamaNetMessaegingAppApi.Models
{
    /// <summary>
    /// Message entity representing chat messages between users
    /// </summary>
    public class Message
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int SenderId { get; set; }

        [Required]
        public int ReceiverId { get; set; }

        [Required]
        [StringLength(20)]
        public string MessageType { get; set; } = "text"; // text, image, audio, video, file

        public string? Content { get; set; }

        public DateTime SentAt { get; set; } = DateTime.UtcNow;

        public DateTime? DeliveredAt { get; set; }

        public DateTime? ReadAt { get; set; }

        // Navigation properties
        [ForeignKey("SenderId")]
        public virtual User Sender { get; set; } = null!;

        [ForeignKey("ReceiverId")]
        public virtual User Receiver { get; set; } = null!;

        public virtual ICollection<Attachment> Attachments { get; set; } = new List<Attachment>();
    }
}