#!/bin/bash

# SentinelOne Syslog Toolkit - Connectivity Test Script
# Tests basic network connectivity to SentinelOne endpoints

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔗 SentinelOne Connectivity Test${NC}"
echo "================================="
echo ""

# Check if .env file exists in current directory
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ Found .env file${NC}"
    source .env
else
    echo -e "${YELLOW}⚠️  No .env file found in current directory${NC}"
    echo "Please run this script from a solution directory with a configured .env file"
    exit 1
fi

# Determine which endpoints to test based on available variables
ENDPOINTS_TO_TEST=()

if [ ! -z "$S1_INGEST_URL" ]; then
    ENDPOINTS_TO_TEST+=("$S1_INGEST_URL")
fi

if [ ! -z "$S1_HEC_URL" ]; then
    ENDPOINTS_TO_TEST+=("https://$S1_HEC_URL")
fi

if [ ! -z "$AISIEM_SERVER" ]; then
    ENDPOINTS_TO_TEST+=("$AISIEM_SERVER")
fi

if [ ${#ENDPOINTS_TO_TEST[@]} -eq 0 ]; then
    echo -e "${RED}❌ No SentinelOne endpoints found in .env file${NC}"
    echo "Expected variables: S1_INGEST_URL, S1_HEC_URL, or AISIEM_SERVER"
    exit 1
fi

echo "Testing connectivity to SentinelOne endpoints..."
echo ""

# Test each endpoint
for endpoint in "${ENDPOINTS_TO_TEST[@]}"; do
    echo -e "${BLUE}Testing: $endpoint${NC}"
    
    # Extract hostname for DNS resolution test
    hostname=$(echo "$endpoint" | sed 's|https\?://||' | cut -d'/' -f1)
    
    # DNS resolution test
    echo -n "  DNS resolution: "
    if nslookup "$hostname" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Success${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
        continue
    fi
    
    # Port connectivity test (HTTPS/443)
    echo -n "  Port 443 connectivity: "
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$hostname/443" 2>/dev/null; then
        echo -e "${GREEN}✅ Success${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
        continue
    fi
    
    # HTTP(S) response test
    echo -n "  HTTP response: "
    if curl -s --connect-timeout 5 --max-time 10 "$endpoint" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Success${NC}"
    else
        # Many endpoints will reject requests without proper auth, which is normal
        echo -e "${YELLOW}⚠️  No response (normal for auth-required endpoints)${NC}"
    fi
    
    echo ""
done

echo -e "${CYAN}🔍 Additional Checks${NC}"

# Check local syslog ports
echo -n "Local syslog port availability: "
if [ ! -z "$SIMPLE_UDP_PORT" ]; then
    if ss -tuln | grep -q ":$SIMPLE_UDP_PORT "; then
        echo -e "${YELLOW}⚠️  Port $SIMPLE_UDP_PORT already in use${NC}"
    else
        echo -e "${GREEN}✅ Port $SIMPLE_UDP_PORT available${NC}"
    fi
elif [ ! -z "$PORT1_NUMBER" ]; then
    if ss -tuln | grep -q ":$PORT1_NUMBER "; then
        echo -e "${YELLOW}⚠️  Port $PORT1_NUMBER already in use${NC}"
    else
        echo -e "${GREEN}✅ Port $PORT1_NUMBER available${NC}"
    fi
elif [ ! -z "$ROOTLESS_PORT" ]; then
    if ss -tuln | grep -q ":$ROOTLESS_PORT "; then
        echo -e "${YELLOW}⚠️  Port $ROOTLESS_PORT already in use${NC}"
    else
        echo -e "${GREEN}✅ Port $ROOTLESS_PORT available${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No port configuration found${NC}"
fi

# Check Docker
echo -n "Docker availability: "
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker running${NC}"
    else
        echo -e "${RED}❌ Docker not running${NC}"
    fi
else
    echo -e "${RED}❌ Docker not installed${NC}"
fi

# Check Docker Compose
echo -n "Docker Compose availability: "
if docker compose version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker Compose available${NC}"
elif docker-compose --version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker Compose (legacy) available${NC}"
else
    echo -e "${RED}❌ Docker Compose not available${NC}"
fi

echo ""
echo -e "${CYAN}📋 Summary${NC}"
echo "Connectivity test complete. Review any failed tests above."
echo "For issues, check:"
echo "1. Network firewall rules"
echo "2. Corporate proxy settings"
echo "3. DNS configuration"
echo "4. SentinelOne tenant URL correctness"