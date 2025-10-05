using System.ComponentModel.DataAnnotations;

namespace SamaNetMessaegingAppApi.DTOs
{
    /// <summary>
    /// DTO for blocking/unblocking a user
    /// </summary>
    public class BlockUserRequestDto
    {
        [Required]
        public int BlockedUserId { get; set; }
    }

    /// <summary>
    /// DTO for blocked user response
    /// </summary>
    public class BlockedUserResponseDto
    {
        public int Id { get; set; }
        public int BlockerId { get; set; }
        public int BlockedUserId { get; set; }
        public UserResponseDto? BlockedUser { get; set; }
        public DateTime BlockedAt { get; set; }
    }

    /// <summary>
    /// DTO for block status response
    /// </summary>
    public class BlockStatusResponseDto
    {
        public bool IsBlocked { get; set; }
        public string Message { get; set; } = string.Empty;
    }
}
