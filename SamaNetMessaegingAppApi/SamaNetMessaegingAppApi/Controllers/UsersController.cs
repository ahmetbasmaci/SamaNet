using Microsoft.AspNetCore.Mvc;
using SamaNetMessaegingAppApi.DTOs;
using SamaNetMessaegingAppApi.Services.Interfaces;

namespace SamaNetMessaegingAppApi.Controllers
{
    /// <summary>
    /// Controller for user authentication and management
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly IUserService _userService;

        public UsersController(IUserService userService)
        {
            _userService = userService;
        }

        /// <summary>
        /// User login with username and password
        /// </summary>
        [HttpPost("login")]
        public async Task<ActionResult<LoginResponseDto>> Login([FromBody] LoginRequestDto loginRequest)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _userService.LoginAsync(loginRequest);

            if (result.Success)
            {
                return Ok(result);
            }

            return Unauthorized(result);
        }

        /// <summary>
        /// User registration
        /// </summary>
        [HttpPost("register")]
        public async Task<ActionResult<LoginResponseDto>> Register([FromBody] RegisterRequestDto registerRequest)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _userService.RegisterAsync(registerRequest);

            if (result.Success)
            {
                return Ok(result);
            }

            return BadRequest(result);
        }

        /// <summary>
        /// Search users by phone number or username
        /// </summary>
        [HttpGet("search")]
        public async Task<ActionResult<IEnumerable<UserResponseDto>>> SearchUsers(
            [FromQuery] string? phoneNumber,
            [FromQuery] string? username)
        {
            if (string.IsNullOrWhiteSpace(phoneNumber) && string.IsNullOrWhiteSpace(username))
            {
                return BadRequest("Either phone number or username is required");
            }

            IEnumerable<UserResponseDto> users;

            if (!string.IsNullOrWhiteSpace(username))
            {
                users = await _userService.SearchUsersByUsernameAsync(username);
            }
            else
            {
                users = await _userService.SearchUsersByPhoneAsync(phoneNumber!);
            }

            return Ok(users);
        }

        /// <summary>
        /// Get user by ID
        /// </summary>
        [HttpGet("{id}")]
        public async Task<ActionResult<UserResponseDto>> GetUser(int id)
        {
            var user = await _userService.GetUserByIdAsync(id);

            if (user == null)
            {
                return NotFound("User not found");
            }

            return Ok(user);
        }

        /// <summary>
        /// Update user's last seen timestamp
        /// </summary>
        [HttpPut("{id}/last-seen")]
        public async Task<ActionResult> UpdateLastSeen(int id)
        {
            await _userService.UpdateLastSeenAsync(id);
            return Ok();
        }

        /// <summary>
        /// Update user's avatar image path
        /// </summary>
        [HttpPut("{id}/avatar")]
        public async Task<ActionResult<UserResponseDto>> UpdateAvatar(int id, [FromBody] UpdateAvatarRequestDto request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var updatedUser = await _userService.UpdateAvatarAsync(id, request.AvatarPath);

            if (updatedUser == null)
            {
                return NotFound("User not found");
            }

            return Ok(updatedUser);
        }

        // get all users - for testing purposes
        [HttpGet]
        public async Task<ActionResult<IEnumerable<UserResponseDto>>> GetAllUsers()
        {
            var users = await _userService.GetAllUsersAsync();
            return Ok(users);
        }

        /// <summary>
        /// Block a user
        /// </summary>
        [HttpPost("{blockerId}/block")]
        public async Task<ActionResult<BlockStatusResponseDto>> BlockUser(int blockerId, [FromBody] BlockUserRequestDto request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _userService.BlockUserAsync(blockerId, request.BlockedUserId);

            if (result.IsBlocked)
            {
                return Ok(result);
            }

            return BadRequest(result);
        }

        /// <summary>
        /// Unblock a user
        /// </summary>
        [HttpDelete("{blockerId}/unblock/{blockedUserId}")]
        public async Task<ActionResult<BlockStatusResponseDto>> UnblockUser(int blockerId, int blockedUserId)
        {
            var result = await _userService.UnblockUserAsync(blockerId, blockedUserId);
            return Ok(result);
        }

        /// <summary>
        /// Check if a user is blocked
        /// </summary>
        [HttpGet("{blockerId}/is-blocked/{blockedUserId}")]
        public async Task<ActionResult<bool>> IsUserBlocked(int blockerId, int blockedUserId)
        {
            var isBlocked = await _userService.IsUserBlockedAsync(blockerId, blockedUserId);
            return Ok(isBlocked);
        }

        /// <summary>
        /// Get list of blocked users
        /// </summary>
        [HttpGet("{blockerId}/blocked-users")]
        public async Task<ActionResult<IEnumerable<BlockedUserResponseDto>>> GetBlockedUsers(int blockerId)
        {
            var blockedUsers = await _userService.GetBlockedUsersAsync(blockerId);
            return Ok(blockedUsers);
        }
    }
}