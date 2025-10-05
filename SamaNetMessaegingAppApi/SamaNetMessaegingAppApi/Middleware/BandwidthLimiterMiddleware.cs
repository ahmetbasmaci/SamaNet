using System.Diagnostics;

namespace SamaNetMessaegingAppApi.Middleware
{
    /// <summary>
    /// Middleware to limit bandwidth for file uploads and downloads
    /// </summary>
    public class BandwidthLimiterMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<BandwidthLimiterMiddleware> _logger;
        private readonly BandwidthLimiterOptions _options;

        public BandwidthLimiterMiddleware(
            RequestDelegate next,
            ILogger<BandwidthLimiterMiddleware> logger,
            BandwidthLimiterOptions options)
        {
            _next = next;
            _logger = logger;
            _options = options;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            // Check if bandwidth limiting is enabled
            if (!_options.Enabled)
            {
                await _next(context);
                return;
            }

            // Check if the request path matches file operations
            var path = context.Request.Path.ToString().ToLower();
            var isFileOperation = _options.TargetPaths.Any(p => path.Contains(p.ToLower()));

            if (!isFileOperation)
            {
                await _next(context);
                return;
            }

            // Determine if it's an upload or download
            var isUpload = context.Request.Method.Equals("POST", StringComparison.OrdinalIgnoreCase) ||
                          context.Request.Method.Equals("PUT", StringComparison.OrdinalIgnoreCase);
            var isDownload = context.Request.Method.Equals("GET", StringComparison.OrdinalIgnoreCase);

            if (isUpload)
            {
                await HandleUploadWithBandwidthLimit(context);
            }
            else if (isDownload)
            {
                await HandleDownloadWithBandwidthLimit(context);
            }
            else
            {
                await _next(context);
            }
        }

        private async Task HandleUploadWithBandwidthLimit(HttpContext context)
        {
            var maxBytesPerSecond = _options.MaxUploadSpeedKBps * 1024;

            if (maxBytesPerSecond <= 0)
            {
                await _next(context);
                return;
            }

            // Wrap the request body stream with a throttled stream
            var originalBody = context.Request.Body;
            var throttledStream = new ThrottledStream(originalBody, maxBytesPerSecond, _logger);
            context.Request.Body = throttledStream;

            try
            {
                await _next(context);
            }
            finally
            {
                context.Request.Body = originalBody;
            }
        }

