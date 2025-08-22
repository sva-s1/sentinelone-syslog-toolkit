# SentinelOne Syslog Toolkit Architecture

## Overview

This toolkit provides three distinct approaches to syslog collection and forwarding to SentinelOne SDL, each optimized for different use cases and environments.

## Solution Architectures

### 1. Simple Collector

```
┌─────────────────┐    ┌───────────────────────┐    ┌──────────────────┐
│  Syslog Sources │    │   Simple Collector    │    │  SentinelOne     │
│                 │───▶│   (1 Container)       │───▶│  SDL             │
│  Port-based     │    │   S1 Agent + Syslog   │    │  addEvents API   │
│  differentiation│    │   UDP:514, TCP:601    │    │                  │
└─────────────────┘    └───────────────────────┘    └──────────────────┘
```

**Use Case:** Basic multi-port syslog collection
- **Complexity:** Low
- **Containers:** 1 (scalyr/scalyr-agent-docker-json)
- **API:** addEvents
- **Differentiation:** Port-based
- **Support:** Official S1

### 2. 3-in-1 Pipeline

```
┌─────────────────┐    ┌─────────────────────────────────────────────┐    ┌──────────────────┐
│  Syslog Sources │    │             3-in-1 Pipeline                 │    │  SentinelOne     │
│                 │    │  ┌─────────────┐  ┌─────────────┐  ┌───────┐ │    │  SDL             │
│  Content-based  │───▶│  │ syslog-ng   │─▶│config-gen   │─▶│S1     │ │───▶│  addEvents API   │
│  differentiation│    │  │             │  │             │  │Agent  │ │    │                  │
│                 │    │  │ UDP:514     │  │ /tmp files  │  │       │ │    │                  │
│                 │    │  │ TLS:6514    │  │             │  │       │ │    │                  │
└─────────────────┘    └─────────────────────────────────────────────┘    └──────────────────┘
```

**Use Case:** Advanced content-based log routing
- **Complexity:** High
- **Containers:** 3 (syslog-ng + config-generator + scalyr-agent)
- **API:** addEvents (via S1 Agent)
- **Differentiation:** Content-based via regex
- **Support:** Official S1

### 3. Rootless Syslog-NG

```
┌─────────────────┐    ┌───────────────────────┐    ┌──────────────────┐
│  Syslog Sources │    │  Rootless Syslog-NG   │    │  SentinelOne     │
│                 │───▶│  (1 Container)        │───▶│  SDL             │
│  Content-based  │    │  Custom syslog-ng     │    │  HEC API         │
│  differentiation│    │  UDP:5514             │    │  (High throughput)│
└─────────────────┘    └───────────────────────┘    └──────────────────┘
```

**Use Case:** High-performance, security-focused
- **Complexity:** Medium  
- **Containers:** 1 (custom rootless syslog-ng)
- **API:** HEC (HTTP Event Collector)
- **Differentiation:** Content-based via syslog-ng
- **Support:** Community

## API Comparison

### addEvents API
- **Used by:** Simple Collector, 3-in-1 Pipeline
- **Authentication:** API Token
- **Format:** JSON structured events
- **Throughput:** Standard
- **Batching:** Automatic via S1 Agent
- **Support:** Official S1

### HEC API  
- **Used by:** Rootless Syslog-NG
- **Authentication:** HEC Token
- **Format:** Raw log events with metadata
- **Throughput:** Higher than addEvents
- **Batching:** Custom implementation
- **Support:** Community

## Network Flow Diagrams

### Simple Collector
```
Internet/LAN Sources ──UDP:514──┐
                                ├─▶ Docker Container ──HTTPS──▶ SDL
Network Appliances ──TCP:601────┘
```

### 3-in-1 Pipeline
```
Internet/LAN Sources ──UDP:514──┐
                                ├─▶ syslog-ng ──files──▶ config-gen ──files──▶ S1-Agent ──HTTPS──▶ SDL
Network Appliances ──TLS:6514───┘
```

### Rootless Syslog-NG
```
Internet/LAN Sources ──UDP:5514──▶ syslog-ng Container ──HTTPS/HEC──▶ SDL
```

## Decision Matrix

| Requirement | Simple | 3-in-1 | Rootless |
|-------------|--------|---------|----------|
| **Port differentiation** | ✅ Best | ✅ Good | ✅ Good |
| **Content differentiation** | ❌ None | ✅ Best | ✅ Good |
| **Official S1 support** | ✅ Yes | ✅ Yes | ❌ No |
| **Container security** | ⚠️ Standard | ⚠️ Standard | ✅ Rootless |
| **Setup complexity** | ✅ Low | ❌ High | ⚠️ Medium |
| **Throughput** | ⚠️ Medium | ⚠️ Medium | ✅ High |
| **Resource usage** | ✅ Low | ❌ High | ✅ Low |
| **SSL/TLS support** | ❌ No | ✅ Yes | ⚠️ Future |

## Security Considerations

### Simple Collector
- Runs as root in container
- Single point of failure
- Official S1 security model

### 3-in-1 Pipeline  
- Multiple containers increase attack surface
- Complex inter-container communication
- Official S1 security model

### Rootless Syslog-NG
- Runs as non-root user (UID/GID 1000)
- Minimal attack surface
- Enhanced container security
- Community security model

## Performance Characteristics

### Throughput Comparison
1. **Rootless Syslog-NG:** ~10,000+ EPS (HEC API)
2. **Simple Collector:** ~5,000+ EPS (addEvents API)
3. **3-in-1 Pipeline:** ~5,000+ EPS (addEvents API, overhead from 3 containers)

### Resource Usage
1. **Simple Collector:** ~256MB RAM, 0.5 CPU
2. **Rootless Syslog-NG:** ~128MB RAM, 0.3 CPU  
3. **3-in-1 Pipeline:** ~512MB RAM, 1.0 CPU (3 containers)

*Performance numbers are approximate and depend on log volume, complexity, and hardware.*

## Future Architecture

### Planned Enhancements
- **Native Linux:** Direct systemd integration, no containers
- **Enterprise Offline:** Air-gapped deployment with bundled dependencies
- **TLS Enhancement:** Certificate management for rootless solution
- **Multi-tenant:** Support for multiple S1 tenants from single deployment

---

_This architecture overview helps you understand the trade-offs between solutions and choose the right one for your environment._