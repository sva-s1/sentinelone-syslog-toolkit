#!/bin/bash

# Test script for 3-in-1 Pipeline solution
# Sends sample syslog messages to test the pipeline

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🧪 Testing 3-in-1 Pipeline Syslog Reception${NC}"
echo "=============================================="
echo ""

# Check if .env exists and load ports
if [ -f ".env" ]; then
    source .env
    UDP_PORT=${PORT1_NUMBER:-514}
    TLS_PORT=${PORT2_NUMBER:-6514}
else
    echo -e "${YELLOW}⚠️  No .env file found, using default ports${NC}"
    UDP_PORT=514
    TLS_PORT=6514
fi

echo "Testing UDP port: $UDP_PORT"
echo "Testing TLS port: $TLS_PORT"
echo ""

# Test messages
CISCO_MSG="<190>$(date '+%b %d %H:%M:%S') cisco-router %ASA-6-302013: Built inbound TCP connection 123 for outside:192.168.1.100/80 to inside:10.0.0.50/8080"
PALO_MSG="<14>$(date '+%b %d %H:%M:%S') PA-VM TRAFFIC,1,$(date '+%Y/%m/%d %H:%M:%S'),001801009999,TRAFFIC,end,2560,test"
LINUX_MSG="<134>$(date '+%b %d %H:%M:%S') ubuntu-server sshd[12345]: Accepted publickey for admin from 192.168.1.100 port 55432 ssh2"

# Function to send test message
send_test_msg() {
    local message="$1"
    local port="$2"
    local protocol="$3"
    local description="$4"
    
    echo -e "${BLUE}Testing $description...${NC}"
    
    if command -v nc >/dev/null 2>&1; then
        if [ "$protocol" = "udp" ]; then
            echo "$message" | nc -u -w 1 localhost "$port"
        else
            echo "$message" | nc -w 1 localhost "$port"
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Sent: $description${NC}"
        else
            echo -e "${RED}❌ Failed: $description${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  netcat (nc) not available, trying with logger${NC}"
        if command -v logger >/dev/null 2>&1; then
            if [ "$protocol" = "udp" ]; then
                logger -P "$port" -n 127.0.0.1 -p user.info "$message"
            else
                logger -T "$port" -n 127.0.0.1 -p user.info "$message"
            fi
            echo -e "${GREEN}✅ Sent via logger: $description${NC}"
        else
            echo -e "${RED}❌ Neither nc nor logger available${NC}"
        fi
    fi
    echo ""
}

# Send test messages
send_test_msg "$CISCO_MSG" "$UDP_PORT" "udp" "Cisco Router message via UDP"
send_test_msg "$PALO_MSG" "$UDP_PORT" "udp" "Palo Alto message via UDP"  
send_test_msg "$LINUX_MSG" "$UDP_PORT" "udp" "Linux system message via UDP"

echo -e "${CYAN}📋 Test Summary${NC}"
echo "Sent 3 test messages to UDP port $UDP_PORT"
echo ""
echo "Next steps:"
echo "1. Check docker logs: docker compose logs -f"
echo "2. Verify messages appear in SentinelOne with proper parsing"
echo "3. Look for SOURCE1_, SOURCE2_, SOURCE3_ parser assignments"
echo ""
echo -e "${YELLOW}💡 Tip: It may take 1-2 minutes for messages to appear in SentinelOne${NC}"