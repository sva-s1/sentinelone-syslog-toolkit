# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.6] - 2025-08-15

### Added
- **Dual deployment modes**: Development/testing mode using registry images and Production mode with local builds
- **Automated rootless testing pipeline**: GitHub Actions workflow validates rootless Docker compatibility
- **AppArmor configuration**: Automatic setup for rootless Docker in GitHub Actions
- **Production override**: `docker-compose.dev.yml` for customization workflows
- **Enhanced CI/CD testing**: Comprehensive testing for security, functionality, and builds
- **Rootless troubleshooting guide**: Added `ROOTLESS_FIXES.md` documentation

### Changed
- **Development deployment**: Default docker-compose now pulls tested images from registry
- **Production workflow**: Live configuration mounting for easier customization
- **Documentation**: Updated README with clear production vs development guidance
- **Project structure**: Reorganized with proper GitHub Actions workflows
- **Container logs command**: Updated from `syslog-bridge` to `syslog` service name

### Fixed
- **Rootless container testing**: Fixed user ID detection and permission validation
- **GitHub Actions compatibility**: Resolved AppArmor restrictions for rootless Docker
- **Test reliability**: Improved container process detection without relying on `pgrep`
- **File permissions**: Enhanced ownership validation for rootless deployments

### Security
- **Rootless validation**: Automated testing ensures containers never run as root
- **Capability restrictions**: Tests verify minimal required capabilities
- **Permission isolation**: Validates proper file ownership in rootless mode

## [1.0.0] - 2025-08-04

### Added
- Initial production-ready release of Syslog to SentinelOne SDL HEC Bridge
- Support for Linux/Unix system logs with enhanced metadata
- Support for FortiGate firewall logs with comprehensive security context
- Support for ZScaler proxy logs with web security event details
- Rootless container implementation for improved security
- Environment-based configuration via .env file
- Comprehensive documentation and examples

### Changed
- Updated syslog-ng configuration with optimized performance settings
- Improved log matching patterns for better accuracy
- Enhanced error handling and logging
- Optimized Docker build and runtime configuration

### Fixed
- Resolved permission issues in container startup
- Fixed environment variable handling in syslog-ng configuration
- Improved log message formatting and metadata enrichment

## [0.1.0] - 2025-08-01

### Added
- Initial project setup and basic configuration
- Support for receiving syslog messages over UDP
- Basic forwarding to SentinelOne SDL HEC endpoint
- Docker and docker-compose configuration
