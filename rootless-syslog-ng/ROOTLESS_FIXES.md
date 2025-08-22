# Rootless Syslog-ng Fixes

## Summary of Changes

### 1. **Dockerfile Updates**
- Changed from hardcoded user `911:911` to `1000:1000` (standard non-root user)
- Added proper directory creation and ownership for all required paths:
  - `/var/lib/syslog-ng` (for persistent state files)
  - `/var/log/syslog-ng` (for log files)
  - `/var/run/syslog-ng` (for runtime files)
  - `/etc/syslog-ng` (for configuration files)
- Used `--chown=1000:1000` when copying the config template to ensure proper ownership
- Set proper permissions (755) on all directories

### 2. **Docker Compose Updates**
- Made the user configurable via environment variables: `${USER_ID:-1000}:${GROUP_ID:-1000}`
- Added support for .env values for ports and protocols
- Properly mapped all environment variables from .env file

### 3. **Simplified Entrypoint**
- Kept the entrypoint script minimal as requested
- Only performs essential tasks:
  - Environment variable substitution
  - Config validation
  - Execution of syslog-ng

## Environment Variables Now Supported

From your .env file:
- `USER_ID` and `GROUP_ID` - For rootless operation
- `S1_INGEST_URL` - SentinelOne ingest endpoint (with https://)
- `S1_WRITE_TOKEN` - Authentication token
- `SYSLOG_PORT` - Configurable port setting

## Remaining Warning

The SO_RCVBUF warning is not a critical issue but indicates that the kernel buffer size is smaller than requested. This can be addressed by:
1. Adjusting kernel parameters on the host (requires root)
2. Or reducing the buffer size in syslog-ng.conf.tmpl from 1048576 to a smaller value

## Testing

To test that syslog messages are being received:
```bash
# Send a test message to the syslog server
echo "<14>Test message from rootless syslog-ng" | nc -u localhost 5514
```

Then check the logs:
```bash
docker compose logs -f
```

You should see the test message appear in the stdout destination.
