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
        /// Supports HTTP Range requests for video streaming
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
                var fullPath = Path.Combine(Directory.GetCurrentDirectory(), filePath);
                if (!System.IO.File.Exists(fullPath))
                {
                    return NotFound("File not found");
                }

                var fileInfo = new FileInfo(fullPath);
                var contentType = GetContentType(fullPath);
                
                // For video files, support HTTP Range requests
                if (contentType.StartsWith("video/"))
                {
                    return await StreamVideoWithRangeSupport(fullPath, fileInfo, contentType);
                }

                // For other files (images, etc.), return the entire file
                var (content, _, fileName) = await _fileService.GetFileAsync(filePath);
                Response.Headers["Content-Disposition"] = $"inline; filename=\"{fileName}\"";
                Response.Headers["Cache-Control"] = "public, max-age=31536000";
                Response.Headers["Accept-Ranges"] = "bytes";
                
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

        private async Task<ActionResult> StreamVideoWithRangeSupport(string filePath, FileInfo fileInfo, string contentType)
        {
            var fileLength = fileInfo.Length;
            var rangeHeader = Request.Headers["Range"].ToString();

            // If no range header, return entire file
            if (string.IsNullOrEmpty(rangeHeader))
            {
                Response.Headers["Accept-Ranges"] = "bytes";
                Response.Headers["Content-Length"] = fileLength.ToString();
                Response.Headers["Cache-Control"] = "public, max-age=31536000";
                
                var stream = System.IO.File.OpenRead(filePath);
                return File(stream, contentType, enableRangeProcessing: true);
            }

            // Parse range header (e.g., "bytes=0-1023")
            var range = rangeHeader.Replace("bytes=", "").Split('-');
            var start = long.Parse(range[0]);
            var end = range.Length > 1 && !string.IsNullOrEmpty(range[1]) 
                ? long.Parse(range[1]) 
                : fileLength - 1;

            // Validate range
            if (start > end || start < 0 || end >= fileLength)
            {
                Response.Headers["Content-Range"] = $"bytes */{fileLength}";
                return StatusCode(416); // Range Not Satisfiable
            }

            var length = end - start + 1;

            // Set response headers for partial content
            Response.StatusCode = 206; // Partial Content
            Response.Headers["Accept-Ranges"] = "bytes";
            Response.Headers["Content-Range"] = $"bytes {start}-{end}/{fileLength}";
            Response.Headers["Content-Length"] = length.ToString();
            Response.Headers["Cache-Control"] = "public, max-age=31536000";

            // Stream the requested range
            var fileStream = System.IO.File.OpenRead(filePath);
            fileStream.Seek(start, SeekOrigin.Begin);
            
            var buffer = new byte[length];
            await fileStream.ReadAsync(buffer, 0, (int)length);
            fileStream.Close();

            return File(buffer, contentType);
        }

        private string GetContentType(string filePath)
        {
            var extension = Path.GetExtension(filePath).ToLowerInvariant();
            return extension switch
            {
                ".mp4" => "video/mp4",
                ".webm" => "video/webm",
                ".ogv" => "video/ogg",
                ".avi" => "video/x-msvideo",
                ".mov" => "video/quicktime",
                ".wmv" => "video/x-ms-wmv",
                ".flv" => "video/x-flv",
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".gif" => "image/gif",
                ".webp" => "image/webp",
                ".bmp" => "image/bmp",
                ".mp3" => "audio/mpeg",
                ".wav" => "audio/wav",
                ".ogg" => "audio/ogg",
                ".m4a" => "audio/mp4",
                ".pdf" => "application/pdf",
                _ => "application/octet-stream"
            };
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