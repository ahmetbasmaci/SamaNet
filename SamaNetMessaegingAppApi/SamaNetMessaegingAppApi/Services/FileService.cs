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
            ["image"] = new() { "image/jpeg", "image/png", "image/gif", "image/webp" },
            ["video"] = new() { "video/mp4", "video/avi", "video/mov", "video/wmv" },
            ["audio"] = new() { "audio/mpeg", "audio/wav", "audio/ogg", "audio/mp3" },
            ["file"] = new() { "application/pdf", "application/doc", "application/docx", "text/plain" }
        };

        public FileService(IWebHostEnvironment environment)
        {
            _environment = environment;
        }

        public async Task<FileUploadResponseDto> SaveFileAsync(IFormFile file, string messageType)
        {
            try
            {
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

                if (!IsValidFileType(file.ContentType, messageType))
                {
                    return new FileUploadResponseDto
                    {
                        Success = false,
                        Message = $"Invalid file type for {messageType} message"
                    };
                }

                // Create uploads directory if it doesn't exist
                var uploadsPath = Path.Combine(_environment.ContentRootPath, "uploads", messageType);
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
                var relativePath = Path.Combine("uploads", messageType, fileName).Replace("\\", "/");

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

        public async Task<bool> DeleteFileAsync(string filePath)
        {
            try
            {
                var fullPath = Path.Combine(_environment.ContentRootPath, filePath);
                if (File.Exists(fullPath))
                {
                    File.Delete(fullPath);
                    return true;
                }
                return false;
            }
            catch
            {
                return false;
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

        public bool IsValidFileType(string fileType, string messageType)
        {
            if (!_allowedFileTypes.ContainsKey(messageType))
                return false;

            return _allowedFileTypes[messageType].Contains(fileType.ToLower());
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
                ".mp4" => "video/mp4",
                ".avi" => "video/avi",
                ".mp3" => "audio/mpeg",
                ".wav" => "audio/wav",
                ".pdf" => "application/pdf",
                ".txt" => "text/plain",
                _ => "application/octet-stream"
            };
        }
    }
}