#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}⚡ Rootless Syslog-NG Setup${NC}"
echo "============================"
echo ""
echo "This solution provides high-performance, security-focused log collection."
echo "Uses 1 rootless container with HEC API for maximum throughput."
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}📝 Creating .env file from template...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ .env file created${NC}"
    else
        echo -e "${RED}❌ .env.example not found${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

echo ""
echo -e "${YELLOW}🔧 Configuration Required${NC}"
echo "Please edit the .env file with your SentinelOne details:"
echo ""
echo "1. S1_WRITE_TOKEN - Your SentinelOne write token"
echo "2. S1_INGEST_URL - Your SentinelOne ingest URL"
echo "3. USER_ID/GROUP_ID - For rootless operation (usually 1000)"
echo ""

read -r -p "Open .env file for editing now? (y/n): " edit_env

if [[ $edit_env =~ ^[Yy]$ ]]; then
    if command -v nano &> /dev/null; then
        nano .env
    elif command -v vim &> /dev/null; then
        vim .env
    else
        echo -e "${YELLOW}⚠️  Please edit .env manually with your preferred editor${NC}"
    fi
fi

echo ""
echo -e "${BLUE}🐳 Docker Commands${NC}"
echo "Once your .env is configured:"
echo ""
echo "Development mode (build locally + mount config):"
echo "  docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d"
echo ""
echo "Production mode (use pre-built image):"
echo "  docker compose up -d"
echo ""
echo "Check status:"
echo "  docker compose ps"
echo ""
echo "View logs:"
echo "  docker compose logs -f"
echo ""
echo "Test syslog reception:"
echo "  echo '<134>Test message' | docker run -i --rm --network host ghcr.io/sva-s1/alpine-nc:latest /bin/ash -c 'nc -u -w 1 127.0.0.1 5514'"
echo ""
echo "Stop the service:"
echo "  docker compose down"
echo ""

echo -e "${GREEN}🎉 Rootless Syslog-NG setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Edit .env with your S1 HEC credentials"
echo "2. Choose deployment mode (development vs production)"
echo "3. Run: docker compose up -d (or with -f flags for dev mode)"
echo "4. Test log ingestion with the test command above"
echo ""
echo -e "${CYAN}💡 Tips:${NC}"
echo "- This solution offers the highest throughput via HEC API"
echo "- Runs rootless for enhanced security"
echo "- Single container keeps it simple"
echo "- Community supported (not officially supported by S1)"