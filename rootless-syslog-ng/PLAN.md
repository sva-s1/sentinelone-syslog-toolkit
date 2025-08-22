# Syslog to SentinelOne SDL HEC Bridge - Development Plan

## Project Overview
A production-ready, containerized service that receives traditional syslog messages from various on-premise sources and forwards them to the SentinelOne Singularity Data Lake (SDL) using the HTTP Event Collector (HEC) API.

## Version 1.0 - Production Ready

### Core Features
- [x] Rootless container implementation (UID/GID 1000)
- [x] End-to-end HEC forwarding to SentinelOne SDL
- [x] Dynamic parser assignment with source matching
- [x] FortiGate firewall log support with comprehensive metadata
- [x] ZScaler proxy log support with comprehensive metadata
- [x] Linux/Unix system log support with security categorization
- [x] UDP port 5514 for rootless operation
- [x] Production-ready architecture with batching, compression, retries
- [x] Sample log files and testing framework
- [x] Comprehensive documentation and README

### Technical Architecture
- **Core Engine:** syslog-ng 4.9.0 for high-performance log processing
- **Target Endpoint:** `/services/collector/raw` HEC endpoint
- **Parser Assignment:** Dynamic assignment via sourcetype parameter
- **Containerization:** Docker with non-root user (1000:1000)
- **Configuration:** Environment-based via .env file
- **Security:** Rootless container, no privileged ports required

### Supported Log Sources
1. **Linux/Unix Systems** → `linuxSyslog` parser
2. **FortiGate Firewall** → `fortiGate` parser
3. **ZScaler Proxy** → `zscaler` parser

## Implementation Details

### Configuration
- Environment variables for all sensitive configuration
- Custom entrypoint for dynamic user/group creation
- syslog-ng configuration with optimized batching and retries

### Metadata Enrichment
- Source-specific metadata fields for each log type
- Standardized fields including:
  - `dataSource.category`, `dataSource.vendor`, `dataSource.name`
  - `metadata.version`, `metadata.product.vendor_name`, `metadata.product.name`
  - `severity_id`, `category_uid`, `category_name`

## Testing Strategy
1. **Local Testing:**
   - Send test messages to UDP port 5514
   - Verify reception in container logs
2. **Remote Verification:**
   - Query SentinelOne API to confirm log ingestion
   - Verify correct parser assignment via `sourcetype`

## Future Enhancements
- Add support for additional log sources
- Implement configurable log filtering and transformation
- Add Prometheus metrics endpoint
- Create Kubernetes deployment manifests
- Implement log rotation and retention policies

---
*Last Updated: 2025-08-04 - Production Release*
