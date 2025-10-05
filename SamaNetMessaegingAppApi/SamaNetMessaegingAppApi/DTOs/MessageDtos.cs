using System.ComponentModel.DataAnnotations;

namespace SamaNetMessaegingAppApi.DTOs
{
    /// <summary>
    /// DTO for sending a text message
    /// </summary>
    public class SendMessageRequestDto
    {
        [Required]
        public int ReceiverId { get; set; }

        [Required]
        [StringLength(20)]
        public string MessageType { get; set; } = "text";

        public string? Content { get; set; }
    }
    public class SendMessageWithAttachmentRequestDto
    {
        [Required]
        public IFormFile File { get; set; }

        [Required]
        public int ReceiverId { get; set; }

        public string? Content { get; set; }

        public string MessageType { get; set; } = "file";
    }



    /// <summary>
    /// DTO for message response
    /// </summary>
    public class MessageResponseDto
    {
        public int Id { get; set; }
        public int SenderId { get; set; }
        public int ReceiverId { get; set; }
        public string MessageType { get; set; } = string.Empty;
        public string? Content { get; set; }
        public DateTime SentAt { get; set; }
        public DateTime? DeliveredAt { get; set; }
        public DateTime? ReadAt { get; set; }
        public List<AttachmentResponseDto> Attachments { get; set; } = new List<AttachmentResponseDto>();

        // Simplified user info to avoid circular references
        public string? SenderUsername { get; set; }
        public string? ReceiverUsername { get; set; }
    }

    /// <summary>
    /// DTO for attachment response
    /// </summary>
    public class AttachmentResponseDto
    {
        public int Id { get; set; }
        public string FilePath { get; set; } = string.Empty;
        public string FileType { get; set; } = string.Empty;
        public long FileSize { get; set; }
    }

    /// <summary>
    /// DTO for conversation request
    /// </summary>
    public class ConversationRequestDto
    {
        [Required]
        public int UserId { get; set; }

        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 50;
    }

    /// <summary>
    /// DTO for marking message as read
    /// </summary>
    public class MarkMessageReadDto
    {
        [Required]
        public int MessageId { get; set; }
    }

    /// <summary>
    /// DTO for file upload response
    /// </summary>
    public class FileUploadResponseDto
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? FilePath { get; set; }
        public long FileSize { get; set; }
        public string? FileType { get; set; }
    }
    public class FileUploadRequestDto
    {
        [Required]
        public IFormFile File { get; set; }

        public string MessageType { get; set; } = "file";
    }

    /// <summary>
    /// DTO for conversation response in recent conversations list
    /// </summary>
    public class ConversationResponseDto
    {
        public int Id { get; set; }
        public UserResponseDto OtherUser { get; set; } = new UserResponseDto();
        public MessageResponseDto? LastMessage { get; set; }
        public int UnreadCount { get; set; }
        public DateTime LastActivity { get; set; }
    }

}