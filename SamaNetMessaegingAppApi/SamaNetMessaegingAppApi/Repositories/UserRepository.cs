using Microsoft.EntityFrameworkCore;
using SamaNetMessaegingAppApi.Data;
using SamaNetMessaegingAppApi.Models;
using SamaNetMessaegingAppApi.Repositories.Interfaces;

namespace SamaNetMessaegingAppApi.Repositories
{
    /// <summary>
    /// Repository implementation for User entity operations
    /// </summary>
    public class UserRepository : IUserRepository
    {
        private readonly ChatDbContext _context;

        public UserRepository(ChatDbContext context)
        {
            _context = context;
        }

        public async Task<User?> GetByIdAsync(int id)
        {
            return await _context.Users.FindAsync(id);
        }

        public async Task<User?> GetByUsernameAsync(string username)
        {
            return await _context.Users
                .FirstOrDefaultAsync(u => u.Username == username);
        }

        public async Task<User?> GetByPhoneNumberAsync(string phoneNumber)
        {
            return await _context.Users
                .FirstOrDefaultAsync(u => u.PhoneNumber == phoneNumber);
        }

        public async Task<IEnumerable<User>> SearchByPhoneNumberAsync(string phoneNumber)
        {
            return await _context.Users
                .Where(u => u.PhoneNumber.Contains(phoneNumber))
                .Take(10) // Limit results
                .ToListAsync();
        }

        public async Task<IEnumerable<User>> SearchByUsernameAsync(string username)
        {
            return await _context.Users
                .Where(u => u.Username.Contains(username))
                .Take(10) // Limit results
                .ToListAsync();
        }

        public async Task<User> CreateAsync(User user)
        {
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return user;
        }

        public async Task<User> UpdateAsync(User user)
        {
            _context.Users.Update(user);
            await _context.SaveChangesAsync();
            return user;
        }

        public async Task DeleteAsync(int id)
        {
            var user = await GetByIdAsync(id);
            if (user != null)
            {
                _context.Users.Remove(user);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<bool> ExistsAsync(int id)
        {
            return await _context.Users.AnyAsync(u => u.Id == id);
        }

        public async Task<bool> UsernameExistsAsync(string username)
        {
            return await _context.Users.AnyAsync(u => u.Username == username);
        }

        public async Task<bool> PhoneNumberExistsAsync(string phoneNumber)
        {
            return await _context.Users.AnyAsync(u => u.PhoneNumber == phoneNumber);
        }
    }
}