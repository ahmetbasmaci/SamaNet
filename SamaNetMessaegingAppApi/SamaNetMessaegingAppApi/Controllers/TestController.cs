using Microsoft.AspNetCore.Mvc;

namespace SamaNetMessaegingAppApi.Controllers
{
    /// <summary>
    /// Simple test controller for debugging Swagger issues
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        /// <summary>
        /// Simple test endpoint
        /// </summary>
        [HttpGet]
        public ActionResult<string> Get()
        {
            return Ok("Test endpoint is working!");
        }

        /// <summary>
        /// Test endpoint with parameter
        /// </summary>
        [HttpGet("{id}")]
        public ActionResult<object> GetById(int id)
        {
            return Ok(new { id, message = "Test with parameter", timestamp = DateTime.UtcNow });
        }

        /// <summary>
        /// Test POST endpoint
        /// </summary>
        [HttpPost]
        public ActionResult<object> Post([FromBody] object data)
        {
            return Ok(new { received = data, timestamp = DateTime.UtcNow });
        }
    }
}