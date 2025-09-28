using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using SamaNetMessaegingAppApi.Data;

#nullable disable

namespace SamaNetMessaegingAppApi.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(ChatDbContext))]
    [Migration("20250928000000_AddUserAvatar")]
    public partial class AddUserAvatar : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AvatarPath",
                table: "Users",
                type: "TEXT",
                maxLength: 255,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AvatarPath",
                table: "Users");
        }
    }
}
