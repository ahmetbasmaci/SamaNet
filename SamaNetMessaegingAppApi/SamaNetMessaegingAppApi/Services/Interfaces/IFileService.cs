using SamaNetMessaegingAppApi.DTOs;

namespace SamaNetMessaegingAppApi.Services.Interfaces
{
    /// <summary>
    /// Service interface for file handling operations
    /// </summary>
    public interface IFileService
    {
        Task<FileUploadResponseDto> SaveFileAsync(IFormFile file, string messageType);
        Task<bool> DeleteFileAsync(string filePath);
        Task<(byte[] content, string contentType, string fileName)> GetFileAsync(string filePath);
        bool IsValidFileType(string fileType, string messageType);
        bool IsValidFileSize(long fileSize);
    }
}