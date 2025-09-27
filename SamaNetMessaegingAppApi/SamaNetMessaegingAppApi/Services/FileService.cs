using SamaNetMessaegingAppApi.DTOs;
using SamaNetMessaegingAppApi.Services.Interfaces;

namespace SamaNetMessaegingAppApi.Services
{
    /// <summary>
    /// Service implementation for file handling operations
    /// </summary>
    public class FileService : IFileService
    {
        private readonly IWebHostEnvironment _environment;
        private readonly long _maxFileSize = 200 * 1024 * 1024; // 200MB
        private readonly Dictionary<string, List<string>> _allowedFileTypes = new()
        {
            ["image"] = new()
            {
                "image/jpeg",
                "image/jpg",
                "image/png",
                "image/gif",
                "image/webp",
                "image/bmp",
                "image/heic",
                "image/heif",
                "image/pjpeg"
            },
            ["video"] = new()
            {
                "video/mp4",
                "video/avi",
                "video/mov",
                "video/quicktime",
                "video/wmv",
                "video/x-ms-wmv",
                "video/x-matroska",
                "video/x-flv",
                "video/webm"
            },
            ["audio"] = new()
            {
                "audio/mpeg",
                "audio/wav",
                "audio/ogg",
                "audio/mp3",
                "audio/aac",
                "audio/flac",
                "audio/mp4",
                "audio/x-m4a"
            },
            ["file"] = new()
            {
                "application/pdf",
                "application/msword",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "application/rtf",
                "text/plain"
            }
        };
        private readonly Dictionary<string, List<string>> _allowedFileExtensions = new()
        {
            ["image"] = new() { ".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".heic", ".heif" },
            ["video"] = new() { ".mp4", ".avi", ".mov", ".wmv", ".mkv", ".flv", ".webm" },
            ["audio"] = new() { ".mp3", ".wav", ".aac", ".ogg", ".flac", ".m4a" },
            ["file"] = new() { ".pdf", ".doc", ".docx", ".txt", ".rtf" }
        };

        public FileService(IWebHostEnvironment environment)
        {
            _environment = environment;
        }

        public async Task<FileUploadResponseDto> SaveFileAsync(IFormFile file, string messageType)
        {
            try
            {
                var normalizedMessageType = messageType.ToLowerInvariant();

                if (file == null || file.Length == 0)
                {
                    return new FileUploadResponseDto
                    {
                        Success = false,
                        Message = "No file provided"
                    };
                }

                if (!IsValidFileSize(file.Length))
                {
                    return new FileUploadResponseDto
                    {
                        Success = false,
                        Message = $"File size exceeds maximum limit of {_maxFileSize / (1024 * 1024)}MB"
                    };
                }

                if (!IsValidFileType(file.ContentType, normalizedMessageType, file.FileName))
                {
                    return new FileUploadResponseDto
                    {
                        Success = false,
                        Message = $"Invalid file type for {normalizedMessageType} message"
                    };
                }

                // Create uploads directory if it doesn't exist
                var uploadsPath = Path.Combine(_environment.ContentRootPath, "uploads", normalizedMessageType);
                Directory.CreateDirectory(uploadsPath);

                // Generate unique filename
                var fileExtension = Path.GetExtension(file.FileName);
                var fileName = $"{Guid.NewGuid()}{fileExtension}";
                var filePath = Path.Combine(uploadsPath, fileName);

                // Save file
                using (var fileStream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(fileStream);
                }

                // Return relative path for storage in database
                var relativePath = Path.Combine("uploads", normalizedMessageType, fileName).Replace("\\", "/");

                return new FileUploadResponseDto
                {
                    Success = true,
                    Message = "File uploaded successfully",
                    FilePath = relativePath,
                    FileSize = file.Length,
                    FileType = file.ContentType
                };
            }
            catch (Exception ex)
            {
                return new FileUploadResponseDto
                {
                    Success = false,
                    Message = $"File upload failed: {ex.Message}"
                };
            }
        }

        public Task<bool> DeleteFileAsync(string filePath)
        {
            try
            {
                var fullPath = Path.Combine(_environment.ContentRootPath, filePath);
                if (File.Exists(fullPath))
                {
                    File.Delete(fullPath);
                    return Task.FromResult(true);
                }
                return Task.FromResult(false);
            }
            catch
            {
                return Task.FromResult(false);
            }
        }

        public async Task<(byte[] content, string contentType, string fileName)> GetFileAsync(string filePath)
        {
            var fullPath = Path.Combine(_environment.ContentRootPath, filePath);

            if (!File.Exists(fullPath))
            {
                throw new FileNotFoundException("File not found");
            }

            var content = await File.ReadAllBytesAsync(fullPath);
            var contentType = GetContentType(Path.GetExtension(fullPath));
            var fileName = Path.GetFileName(fullPath);

            return (content, contentType, fileName);
        }

        public bool IsValidFileType(string fileType, string messageType, string fileName)
        {
            if (!_allowedFileTypes.ContainsKey(messageType))
                return false;

            var normalizedType = fileType?.ToLowerInvariant() ?? string.Empty;
            if (!string.IsNullOrEmpty(normalizedType) && _allowedFileTypes[messageType].Contains(normalizedType))
            {
                return true;
            }

            var extension = Path.GetExtension(fileName)?.ToLowerInvariant() ?? string.Empty;
            if (!string.IsNullOrEmpty(extension) &&
                _allowedFileExtensions.TryGetValue(messageType, out var extensions) &&
                extensions.Contains(extension))
            {
                return true;
            }

            if (string.IsNullOrEmpty(normalizedType) || normalizedType == "application/octet-stream")
            {
                var fallbackType = GetContentType(extension);
                if (!string.IsNullOrEmpty(fallbackType) && _allowedFileTypes[messageType].Contains(fallbackType))
                {
                    return true;
                }
            }

            return false;
        }

        public bool IsValidFileSize(long fileSize)
        {
            return fileSize <= _maxFileSize;
        }

        private static string GetContentType(string extension)
        {
            return extension.ToLower() switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".gif" => "image/gif",
                ".bmp" => "image/bmp",
                ".webp" => "image/webp",
                ".heic" or ".heif" => "image/heic",
                ".mp4" => "video/mp4",
                ".avi" => "video/avi",
                ".mov" => "video/mov",
                ".wmv" => "video/wmv",
                ".mkv" => "video/x-matroska",
                ".flv" => "video/x-flv",
                ".webm" => "video/webm",
                ".mp3" => "audio/mpeg",
                ".wav" => "audio/wav",
                ".aac" => "audio/aac",
                ".ogg" => "audio/ogg",
                ".flac" => "audio/flac",
                ".m4a" => "audio/mp4",
                ".pdf" => "application/pdf",
                ".doc" => "application/msword",
                ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                ".rtf" => "application/rtf",
                ".txt" => "text/plain",
                _ => "application/octet-stream"
            };
        }
    }
}