# Bandwidth Limiter for File Uploads and Downloads

## Overview
This API implements bandwidth limiting for file upload and download operations to control network usage and simulate real-world network conditions during testing.

## Configuration

The bandwidth limiter is configured in `appsettings.json`:

```json
{
  "BandwidthLimiter": {
    "Enabled": true,
    "MaxUploadSpeedKBps": 100,
    "MaxDownloadSpeedKBps": 100,
    "TargetPaths": [ "/api/files/" ]
  }
}
```

### Configuration Options

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `Enabled` | boolean | Enable or disable bandwidth limiting | `true` |
| `MaxUploadSpeedKBps` | integer | Maximum upload speed in KB/s (0 = unlimited) | `100` |
| `MaxDownloadSpeedKBps` | integer | Maximum download speed in KB/s (0 = unlimited) | `100` |
| `TargetPaths` | string[] | API paths to apply bandwidth limiting | `["/api/files/"]` |

## How It Works

1. **Request Interception**: The middleware intercepts HTTP requests matching the configured target paths
2. **Stream Wrapping**: For uploads (POST/PUT), it wraps the request body stream; for downloads (GET), it wraps the response body stream
3. **Throttling**: The `ThrottledStream` class monitors data transfer and introduces delays to maintain the configured speed limit
4. **Logging**: Transfer statistics are logged when each transfer completes

## Usage Examples

### Testing with Different Speeds

**Slow Connection (50 KB/s)**
```json
{
  "BandwidthLimiter": {
    "Enabled": true,
    "MaxUploadSpeedKBps": 50,
    "MaxDownloadSpeedKBps": 50
  }
}
```

**Medium Connection (100 KB/s)**
```json
{
  "BandwidthLimiter": {
    "Enabled": true,
    "MaxUploadSpeedKBps": 100,
    "MaxDownloadSpeedKBps": 100
  }
}
```

**Fast Connection (500 KB/s)**
```json
{
  "BandwidthLimiter": {
    "Enabled": true,
    "MaxUploadSpeedKBps": 500,
    "MaxDownloadSpeedKBps": 500
  }
}
```

**Unlimited (Disabled)**
```json
{
  "BandwidthLimiter": {
    "Enabled": false
  }
}
```

Or set speeds to 0:
```json
{
  "BandwidthLimiter": {
    "Enabled": true,
    "MaxUploadSpeedKBps": 0,
    "MaxDownloadSpeedKBps": 0
  }
}
```

### Environment-Specific Settings

You can have different settings for different environments:

**appsettings.Development.json** (Slower for testing)
```json
{
  "BandwidthLimiter": {
    "Enabled": true,
    "MaxUploadSpeedKBps": 50,
    "MaxDownloadSpeedKBps": 50
  }
}
```

**appsettings.Production.json** (Faster for production)
```json
{
  "BandwidthLimiter": {
    "Enabled": true,
    "MaxUploadSpeedKBps": 200,
    "MaxDownloadSpeedKBps": 200
  }
}
```

## Monitoring

The bandwidth limiter logs transfer statistics when each operation completes:

```
Transfer completed: 1048576 bytes in 10.24s (avg speed: 100.00 KB/s, limit: 100 KB/s)
```

This helps you verify that the bandwidth limiting is working correctly.

## Testing the Bandwidth Limiter

### 1. Upload a File
```bash
curl -X POST "http://localhost:5000/api/files/upload" \
  -F "file=@large_file.mp4" \
  -F "messageType=video" \
  -w "\nTime: %{time_total}s\n"
```

### 2. Download a File
```bash
curl -X GET "http://localhost:5000/api/files/download?filePath=uploads/video/filename.mp4" \
  -o downloaded_file.mp4 \
  -w "\nTime: %{time_total}s\n"
```

### 3. Expected Transfer Time Calculation
For a 5MB file with 100 KB/s limit:
- File size: 5,120 KB
- Expected time: 5,120 KB ÷ 100 KB/s = ~51.2 seconds

## Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────┐
│  BandwidthLimiterMiddleware │
│                             │
│  - Checks if enabled        │
│  - Matches target paths     │
│  - Wraps streams            │
└──────────┬──────────────────┘
           │
           ▼
    ┌──────────────┐
    │ThrottledStream│
    │              │
    │ - Monitors   │
    │ - Throttles  │
    │ - Logs stats │
    └──────┬───────┘
           │
           ▼
    ┌─────────────┐
    │FilesController│
    └─────────────┘
```

## Business Use Cases

1. **Network Simulation**: Test how your mobile app handles slow network conditions
2. **Bandwidth Control**: Limit bandwidth usage in production environments
3. **Fair Usage**: Prevent individual users from consuming excessive bandwidth
4. **Cost Management**: Control data transfer costs in cloud environments
5. **Testing**: Validate upload/download progress indicators and timeout handling

## Troubleshooting

### Bandwidth Limiting Not Working
1. Check that `Enabled` is set to `true`
2. Verify the request path matches one of the `TargetPaths`
3. Check logs for bandwidth limiter messages
4. Ensure speeds are not set to 0 (which means unlimited)

### Transfers Too Slow
- Increase `MaxUploadSpeedKBps` or `MaxDownloadSpeedKBps`
- Consider disabling for specific environments

### Need Different Speeds for Upload vs Download
- Set `MaxUploadSpeedKBps` and `MaxDownloadSpeedKBps` independently
- Common pattern: Allow faster uploads than downloads, or vice versa

## Notes

- The bandwidth limiter applies per-connection, not globally
- Multiple simultaneous transfers will each respect the speed limit independently
- Very small files may not show noticeable throttling
- The actual speed may vary slightly due to buffering and OS-level optimizations
