# Environment Variable Standards

This document defines the standardized environment variable naming across all solutions in the SentinelOne Syslog Toolkit.

## Core SentinelOne Variables

### Write Token (Required for all solutions)
- **Standard Name:** `S1_WRITE_TOKEN`
- **Description:** SentinelOne write token for data ingestion
- **Scope:** Supports both addEvents API and HEC API  
- **Usage:** All solutions use this for authentication
- **Replaces:** `S1_API_TOKEN`, `S1_HEC_WRITE_TOKEN`, `AISIEM_LOGACCESS_WRITE_TOKEN`

### Ingest URL (Required for all solutions)  
- **Standard Name:** `S1_INGEST_URL`
- **Description:** SentinelOne ingest endpoint URL
- **Format:** `https://xdr.us1.sentinelone.net` or `https://ingest.us1.sentinelone.net` (HEC only)
- **Usage:** Target endpoint for log forwarding

## Solution-Specific Variables

### Simple Collector
- `SIMPLE_UDP_PORT=514` - UDP syslog port
- `SIMPLE_TCP_PORT=601` - TCP syslog port  
- `SIMPLE_PARSER=marketplace-paloaltonetworksfirewall-latest` - Default parser

### 3-in-1 Pipeline
- `PORT1_PROTOCOL=udp` - First port protocol
- `PORT1_NUMBER=514` - First port number
- `PORT2_PROTOCOL=tls` - Second port protocol (TLS)
- `PORT2_NUMBER=6514` - Second port number
- `SOURCE1_NAME=cisco-router` - Source identifier
- `SOURCE1_PARSER=ciscoRouter1` - Parser for source
- `SOURCE1_MATCHER=router*` - Content matching pattern

### Rootless Syslog-NG
- `ROOTLESS_PORT=5514` - Syslog listening port (rootless-friendly)
- `USER_ID=1000` - Container user ID
- `GROUP_ID=1000` - Container group ID

## Backward Compatibility

The following legacy variables are automatically mapped for backward compatibility:

### Legacy Mappings
```bash
# Legacy → Standard (automatically mapped in .env files)
AISIEM_LOGACCESS_WRITE_TOKEN → S1_WRITE_TOKEN
AISIEM_SERVER → S1_INGEST_URL
S1_API_TOKEN → S1_WRITE_TOKEN
S1_HEC_WRITE_TOKEN → S1_WRITE_TOKEN
S1_HEC_URL → S1_INGEST_URL
```

### GitHub Secrets
For GitHub Actions workflows:
- `REPO_TOKEN` - GitHub repository token for container registry access
- `S1_WRITE_TOKEN` - SentinelOne write token (for testing)

## Migration Guide

When updating from older versions:

1. **Update .env files** to use `S1_WRITE_TOKEN` and `S1_INGEST_URL`
2. **Remove legacy variables** (they'll still work but are deprecated)
3. **Test configuration** with new variable names

## API Endpoint Compatibility

Both standard variables work with all SentinelOne APIs:

- **addEvents API** (Simple Collector, 3-in-1 Pipeline)
  - Uses: `S1_WRITE_TOKEN` + `S1_INGEST_URL`
  - Format: `https://xdr.region.sentinelone.net`

- **HEC API** (Rootless Syslog-NG)
  - Uses: `S1_WRITE_TOKEN` + `S1_INGEST_URL` 
  - Format: `https://ingest.region.sentinelone.net`

This standardization simplifies configuration while maintaining full backward compatibility.
