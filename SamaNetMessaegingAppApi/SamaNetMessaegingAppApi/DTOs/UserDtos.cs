using System.ComponentModel.DataAnnotations;

namespace SamaNetMessaegingAppApi.DTOs
{
    /// <summary>
    /// DTO for user login request
    /// </summary>
    public class LoginRequestDto
    {
        [Required]
        [StringLength(50)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string Password { get; set; } = string.Empty;
    }

    /// <summary>
    /// DTO for user registration request
    /// </summary>
    public class RegisterRequestDto
    {
        [Required]
        [StringLength(50)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string Password { get; set; } = string.Empty;

        [Required]
        [StringLength(20)]
        [Phone]
        public string PhoneNumber { get; set; } = string.Empty;

        [StringLength(100)]
        public string? DisplayName { get; set; }
    }

    /// <summary>
    /// DTO for user search request
    /// </summary>
    public class UserSearchRequestDto
    {
        [Required]
        [StringLength(20)]
        [Phone]
        public string PhoneNumber { get; set; } = string.Empty;
    }

    /// <summary>
    /// DTO for user response
    /// </summary>
    public class UserResponseDto
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string? DisplayName { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? LastSeen { get; set; }
        public bool IsOnline { get; set; }
    }

    /// <summary>
    /// DTO for login response
    /// </summary>
    public class LoginResponseDto
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public UserResponseDto? User { get; set; }
        public string? Token { get; set; }
    }
}