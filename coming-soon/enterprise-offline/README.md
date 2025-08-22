# Enterprise Offline Deployment (Coming Soon)

## Overview
A completely offline-capable deployment solution for enterprise environments without external repository access.

## Use Case
- Air-gapped environments
- Environments without access to public repositories (no EPEL, Docker Hub, etc.)
- High-security installations requiring complete dependency isolation
- Enterprise environments with strict change control

## Planned Features
- ✅ Self-contained deployment packages
- ✅ All dependencies bundled (no external repos required)
- ✅ Offline-first design
- ✅ Static binary distributions
- ✅ Enterprise-grade installation procedures
- ✅ Comprehensive offline documentation
- ✅ Custom CA certificate support

## Target Timeline
Q3 2025

## Current Status
📋 **Requirements Gathering** - Working with enterprise customers to define needs

## Architecture Considerations
- Statically linked binaries where possible
- Vendored dependencies
- Offline package repositories
- Air-gap transfer procedures
- Compliance documentation

## Get Notified
Watch this repository for updates on enterprise offline deployment availability.

---

_For current air-gapped needs, the rootless-syslog-ng solution may work with pre-pulled container images._