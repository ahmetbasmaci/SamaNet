using Microsoft.AspNetCore.Mvc;
using SamaNetMessaegingAppApi.DTOs;
using SamaNetMessaegingAppApi.Services.Interfaces;

namespace SamaNetMessaegingAppApi.Controllers
{
    /// <summary>
    /// Controller for message operations and conversations
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class MessagesController : ControllerBase
    {
        private readonly IMessageService _messageService;

        public MessagesController(IMessageService messageService)
        {
            _messageService = messageService;
        }

        /// <summary>
        /// Send a text message to another user
        /// </summary>
        [HttpPost("send")]
        public async Task<ActionResult<MessageResponseDto>> SendMessage([FromBody] SendMessageRequestDto request, [FromHeader(Name = "X-User-Id")] string? senderIdHeader = null)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (string.IsNullOrEmpty(senderIdHeader) || !int.TryParse(senderIdHeader, out int senderId) || senderId <= 0)
            {
                return BadRequest("Valid sender ID is required in X-User-Id header");
            }

            try
            {
                var message = await _messageService.SendMessageAsync(senderId, request);
                return Ok(message);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        /// <summary>
        /// Send a message with file attachment
        /// </summary>
        [HttpPost("send-with-attachment")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<MessageResponseDto>> SendMessageWithAttachment(
            [FromForm] SendMessageWithAttachmentRequestDto request,
            [FromHeader(Name = "X-User-Id")] string? senderIdHeader = null)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            if (string.IsNullOrEmpty(senderIdHeader) || !int.TryParse(senderIdHeader, out int senderId) || senderId <= 0)
                return BadRequest("Valid sender ID is required in X-User-Id header");

            if (request.File == null || request.File.Length == 0)
                return BadRequest("File is required");

            try
            {
                var messageRequest = new SendMessageRequestDto
                {
                    ReceiverId = request.ReceiverId,
                    Content = request.Content,
                    MessageType = request.MessageType
                };

                var message = await _messageService.SendMessageWithAttachmentAsync(senderId, messageRequest, request.File);
                return Ok(message);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }


        /// <summary>
        /// Get conversation messages between current user and another user
        /// </summary>
        [HttpGet("conversation")]
        public async Task<ActionResult<IEnumerable<MessageResponseDto>>> GetConversation(
            [FromQuery] ConversationRequestDto request,
            [FromHeader(Name = "X-User-Id")] string? currentUserIdHeader = null)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (string.IsNullOrEmpty(currentUserIdHeader) || !int.TryParse(currentUserIdHeader, out int currentUserId) || currentUserId <= 0)
            {
                return BadRequest("Valid current user ID is required in X-User-Id header");
            }

            try
            {
                var messages = await _messageService.GetConversationAsync(currentUserId, request);
                return Ok(messages);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        /// <summary>
        /// Mark a message as read
        /// </summary>
        [HttpPut("{messageId}/read")]
        public async Task<ActionResult> MarkMessageAsRead(int messageId, [FromHeader(Name = "X-User-Id")] string? userIdHeader = null)
        {
            if (messageId <= 0)
            {
                return BadRequest("Valid message ID is required");
            }

            if (string.IsNullOrEmpty(userIdHeader) || !int.TryParse(userIdHeader, out int userId) || userId <= 0)
            {
                return BadRequest("Valid user ID is required in X-User-Id header");
            }

            try
            {
                var success = await _messageService.MarkMessageAsReadAsync(userId, messageId);

                if (!success)
                {
                    return NotFound("Message not found or access denied");
                }

                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        /// <summary>
        /// Mark a message as delivered
        /// </summary>
        [HttpPut("{messageId}/delivered")]
        public async Task<ActionResult> MarkMessageAsDelivered(int messageId)
        {
            if (messageId <= 0)
            {
                return BadRequest("Valid message ID is required");
            }

            try
            {
                var success = await _messageService.MarkMessageAsDeliveredAsync(messageId);

                if (!success)
                {
                    return NotFound("Message not found");
                }

                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        /// <summary>
        /// Get unread message count for a user
        /// </summary>
        [HttpGet("unread-count")]
        public async Task<ActionResult<int>> GetUnreadCount([FromHeader(Name = "X-User-Id")] string? userIdHeader = null)
        {
            if (string.IsNullOrEmpty(userIdHeader) || !int.TryParse(userIdHeader, out int userId) || userId <= 0)
            {
                return BadRequest("Valid user ID is required in X-User-Id header");
            }

            try
            {
                var count = await _messageService.GetUnreadCountAsync(userId);
                return Ok(count);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        /// <summary>
        /// Get a specific message by ID
        /// </summary>
        [HttpGet("{messageId}")]
        public async Task<ActionResult<MessageResponseDto>> GetMessage(int messageId)
        {
            if (messageId <= 0)
            {
                return BadRequest("Valid message ID is required");
            }

            try
            {
                var message = await _messageService.GetMessageByIdAsync(messageId);

                if (message == null)
                {
                    return NotFound("Message not found");
                }

                return Ok(message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        /// <summary>
        /// Get recent conversations for current user
        /// </summary>
        [HttpGet("recent-conversations")]
        public async Task<ActionResult<IEnumerable<ConversationResponseDto>>> GetRecentConversations(
            [FromQuery] int limit = 20,
            [FromHeader(Name = "X-User-Id")] string? userIdHeader = null)
        {
            if (string.IsNullOrEmpty(userIdHeader) || !int.TryParse(userIdHeader, out int userId) || userId <= 0)
            {
                return BadRequest("Valid user ID is required in X-User-Id header");
            }

            if (limit <= 0 || limit > 100)
            {
                return BadRequest("Limit must be between 1 and 100");
            }

            try
            {
                var conversations = await _messageService.GetRecentConversationsAsync(userId, limit);
                return Ok(conversations);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        /// <summary>
        /// Get API status and available endpoints
        /// </summary>
        [HttpGet("status")]
        public ActionResult GetStatus()
        {
            return Ok(new
            {
                service = "Messages API",
                status = "running",
                timestamp = DateTime.UtcNow,
                endpoints = new
                {
                    sendMessage = "POST /api/messages/send",
                    sendWithAttachment = "POST /api/messages/send-with-attachment",
                    getConversation = "GET /api/messages/conversation",
                    getRecentConversations = "GET /api/messages/recent-conversations",
                    markAsRead = "PUT /api/messages/{messageId}/read",
                    markAsDelivered = "PUT /api/messages/{messageId}/delivered",
                    getUnreadCount = "GET /api/messages/unread-count",
                    getMessage = "GET /api/messages/{messageId}"
                },
                note = "Most endpoints require X-User-Id header for authentication"
            });
        }
    }
}