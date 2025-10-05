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
        private readonly IUserBlockRepository _userBlockRepository;

        public UserService(IUserRepository userRepository, IUserBlockRepository userBlockRepository)
        {
            _userRepository = userRepository;
            _userBlockRepository = userBlockRepository;
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

        public async Task<BlockStatusResponseDto> BlockUserAsync(int blockerId, int blockedUserId)
        {
            try
            {
                // Validate users exist
                var blocker = await _userRepository.GetByIdAsync(blockerId);
                var blockedUser = await _userRepository.GetByIdAsync(blockedUserId);

                if (blocker == null || blockedUser == null)
                {
                    return new BlockStatusResponseDto
                    {
                        IsBlocked = false,
                        Message = "User not found"
                    };
                }

                // Can't block yourself
                if (blockerId == blockedUserId)
                {
                    return new BlockStatusResponseDto
                    {
                        IsBlocked = false,
                        Message = "Cannot block yourself"
                    };
                }

                // Check if already blocked
                var isAlreadyBlocked = await _userBlockRepository.IsUserBlockedAsync(blockerId, blockedUserId);
                if (isAlreadyBlocked)
                {
                    return new BlockStatusResponseDto
                    {
                        IsBlocked = true,
                        Message = "User is already blocked"
                    };
                }

                await _userBlockRepository.BlockUserAsync(blockerId, blockedUserId);

                return new BlockStatusResponseDto
                {
                    IsBlocked = true,
                    Message = "User blocked successfully"
                };
            }
            catch (Exception ex)
            {
                return new BlockStatusResponseDto
                {
                    IsBlocked = false,
                    Message = $"Failed to block user: {ex.Message}"
                };
            }
        }

        public async Task<BlockStatusResponseDto> UnblockUserAsync(int blockerId, int blockedUserId)
        {
            try
            {
                var success = await _userBlockRepository.UnblockUserAsync(blockerId, blockedUserId);

                return new BlockStatusResponseDto
                {
                    IsBlocked = false,
                    Message = success ? "User unblocked successfully" : "User was not blocked"
                };
            }
            catch (Exception ex)
            {
                return new BlockStatusResponseDto
                {
                    IsBlocked = true,
                    Message = $"Failed to unblock user: {ex.Message}"
                };
            }
        }

        public async Task<bool> IsUserBlockedAsync(int blockerId, int blockedUserId)
        {
            return await _userBlockRepository.IsUserBlockedAsync(blockerId, blockedUserId);
        }

        public async Task<IEnumerable<BlockedUserResponseDto>> GetBlockedUsersAsync(int blockerId)
        {
            var blockedUsers = await _userBlockRepository.GetBlockedUsersAsync(blockerId);
            
            return blockedUsers.Select(ub => new BlockedUserResponseDto
            {
                Id = ub.Id,
                BlockerId = ub.BlockerId,
                BlockedUserId = ub.BlockedUserId,
                BlockedUser = ub.BlockedUser != null ? MapToUserResponseDto(ub.BlockedUser) : null,
                BlockedAt = ub.BlockedAt
            });
        }
 public async Task<IEnumerable<UserResponseDto>> GetAllUsersAsync()
        {
            var users = await _userRepository.GetAllAsync();
            return users.Select(MapToUserResponseDto);
        }
        public async Task<BlockStatusResponseDto> BlockUserAsync(int blockerId, int blockedUserId)
        {
            try
            {
                // Validate users exist
                var blocker = await _userRepository.GetByIdAsync(blockerId);
                var blockedUser = await _userRepository.GetByIdAsync(blockedUserId);

                if (blocker == null || blockedUser == null)
                {
                    return new BlockStatusResponseDto
                    {
                        IsBlocked = false,
                        Message = "User not found"
                    };
                }

                // Can't block yourself
                if (blockerId == blockedUserId)
                {
                    return new BlockStatusResponseDto
                    {
                        IsBlocked = false,
                        Message = "Cannot block yourself"
                    };
                }

                // Check if already blocked
                var isAlreadyBlocked = await _userBlockRepository.IsUserBlockedAsync(blockerId, blockedUserId);
                if (isAlreadyBlocked)
                {
                    return new BlockStatusResponseDto
                    {
                        IsBlocked = true,
                        Message = "User is already blocked"
                    };
                }

                await _userBlockRepository.BlockUserAsync(blockerId, blockedUserId);

                return new BlockStatusResponseDto
                {
                    IsBlocked = true,
                    Message = "User blocked successfully"
                };
            }
            catch (Exception ex)
            {
                return new BlockStatusResponseDto
                {
                    IsBlocked = false,
                    Message = $"Failed to block user: {ex.Message}"
                };
            }
        }

        public async Task<BlockStatusResponseDto> UnblockUserAsync(int blockerId, int blockedUserId)
        {
            try
            {
                var success = await _userBlockRepository.UnblockUserAsync(blockerId, blockedUserId);

                return new BlockStatusResponseDto
                {
                    IsBlocked = false,
                    Message = success ? "User unblocked successfully" : "User was not blocked"
                };
            }
            catch (Exception ex)
            {
                return new BlockStatusResponseDto
                {
                    IsBlocked = true,
                    Message = $"Failed to unblock user: {ex.Message}"
                };
            }
        }

        public async Task<bool> IsUserBlockedAsync(int blockerId, int blockedUserId)
        {
            return await _userBlockRepository.IsUserBlockedAsync(blockerId, blockedUserId);
        }

        public async Task<IEnumerable<BlockedUserResponseDto>> GetBlockedUsersAsync(int blockerId)
        {
            var blockedUsers = await _userBlockRepository.GetBlockedUsersAsync(blockerId);
            
            return blockedUsers.Select(ub => new BlockedUserResponseDto
            {
                Id = ub.Id,
                BlockerId = ub.BlockerId,
                BlockedUserId = ub.BlockedUserId,
                BlockedUser = ub.BlockedUser != null ? MapToUserResponseDto(ub.BlockedUser) : null,
                BlockedAt = ub.BlockedAt
            });
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