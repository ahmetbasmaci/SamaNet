using Microsoft.AspNetCore.Mvc;
using SamaNetMessaegingAppApi.DTOs;
using SamaNetMessaegingAppApi.Services.Interfaces;

namespace SamaNetMessaegingAppApi.Controllers
{
    /// <summary>
    /// Controller for file upload, download, and management operations
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class FilesController : ControllerBase
    {
        private readonly IFileService _fileService;

        public FilesController(IFileService fileService)
        {
            _fileService = fileService;
        }

        [HttpPost("upload")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<FileUploadResponseDto>> UploadFile([FromForm] FileUploadRequestDto request)
        {
            if (request.File == null || request.File.Length == 0)
                return BadRequest("No file provided");

            var validTypes = new[] { "image", "video", "audio", "file" };
            if (!validTypes.Contains(request.MessageType.ToLower()))
                return BadRequest($"Invalid message type. Valid types are: {string.Join(", ", validTypes)}");

            var result = await _fileService.SaveFileAsync(request.File, request.MessageType.ToLower());

            return result.Success ? Ok(result) : BadRequest(result);
        }


        /// <summary>
        /// Download a file by its path
        /// </summary>
        [HttpGet("download")]
        public async Task<ActionResult> DownloadFile([FromQuery] string filePath)
        {
            if (string.IsNullOrWhiteSpace(filePath))
            {
                return BadRequest("File path is required");
            }

            try
            {
                var (content, contentType, fileName) = await _fileService.GetFileAsync(filePath);
                return File(content, contentType, fileName);
            }
            catch (FileNotFoundException)
            {
                return NotFound("File not found");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        /// <summary>
        /// Stream a file for direct viewing (images, videos, etc.)
        /// </summary>
        [HttpGet("stream")]
        public async Task<ActionResult> StreamFile([FromQuery] string filePath)
        {
            if (string.IsNullOrWhiteSpace(filePath))
            {
                return BadRequest("File path is required");
            }

            try
            {
                var (content, contentType, fileName) = await _fileService.GetFileAsync(filePath);

                // Set headers for streaming  
                Response.Headers["Content-Disposition"] = $"inline; filename=\"{fileName}\"";
                Response.Headers["Cache-Control"] = "public, max-age=31536000"; // Cache for 1 year

                return File(content, contentType);
            }
            catch (FileNotFoundException)
            {
                return NotFound("File not found");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        /// <summary>
        /// Delete a file from the server
        /// </summary>
        [HttpDelete("delete")]
        public async Task<ActionResult> DeleteFile([FromQuery] string filePath)
        {
            if (string.IsNullOrWhiteSpace(filePath))
            {
                return BadRequest("File path is required");
            }

            try
            {
                var success = await _fileService.DeleteFileAsync(filePath);

                if (success)
                {
                    return Ok(new { message = "File deleted successfully" });
                }

                return NotFound("File not found");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
        /// <summary>
        /// Validate file type and size before upload
        /// </summary>
        [HttpPost("validate")]
        [Consumes("multipart/form-data")]
        public ActionResult ValidateFile([FromForm] FileUploadRequestDto request)
        {
            if (request.File == null || request.File.Length == 0)
                return BadRequest("No file provided");

            var validTypes = new[] { "image", "video", "audio", "file" };
            if (!validTypes.Contains(request.MessageType.ToLower()))
                return BadRequest($"Invalid message type. Valid types are: {string.Join(", ", validTypes)}");

            try
            {
                var isValidType = _fileService.IsValidFileType(request.File.ContentType, request.MessageType.ToLower(), request.File.FileName);
                var isValidSize = _fileService.IsValidFileSize(request.File.Length);

                var validation = new
                {
                    isValidType,
                    isValidSize,
                    fileType = request.File.ContentType,
                    fileSize = request.File.Length,
                    maxSize = 200 * 1024 * 1024, // 200MB
                    message = !isValidType ? $"Invalid file type for {request.MessageType}" :
                             !isValidSize ? "File size exceeds maximum limit" :
                             "File is valid"
                };

                return (isValidType && isValidSize) ? Ok(validation) : BadRequest(validation);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }


        /// <summary>
        /// Get file information without downloading
        /// </summary>
        [HttpGet("info")]
        public async Task<ActionResult> GetFileInfo([FromQuery] string filePath)
        {
            if (string.IsNullOrWhiteSpace(filePath))
            {
                return BadRequest("File path is required");
            }

            try
            {
                var (content, contentType, fileName) = await _fileService.GetFileAsync(filePath);

                var fileInfo = new
                {
                    fileName,
                    contentType,
                    size = content.Length,
                    lastModified = System.IO.File.GetLastWriteTime(Path.Combine(Directory.GetCurrentDirectory(), filePath)),
                    exists = true
                };

                return Ok(fileInfo);
            }
            catch (FileNotFoundException)
            {
                return NotFound(new { fileName = Path.GetFileName(filePath), exists = false });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}