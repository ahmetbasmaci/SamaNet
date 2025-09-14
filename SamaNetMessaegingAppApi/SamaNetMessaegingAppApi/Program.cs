using Microsoft.EntityFrameworkCore;
using SamaNetMessaegingAppApi.Data;
using SamaNetMessaegingAppApi.Hubs;
using SamaNetMessaegingAppApi.Repositories;
using SamaNetMessaegingAppApi.Repositories.Interfaces;
using SamaNetMessaegingAppApi.Services;
using SamaNetMessaegingAppApi.Services.Interfaces;

namespace SamaNetMessaegingAppApi
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container
            ConfigureServices(builder.Services, builder.Configuration);

            var app = builder.Build();

            // Configure the HTTP request pipeline
            ConfigureApp(app);

            // Initialize database
            InitializeDatabase(app);

            app.Run();
        }

        private static void ConfigureServices(IServiceCollection services, IConfiguration configuration)
        {
            // Add controllers
            services.AddControllers();


            // Add Entity Framework and SQLite
            services.AddDbContext<ChatDbContext>(options =>
                options.UseSqlite(configuration.GetConnectionString("DefaultConnection") ??
                                "Data Source=chat_database.db"));

            // Add SignalR for real-time messaging
            services.AddSignalR(options =>
            {
                options.MaximumReceiveMessageSize = 200 * 1024 * 1024; // 200MB for large files
                options.EnableDetailedErrors = true;
            });

            // Add CORS for cross-origin requests
            services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", policy =>
                {
                    policy.AllowAnyOrigin()
                          .AllowAnyMethod()
                          .AllowAnyHeader();
                });

                options.AddPolicy("ChatAppPolicy", policy =>
                {
                    policy.WithOrigins("http://localhost:3000", "https://localhost:3000") // React/Angular dev servers
                          .AllowAnyMethod()
                          .AllowAnyHeader()
                          .AllowCredentials(); // Required for SignalR
                });
            });

            // Register repositories
            services.AddScoped<IUserRepository, UserRepository>();
            services.AddScoped<IMessageRepository, MessageRepository>();
            services.AddScoped<IAttachmentRepository, AttachmentRepository>();
            services.AddScoped<IMessageDeletionRepository, MessageDeletionRepository>();

            // Register services
            services.AddScoped<IUserService, UserService>();
            services.AddScoped<IMessageService, MessageService>();
            services.AddScoped<IFileService, FileService>();

            // Add API documentation
            services.AddEndpointsApiExplorer();


            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
                {
                    Title = "Chat Application API",
                    Version = "v1",
                    Description = "RESTful API for a real-time chat application"
                });

                c.MapType<IFormFile>(() => new Microsoft.OpenApi.Models.OpenApiSchema
                {
                    Type = "string",
                    Format = "binary"
                });
            });


            // Configure file upload limits
            services.Configure<Microsoft.AspNetCore.Http.Features.FormOptions>(options =>
            {
                options.MultipartBodyLengthLimit = 200 * 1024 * 1024; // 200MB
                options.ValueLengthLimit = 200 * 1024 * 1024;
                options.MultipartHeadersLengthLimit = int.MaxValue;
            });

            // Add logging
            services.AddLogging(builder =>
            {
                builder.AddConsole();
                builder.AddDebug();
            });
        }

        private static void ConfigureApp(WebApplication app)
        {
            // Configure the HTTP request pipeline
            if (app.Environment.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                app.UseSwagger();
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Chat Application API v1");
                    c.RoutePrefix = "swagger"; // Serve Swagger UI at /swagger
                });
            }
            else
            {
                app.UseExceptionHandler("/Error");
                app.UseHsts();
            }

            // Enable CORS
            app.UseCors("ChatAppPolicy");

            // Enable HTTPS redirection
            app.UseHttpsRedirection();

            // Enable static files for file serving
            app.UseStaticFiles();

            // Add routing
            app.UseRouting();

            // Add authorization (placeholder for future JWT implementation)
            app.UseAuthorization();

            // Configure request size limits for large file uploads
            app.Use(async (context, next) =>
            {
                context.Features.Get<Microsoft.AspNetCore.Http.Features.IHttpMaxRequestBodySizeFeature>()!
                    .MaxRequestBodySize = 200 * 1024 * 1024; // 200MB
                await next();
            });

            // Map controllers
            app.MapControllers();

            // Map SignalR Hub
            app.MapHub<ChatHub>("/chatHub");

            // Add API info endpoint at root
            app.MapGet("/", () => new
            {
                message = "Chat Application API is running",
                timestamp = DateTime.UtcNow,
                version = "1.0.0",
                endpoints = new
                {
                    swagger = "/swagger",
                    api = "/api",
                    chatHub = "/chatHub",
                    health = "/api/health"
                },
                documentation = "Visit /swagger for API documentation"
            });
        }

        private static void InitializeDatabase(WebApplication app)
        {
            try
            {
                using var scope = app.Services.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<ChatDbContext>();

                // Ensure database is created
                context.Database.EnsureCreated();

                var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
                logger.LogInformation("Database initialized successfully");
            }
            catch (Exception ex)
            {
                var logger = app.Services.GetRequiredService<ILogger<Program>>();
                logger.LogError(ex, "An error occurred while initializing the database");
                throw;
            }
        }
    }
}
