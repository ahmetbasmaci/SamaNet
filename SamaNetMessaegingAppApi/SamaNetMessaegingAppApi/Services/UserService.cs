using BCrypt.Net;
using SamaNetMessaegingAppApi.DTOs;
using SamaNetMessaegingAppApi.Models;
using SamaNetMessaegingAppApi.Repositories.Interfaces;
using SamaNetMessaegingAppApi.Services.Interfaces;

namespace SamaNetMessaegingAppApi.Services
{
    /// <summary>
    /// Service implementation for user-related operations
    /// </summary>
    public class UserService : IUserService
    {
        private readonly IUserRepository _userRepository;

        public UserService(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<LoginResponseDto> LoginAsync(LoginRequestDto loginRequest)
        {
            try
            {
                var user = await _userRepository.GetByUsernameAsync(loginRequest.Username);

                if (user == null || !BCrypt.Net.BCrypt.Verify(loginRequest.Password, user.PasswordHash))
                {
                    return new LoginResponseDto
                    {
                        Success = false,
                        Message = "Invalid username or password"
                    };
                }

                // Update last seen
                await UpdateLastSeenAsync(user.Id);

                return new LoginResponseDto
                {
                    Success = true,
                    Message = "Login successful",
                    User = MapToUserResponseDto(user),
                    Token = GenerateSimpleToken(user.Id) // Simple token for demo
                };
            }
            catch (Exception ex)
            {
                return new LoginResponseDto
                {
                    Success = false,
                    Message = $"Login failed: {ex.Message}"
                };
            }
        }

        public async Task<LoginResponseDto> RegisterAsync(RegisterRequestDto registerRequest)
        {
            try
            {
                // Check if username already exists
                if (await _userRepository.UsernameExistsAsync(registerRequest.Username))
                {
                    return new LoginResponseDto
                    {
                        Success = false,
                        Message = "Username already exists"
                    };
                }

                // Check if phone number already exists
                if (await _userRepository.PhoneNumberExistsAsync(registerRequest.PhoneNumber))
                {
                    return new LoginResponseDto
                    {
                        Success = false,
                        Message = "Phone number already exists"
                    };
                }

                var user = new User
                {
                    Username = registerRequest.Username,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(registerRequest.Password),
                    PhoneNumber = registerRequest.PhoneNumber,
                    DisplayName = registerRequest.DisplayName,
                    CreatedAt = DateTime.UtcNow
                };

                var createdUser = await _userRepository.CreateAsync(user);

                return new LoginResponseDto
                {
                    Success = true,
                    Message = "Registration successful",
                    User = MapToUserResponseDto(createdUser),
                    Token = GenerateSimpleToken(createdUser.Id)
                };
            }
            catch (Exception ex)
            {
                return new LoginResponseDto
                {
                    Success = false,
                    Message = $"Registration failed: {ex.Message}"
                };
            }
        }

        public async Task<IEnumerable<UserResponseDto>> SearchUsersByPhoneAsync(string phoneNumber)
        {
            var users = await _userRepository.SearchByPhoneNumberAsync(phoneNumber);
            return users.Select(MapToUserResponseDto);
        }

        public async Task<IEnumerable<UserResponseDto>> SearchUsersByUsernameAsync(string username)
        {
            var users = await _userRepository.SearchByUsernameAsync(username);
            return users.Select(MapToUserResponseDto);
        }

        public async Task<UserResponseDto?> GetUserByIdAsync(int id)
        {
            var user = await _userRepository.GetByIdAsync(id);
            return user != null ? MapToUserResponseDto(user) : null;
        }

        public async Task UpdateLastSeenAsync(int userId)
        {
            var user = await _userRepository.GetByIdAsync(userId);
            if (user != null)
            {
                user.LastSeen = DateTime.UtcNow;
                await _userRepository.UpdateAsync(user);
            }
        }

        public async Task<UserResponseDto?> UpdateAvatarAsync(int userId, string avatarPath)
        {
            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null)
            {
                return null;
            }

            user.AvatarPath = avatarPath;
            await _userRepository.UpdateAsync(user);

            return MapToUserResponseDto(user);
        }

        public async Task<IEnumerable<UserResponseDto>> GetAllUsersAsync()
        {
            var users = await _userRepository.GetAllAsync();
            return users.Select(MapToUserResponseDto);
        }
        private static UserResponseDto MapToUserResponseDto(User user)
        {
            return new UserResponseDto
            {
                Id = user.Id,
                Username = user.Username,
                PhoneNumber = user.PhoneNumber,
                DisplayName = user.DisplayName,
                AvatarPath = user.AvatarPath,
                CreatedAt = user.CreatedAt,
                LastSeen = user.LastSeen
            };
        }

        private static string GenerateSimpleToken(int userId)
        {
            // Simple token generation for demo purposes
            // In production, use proper JWT tokens
            return Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes($"user_{userId}_{DateTime.UtcNow:yyyyMMddHHmmss}"));
        }

    }
}