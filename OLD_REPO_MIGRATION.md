# Migration Notice: sva-s1/syslog → sva-s1/sentinelone-syslog-toolkit

## ⚠️ Repository Consolidated

The standalone `sva-s1/syslog` repository has been **consolidated** into the unified SentinelOne Syslog Solutions Toolkit.

### **New Location:**
🆕 **https://github.com/sva-s1/sentinelone-syslog-toolkit**

### **Container Images:**
The container images are now built from the new repository:

| Old Location | New Location | Status |
|-------------|-------------|---------|
| `ghcr.io/sva-s1/syslog:*` (from sva-s1/syslog) | `ghcr.io/sva-s1/syslog:*` (from sva-s1/sentinelone-syslog-toolkit) | ✅ **Active** |
| `ghcr.io/sva-s1/alpine-nc:*` (from sva-s1/syslog) | `ghcr.io/sva-s1/alpine-nc:*` (from sva-s1/sentinelone-syslog-toolkit) | ✅ **Active** |

### **What Changed:**
- **Same container names** - `ghcr.io/sva-s1/syslog` and `ghcr.io/sva-s1/alpine-nc`
- **New source repository** - Now part of the unified toolkit
- **Unified versioning** - Container versions align with toolkit releases
- **Multiple solutions** - Choose from 3 different syslog solutions

### **Migration Steps:**

1. **Update your deployments** to pull from the new build source:
   ```bash
   # Your docker-compose.yml or deployment configs don't need to change
   # Same image names, but now built from the unified toolkit
   docker pull ghcr.io/sva-s1/syslog:latest
   ```

2. **For new deployments**, use the unified toolkit:
   ```bash
   git clone https://github.com/sva-s1/sentinelone-syslog-toolkit.git
   cd sentinelone-syslog-toolkit
   bash setup.sh
   ```

### **Benefits of Migration:**
- ✅ **Multiple solutions** - Choose the right syslog approach for your needs
- ✅ **Unified documentation** - All solutions in one place
- ✅ **Consistent releases** - Coordinated versioning across all components
- ✅ **Better CI/CD** - Comprehensive testing and release automation

### **Timeline:**
- **Now:** New repository is active and building containers
- **Ongoing:** Old repository containers remain available but deprecated
- **Future:** Old repository will be archived with clear migration notices

---

**Questions?** Please open issues in the new repository: https://github.com/sva-s1/sentinelone-syslog-toolkit/issues