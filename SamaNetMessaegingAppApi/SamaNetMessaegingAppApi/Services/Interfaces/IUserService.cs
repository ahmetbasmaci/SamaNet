using SamaNetMessaegingAppApi.DTOs;
using SamaNetMessaegingAppApi.Models;

namespace SamaNetMessaegingAppApi.Services.Interfaces
{
    /// <summary>
    /// Service interface for user-related operations
    /// </summary>
    public interface IUserService
    {
        Task<LoginResponseDto> LoginAsync(LoginRequestDto loginRequest);
        Task<LoginResponseDto> RegisterAsync(RegisterRequestDto registerRequest);
        Task<IEnumerable<UserResponseDto>> SearchUsersByPhoneAsync(string phoneNumber);
        Task<IEnumerable<UserResponseDto>> SearchUsersByUsernameAsync(string username);
        Task<UserResponseDto?> GetUserByIdAsync(int id);
        Task UpdateLastSeenAsync(int userId);
        Task<UserResponseDto?> UpdateAvatarAsync(int userId, string avatarPath);
        
        // Block/Unblock operations
        Task<BlockStatusResponseDto> BlockUserAsync(int blockerId, int blockedUserId);
        Task<BlockStatusResponseDto> UnblockUserAsync(int blockerId, int blockedUserId);
        Task<bool> IsUserBlockedAsync(int blockerId, int blockedUserId);
        Task<IEnumerable<BlockedUserResponseDto>> GetBlockedUsersAsync(int blockerId);

        Task<IEnumerable<UserResponseDto>> GetAllUsersAsync();
    }
}