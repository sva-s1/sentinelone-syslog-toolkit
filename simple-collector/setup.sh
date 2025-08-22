#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 Simple Collector Setup${NC}"
echo "=========================="
echo ""
echo "This solution provides basic multi-port syslog collection with official S1 support."
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
echo "1. S1_API_TOKEN - Your SentinelOne API token"
echo "2. S1_INGEST_URL - Your SentinelOne ingest URL (e.g., https://xdr.us1.sentinelone.net)"
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
echo "Start the collector:"
echo "  docker compose up -d"
echo ""
echo "Check status:"
echo "  docker compose ps"
echo ""
echo "View logs:"
echo "  docker compose logs -f"
echo ""
echo "Stop the collector:"
echo "  docker compose down"
echo ""

# Check if agent.json exists, if not copy from example
if [ ! -f "agent.json" ]; then
    if [ -f "example-agent.json" ]; then
        echo -e "${YELLOW}📝 Creating agent.json from template...${NC}"
        cp example-agent.json agent.json
        echo -e "${GREEN}✅ agent.json created${NC}"
        echo -e "${YELLOW}💡 Review agent.json to configure parsers for your log sources${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 Simple Collector setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Edit .env with your S1 credentials"
echo "2. Review agent.json for parser configuration" 
echo "3. Run: docker compose up -d"
echo "4. Test with: logger -P 514 -n 127.0.0.1 'Test message'"