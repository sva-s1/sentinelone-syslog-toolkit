<img src="assets/logo-syslog.png"
     alt="syslog-ng" height="125">

# Syslog [ROOTLESS](https://docs.docker.com/engine/security/rootless/) to SentinelOne SDL HEC Bridge

[![SentinelOne](https://img.shields.io/badge/SentinelOne-663399?style=for-the-badge&logo=sentinelone&logoColor=white)](https://www.sentinelone.com/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![syslog-ng](https://img.shields.io/badge/SYSLOG_NG-4.9.0-51aad6?style=for-the-badge)](https://www.syslog-ng.com/)
[![License](https://img.shields.io/badge/License-MIT-932218.svg?style=for-the-badge)](LICENSE)
[![Syslog](https://img.shields.io/badge/Syslog-RFC3164%20%26%20RFC5424-f6c444?style=for-the-badge)](https://tools.ietf.org/html/rfc5424)

**Version:** [1.1.6](VERSION) | **Status:** TESTING | **Last Updated:** 2025-08-15 | **Docker Image:** [ghcr.io/sva-s1/syslog](https://github.com/sva-s1/syslog/pkgs/container/syslog) 

## Overview

A pre-production-ready, containerized service that receives traditional syslog messages from various appliances/virtual-appliances/apps syslog sources and forwards them to the SentinelOne Singularity Data Lake (SDL) using the HTTP Event Collector (HEC) API. The service is designed for security operations, providing rich metadata and context for security analytics.

> [!IMPORTANT]
> This collector uses SentinelOne's [HEC API](https://community.sentinelone.com/s/article/000008671) to ingest syslog data directly into your SIEM for real-time threat detection and analysis.

## 🎯 Use Cases & When to Use This Project

**Need to differentiate multiple syslog sources on the same incoming port?** That's this project! 🎉

This is a fork of the [upstream syslog-ng container image](https://hub.docker.com/layers/balabit/syslog-ng/4.9.0/images/sha256-bcb714a35a38aec5461cf80481119dde10b7e22550d60b2ccc2e4ebb22982d6b) designed to be easier, faster to deploy, scalable, and rootless ready.

> [!TIP]
> ⭐ **STAR this repo** if you find it useful!

## Key Features

- **High-Performance Log Processing**

  - Built on **syslog-ng** with optimized configuration
  - Multi-threaded processing for high throughput
  - Batching and compression for efficient network usage

- **Comprehensive Log Source Support**

  - Linux/Unix system logs with security context
  - FortiGate firewall logs with security event details
  - ZScaler proxy logs with web security events

- **Enterprise-Grade Deployment**

  - Rootless container for enhanced security
  - Environment-based configuration
  - Health checks and monitoring
  - Resource constraints and limits

- **Reliable Delivery**
  - Automatic retries on failure
  - Connection pooling and keepalive
  - Configurable timeouts and batch sizes

## Architecture

```
┌─────────────────┐    ┌───────────────────────┐    ┌───────────────────────┐
│                 │    │                       │    │                       │
│  Syslog         │───▶│  syslog-ng Container  │───▶│  SentinelOne SDL      │
│  Sources        │    │  (UDP/5514)           │    │  HEC API              │
│                 │    │                       │    │                       │
└─────────────────┘    └───────────────────────┘    └───────────────────────┘
        ▲                                                       ▲
        │                                                       │
        └───────────────────────────────────────────────────────┘
              Configuration via .env & syslog-ng.conf.tmpl
```

### Example Log Sources

| Source Type                 | Parser Assignment                          | Example Matchers                                              |
| --------------------------- | ------------------------------------------ | ------------------------------------------------------------- |
| **Linux/Unix Systems**      | `linuxSyslog`                              | `sshd`, `systemd`, `kernel`, `cron`, `authpriv`               |
| **FortiGate Firewall**      | `marketplace-fortinetfortigate-latest`     | `devname="FortiGate"`, `type="traffic"`, `logid="0000000013"` |
| **ZScaler Internet Access** | `marketplace-zscalerinternetaccess-latest` | `product="NSS"`, `vendor="Zscaler"`, `action="Allow"`         |

## 📋 Prerequisites

> [!WARNING]
> Do not install Docker from your distribution repository as they can be outdated.

- **Docker Engine** - [Install Docker Engine](https://docs.docker.com/engine/install/)
- **Docker Compose** - [Install Docker Compose](https://docs.docker.com/compose/)
- **SentinelOne AI-SIEM** with [API access](https://community.sentinelone.com/s/article/000006771)

## 🚀 Quick Setup

### Development/Testing Deployment (Quick Start)

For development and testing with the default, pre-built syslog configuration:

1. **Clone and configure:**

   ```bash
   git clone https://github.com/sva-s1/syslog.git
   cd syslog
   cp .env.example .env
   # Edit .env with your SentinelOne token(s)
   ```

2. **Start with pre-built image:**

   ```bash
   docker compose up -d
   ```

### Production Deployment (Recommended)

For production use with customized syslog-ng configuration:

1. **Edit the configuration template:**

   ```bash
   # Modify syslog-ng.conf.tmpl for your specific log sources
   vim syslog-ng.conf.tmpl
   ```

2. **Build and start with production override:**

   ```bash
   # Uses local build + custom config mounting
   docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
   ```

3. **Test syslog reception:**

   To test that the service is receiving logs, you can send sample messages to the exposed UDP port. The following commands use a temporary `alpine-nc` container to send the data, ensuring the tool is available.

   ```bash
   # Test with a sample Linux log
   echo "<134>$(date '+%b %d %H:%M:%S') ubuntu-server sshd[12345]: Accepted publickey for admin" | \
     docker run -i --rm --network host ghcr.io/sva-s1/alpine-nc:latest \
     /bin/ash -c "nc -u -w 1 127.0.0.1 5514"

   # Test with the sample FortiGate log
   cat samples/fortigate-sample.log | \
     docker run -i --rm --network host ghcr.io/sva-s1/alpine-nc:latest \
     /bin/ash -c "nc -u -w 1 127.0.0.1 5514"

   # Test with the sample ZScaler log
   cat samples/zscaler-sample.log | \
     docker run -i --rm --network host ghcr.io/sva-s1/alpine-nc:latest \
     /bin/ash -c "nc -u -w 1 127.0.0.1 5514"
   ```

4. **View logs:**
   ```bash
   docker compose logs -f syslog
   ```

## Configuration

All configuration is managed through the `.env` and `syslog-ng.conf.tmpl` files. At container startup, the `entrypoint.sh` script substitutes variables from this file into the `syslog-ng.conf.tmpl` to generate the final `syslog-ng.conf`.

**Note:** Only variables explicitly handled by the `entrypoint.sh` script (e.g., `$S1_INGEST_URL`, `$S1_WRITE_TOKEN`) are substituted. This prevents accidental modification of internal syslog-ng variables.

The primary variables are:

```bash
# SentinelOne Configuration
S1_WRITE_TOKEN=your_write_token_here
S1_READ_TOKEN=your_read_token_here # <- Optional to TEST via API query
S1_INGEST_URL=https://ingest.us1.sentinelone.net  # MUST include https://

# Syslog Configuration
PORT1_PROTOCOL=udp
PORT1_NUMBER=5514
PORT1_TYPE=rfc3164
USER_ID=1000
GROUP_ID=1000
```

## Development

### Project Structure

```
.
├── .github/
│   └── workflows/          # GitHub Actions CI/CD pipelines
│       ├── build-alpine-nc.yml
│       ├── build-syslog.yml
│       ├── test-project.yml
│       └── test-rootless.yml
├── Dockerfiles/
│   ├── alpine-nc/
│   │   └── Dockerfile      # Alpine netcat utility container
│   └── syslog-ng-rootless/
│       └── Dockerfile      # Main syslog-ng rootless container
├── LOCAL-ONLY/
│   └── llm_status.sh       # Local development scripts
├── assets/
│   └── logo-syslog.png     # Project logo
├── samples/                # Sample log files for testing
│   ├── fortigate-sample.log
│   ├── linux-sample.log
│   └── zscaler-sample.log
├── CHANGELOG.md            # Project changes and version history
├── LICENSE                 # MIT license
├── PLAN.md                 # Development roadmap
├── README.md               # This file
├── ROOTLESS_FIXES.md       # Rootless Docker troubleshooting
├── VERSION                 # Current project version
├── docker-compose.yml      # Development/testing service orchestration
├── docker-compose.dev.yml  # Production override (build + mount config)
├── entrypoint.sh           # Container entrypoint script
├── syslog-ng.conf.tmpl     # syslog-ng configuration template
├── syslog-ng-test.conf     # Test configuration
├── .env                    # Environment variables (not in repo)
├── .env.example            # Environment template
└── .gitignore              # Git exclusions
```

### Testing

**Automated Testing:**

This project includes automated testing pipelines via GitHub Actions:

- **Rootless Compatibility Testing** - Validates that containers run properly in rootless mode without requiring privileged access
- **Functional Testing** - Tests log processing with sample data from FortiGate, ZScaler, and Linux systems
- **Build Testing** - Automatically builds and publishes container images

**Local Testing:**

- Send test messages to UDP port `5514`
- Verify reception in container logs

**Remote Verification:**

- Query SentinelOne API to confirm log ingestion
- Verify correct parser assignment via `sourcetype`

## Version History

### v1.1.6 (2025-08-15) - Production Ready

- ✅ **Dual deployment modes**: Production (registry image) and Development (local build)
- ✅ **Automated rootless testing**: GitHub Actions pipeline validates rootless Docker compatibility
- ✅ **Enhanced CI/CD**: Automated testing for functionality, builds, and security
- ✅ **Improved documentation**: Clear separation of production vs development workflows
- ✅ **Security validation**: Tests ensure containers run without privileged access

### v1.0 (2025-08-04) - QA Ready

- ✅ Complete rootless container implementation (UID/GID 1000)
- ✅ End-to-end HEC forwarding to SentinelOne SDL verified
- ✅ Dynamic parser assignment with source matching
- ✅ FortiGate firewall log support with comprehensive metadata
- ✅ ZScaler proxy log support with comprehensive metadata
- ✅ Linux/Unix system log support with security categorization
- ✅ UDP port 5514 for rootless operation
- ✅ Production-ready architecture with batching, compression, retries
- ✅ Sample log files and testing framework
- ✅ Comprehensive documentation and README

### Previous Versions

#### v0.1 (2025-08-01)

- ✅ Initial project structure and basic syslog-ng configuration
- ✅ Docker containerization foundation
- ✅ Environment-based configuration framework

## Roadmap

- **TLS Encryption:** Support for TLS-encrypted syslog forwarding using self-hosted or bring-your-own certificates (CA).
- **UUID Event Tracking:** Inject unique UUID with each test event for easier tracking and correlation in SentinelOne SDL.
- **Additional Log Sources:** Integration with other common security appliances and applications.

## Support

For issues and questions, please refer to the project documentation or create an issue in the repository.

---

_Built with ❤️ for secure, scalable 🪵 forwarding_
