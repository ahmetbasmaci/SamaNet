using SamaNetMessaegingAppApi.Models;

namespace SamaNetMessaegingAppApi.Repositories.Interfaces
{
    /// <summary>
    /// Repository interface for User entity operations
    /// </summary>
    public interface IUserRepository
    {
        Task<User?> GetByIdAsync(int id);
        Task<User?> GetByUsernameAsync(string username);
        Task<User?> GetByPhoneNumberAsync(string phoneNumber);
        Task<IEnumerable<User>> SearchByPhoneNumberAsync(string phoneNumber);
        Task<IEnumerable<User>> SearchByUsernameAsync(string username);
        Task<User> CreateAsync(User user);
        Task<User> UpdateAsync(User user);
        Task DeleteAsync(int id);
        Task<bool> ExistsAsync(int id);
        Task<bool> UsernameExistsAsync(string username);
        Task<bool> PhoneNumberExistsAsync(string phoneNumber);
    }
}