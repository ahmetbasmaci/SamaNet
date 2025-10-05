using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SamaNetMessaegingAppApi.Models
{
    /// <summary>
    /// Entity representing a blocked user relationship
    /// </summary>
    public class UserBlock
    {
        [Key]
        public int Id { get; set; }

        /// <summary>
        /// ID of the user who is blocking
        /// </summary>
        [Required]
        public int BlockerId { get; set; }

        /// <summary>
        /// ID of the user who is being blocked
        /// </summary>
        [Required]
        public int BlockedUserId { get; set; }

        /// <summary>
        /// Timestamp when the block was created
        /// </summary>
        public DateTime BlockedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("BlockerId")]
        public virtual User? Blocker { get; set; }

        [ForeignKey("BlockedUserId")]
        public virtual User? BlockedUser { get; set; }
    }
}
