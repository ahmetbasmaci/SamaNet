using Microsoft.EntityFrameworkCore;
using SamaNetMessaegingAppApi.Models;

namespace SamaNetMessaegingAppApi.Data
{
    /// <summary>
    /// Database context for the chat application
    /// </summary>
    public class ChatDbContext : DbContext
    {
        public ChatDbContext(DbContextOptions<ChatDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Message> Messages { get; set; }
        public DbSet<Attachment> Attachments { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure User entity
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Username).IsRequired().HasMaxLength(50);
                entity.Property(e => e.PasswordHash).IsRequired();
                entity.Property(e => e.PhoneNumber).IsRequired().HasMaxLength(20);
                entity.HasIndex(e => e.PhoneNumber).IsUnique().HasDatabaseName("IDX_Users_Phone");
                entity.Property(e => e.DisplayName).HasMaxLength(100);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
            });

            // Configure Message entity
            modelBuilder.Entity<Message>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.MessageType).IsRequired().HasMaxLength(20);
                entity.Property(e => e.SentAt).HasDefaultValueSql("CURRENT_TIMESTAMP");

                // Configure relationships
                entity.HasOne(e => e.Sender)
                    .WithMany(u => u.SentMessages)
                    .HasForeignKey(e => e.SenderId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(e => e.Receiver)
                    .WithMany(u => u.ReceivedMessages)
                    .HasForeignKey(e => e.ReceiverId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Add indexes for performance
                entity.HasIndex(e => e.SenderId).HasDatabaseName("IDX_Messages_Sender");
                entity.HasIndex(e => e.ReceiverId).HasDatabaseName("IDX_Messages_Receiver");
            });

            // Configure Attachment entity
            modelBuilder.Entity<Attachment>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.FilePath).IsRequired();
                entity.Property(e => e.FileType).IsRequired().HasMaxLength(100);
                entity.Property(e => e.FileSize).IsRequired();

                // Configure relationship
                entity.HasOne(e => e.Message)
                    .WithMany(m => m.Attachments)
                    .HasForeignKey(e => e.MessageId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Add index for performance
                entity.HasIndex(e => e.MessageId).HasDatabaseName("IDX_Attachments_Message");
            });
        }
    }
}