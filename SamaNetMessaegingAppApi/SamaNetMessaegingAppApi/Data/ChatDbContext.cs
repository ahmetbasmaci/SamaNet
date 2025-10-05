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
        public DbSet<MessageDeletion> MessageDeletions { get; set; }
        public DbSet<UserBlock> UserBlocks { get; set; }

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
                entity.Property(e => e.AvatarPath).HasMaxLength(255);
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

            // Configure MessageDeletion entity
            modelBuilder.Entity<MessageDeletion>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.DeletedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");

                // Configure relationships
                entity.HasOne(e => e.Message)
                    .WithMany()
                    .HasForeignKey(e => e.MessageId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Ensure unique constraint - one deletion record per user per message
                entity.HasIndex(e => new { e.MessageId, e.UserId })
                    .IsUnique()
                    .HasDatabaseName("IDX_MessageDeletions_Unique");

                // Add indexes for performance
                entity.HasIndex(e => e.MessageId).HasDatabaseName("IDX_MessageDeletions_Message");
                entity.HasIndex(e => e.UserId).HasDatabaseName("IDX_MessageDeletions_User");
            });

            // Configure UserBlock entity
            modelBuilder.Entity<UserBlock>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.BlockedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");

                // Configure relationships
                entity.HasOne(e => e.Blocker)
                    .WithMany()
                    .HasForeignKey(e => e.BlockerId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(e => e.BlockedUser)
                    .WithMany()
                    .HasForeignKey(e => e.BlockedUserId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Ensure unique constraint - one block record per blocker-blocked pair
                entity.HasIndex(e => new { e.BlockerId, e.BlockedUserId })
                    .IsUnique()
                    .HasDatabaseName("IDX_UserBlocks_Unique");

                // Add indexes for performance
                entity.HasIndex(e => e.BlockerId).HasDatabaseName("IDX_UserBlocks_Blocker");
                entity.HasIndex(e => e.BlockedUserId).HasDatabaseName("IDX_UserBlocks_Blocked");
            });
        }
    }
}