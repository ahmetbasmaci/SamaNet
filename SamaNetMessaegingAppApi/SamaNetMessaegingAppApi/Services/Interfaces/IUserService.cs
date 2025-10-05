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

        Task<IEnumerable<UserResponseDto>> GetAllUsersAsync();
    }
}