using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;

namespace SamaNetMessaegingAppApi.Controllers
{
    /// <summary>
    /// Controller for health checks and API status
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class HealthController : ControllerBase
    {
        /// <summary>
        /// Health check endpoint to verify API is running
        /// </summary>
        [HttpGet]
        public ActionResult GetHealth()
        {
            return Ok(new
            {
                status = "healthy",
                timestamp = DateTime.UtcNow,
                version = "1.0.0",
                environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production"
            });
        }

        /// <summary>
        /// Detailed health check with system information
        /// </summary>
        [HttpGet("detailed")]
        public ActionResult GetDetailedHealth()
        {
            return Ok(new
            {
                status = "healthy",
                timestamp = DateTime.UtcNow,
                version = "1.0.0",
                environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production",
                system = new
                {
                    machineName = Environment.MachineName,
                    osVersion = Environment.OSVersion.ToString(),
                    processorCount = Environment.ProcessorCount,
                    workingSet = Environment.WorkingSet,
                    uptime = DateTime.UtcNow - Process.GetCurrentProcess().StartTime.ToUniversalTime()
                },
                features = new
                {
                    realTimeMessaging = true,
                    fileUploads = true,
                    userAuthentication = true,
                    messageDeliveryTracking = true,
                    readReceipts = true
                }
            });
        }
    }
}