        private async Task HandleDownloadWithBandwidthLimit(HttpContext context)
        {
            var maxBytesPerSecond = _options.MaxDownloadSpeedKBps * 1024;

            if (maxBytesPerSecond <= 0)
            {
                await _next(context);
                return;
            }

            // Wrap the response body stream with a throttled stream
            var originalBody = context.Response.Body;
            var throttledStream = new ThrottledStream(originalBody, maxBytesPerSecond, _logger);
            context.Response.Body = throttledStream;

            try
            {
                await _next(context);
            }
            finally
            {
                await throttledStream.FlushAsync();
                context.Response.Body = originalBody;
            }
        }
    }

    /// <summary>
    /// Stream wrapper that throttles read/write operations to limit bandwidth
    /// </summary>
    public class ThrottledStream : Stream
    {
        private readonly Stream _baseStream;
        private readonly int _maxBytesPerSecond;
        private readonly ILogger _logger;
        private readonly Stopwatch _stopwatch;
        private long _totalBytesTransferred;
        private readonly object _lock = new object();

        public ThrottledStream(Stream baseStream, int maxBytesPerSecond, ILogger logger)
        {
            _baseStream = baseStream;
            _maxBytesPerSecond = maxBytesPerSecond;
            _logger = logger;
            _stopwatch = Stopwatch.StartNew();
            _totalBytesTransferred = 0;
        }

        public override bool CanRead => _baseStream.CanRead;
        public override bool CanSeek => _baseStream.CanSeek;
        public override bool CanWrite => _baseStream.CanWrite;
        public override long Length => _baseStream.Length;
        public override long Position
        {
            get => _baseStream.Position;
            set => _baseStream.Position = value;
        }

        public override async Task<int> ReadAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
        {
            await ThrottleIfNeededAsync(count);
            var bytesRead = await _baseStream.ReadAsync(buffer, offset, count, cancellationToken);
            UpdateBytesTransferred(bytesRead);
            return bytesRead;
        }

        public override async Task WriteAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
        {
            await ThrottleIfNeededAsync(count);
            await _baseStream.WriteAsync(buffer, offset, count, cancellationToken);
            UpdateBytesTransferred(count);
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            ThrottleIfNeededAsync(count).Wait();
            var bytesRead = _baseStream.Read(buffer, offset, count);
            UpdateBytesTransferred(bytesRead);
            return bytesRead;
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            ThrottleIfNeededAsync(count).Wait();
            _baseStream.Write(buffer, offset, count);
            UpdateBytesTransferred(count);
        }

        private async Task ThrottleIfNeededAsync(int bytesAboutToTransfer)
        {
            lock (_lock)
            {
                var elapsedSeconds = _stopwatch.Elapsed.TotalSeconds;
                
                if (elapsedSeconds <= 0)
                {
                    return;
                }

                // Calculate expected time based on bytes transferred and max speed
                var expectedTimeSeconds = _totalBytesTransferred / (double)_maxBytesPerSecond;
                
                // If we're ahead of schedule, delay
                if (expectedTimeSeconds > elapsedSeconds)
                {
                    var delayMilliseconds = (int)((expectedTimeSeconds - elapsedSeconds) * 1000);
                    
                    if (delayMilliseconds > 0)
                    {
                        Task.Delay(delayMilliseconds).Wait();
                    }
                }
            }

            await Task.CompletedTask;
        }

        private void UpdateBytesTransferred(int bytes)
        {
            lock (_lock)
            {
                _totalBytesTransferred += bytes;
            }
        }

        public override void Flush()
        {
            _baseStream.Flush();
        }

        public override async Task FlushAsync(CancellationToken cancellationToken)
        {
            await _baseStream.FlushAsync(cancellationToken);
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            return _baseStream.Seek(offset, origin);
        }

        public override void SetLength(long value)
        {
            _baseStream.SetLength(value);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _stopwatch.Stop();
                
                var elapsedSeconds = _stopwatch.Elapsed.TotalSeconds;
                var speedKBps = elapsedSeconds > 0 ? (_totalBytesTransferred / 1024.0) / elapsedSeconds : 0;
                
                _logger.LogInformation(
                    "Transfer completed: {TotalBytes} bytes in {ElapsedSeconds:F2}s (avg speed: {SpeedKBps:F2} KB/s, limit: {MaxSpeedKBps} KB/s)",
                    _totalBytesTransferred,
                    elapsedSeconds,
                    speedKBps,
                    _maxBytesPerSecond / 1024);
            }
            
            base.Dispose(disposing);
        }
    }

    /// <summary>
    /// Configuration options for bandwidth limiter
    /// </summary>
    public class BandwidthLimiterOptions
    {
        /// <summary>
        /// Enable or disable bandwidth limiting
        /// </summary>
        public bool Enabled { get; set; } = true;

        /// <summary>
        /// Maximum upload speed in KB/s (0 = unlimited)
        /// </summary>
        public int MaxUploadSpeedKBps { get; set; } = 100;

        /// <summary>
        /// Maximum download speed in KB/s (0 = unlimited)
        /// </summary>
        public int MaxDownloadSpeedKBps { get; set; } = 100;

        /// <summary>
        /// Paths that should be throttled (e.g., "/api/files/")
        /// </summary>
        public List<string> TargetPaths { get; set; } = new List<string> { "/api/files/" };
    }

    /// <summary>
    /// Extension methods for registering bandwidth limiter
    /// </summary>
    public static class BandwidthLimiterExtensions
    {
        public static IApplicationBuilder UseBandwidthLimiter(
            this IApplicationBuilder builder,
            BandwidthLimiterOptions options)
        {
            return builder.UseMiddleware<BandwidthLimiterMiddleware>(options);
        }
    }
}
