#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔧 3-in-1 Pipeline Setup${NC}"
echo "========================="
echo ""
echo "This solution provides advanced content-based log routing with official S1 support."
echo "Uses 3 containers: config-generator, syslog-ng, and scalyr-agent."
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

# Check for SSL certificates
echo ""
echo -e "${YELLOW}🔒 SSL Certificate Check${NC}"
if [ ! -f "syslog.crt" ] || [ ! -f "syslog.key" ]; then
    echo -e "${YELLOW}⚠️  SSL certificates not found${NC}"
    echo ""
    read -r -p "Generate self-signed certificates? (y/n): " gen_certs
    
    if [[ $gen_certs =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔐 Generating self-signed certificates...${NC}"
        if openssl req -x509 -nodes -newkey rsa:4096 -keyout syslog.key -out syslog.crt -subj '/CN=localhost' -days 3650; then
            echo -e "${GREEN}✅ SSL certificates generated${NC}"
        else
            echo -e "${RED}❌ Failed to generate certificates${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️  You'll need to provide SSL certificates manually${NC}"
        echo "Required files: syslog.crt and syslog.key"
    fi
else
    echo -e "${GREEN}✅ SSL certificates found${NC}"
fi

echo ""
echo -e "${YELLOW}🔧 Configuration Required${NC}"
echo "Please edit the .env file with your SentinelOne details:"
echo ""
echo "1. S1_WRITE_TOKEN - Your SentinelOne API token"
echo "2. S1_INGEST_URL - Your SentinelOne ingest URL"
echo "3. SYSLOG_HOST - Unique identifier for this host"
echo "4. Configure SOURCE1_, SOURCE2_, etc. for your log sources"
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
echo "Start the 3-in-1 pipeline:"
echo "  docker compose up -d"
echo ""
echo "Check status:"
echo "  docker compose ps"
echo ""
echo "View logs:"
echo "  docker compose logs -f"
echo ""
echo "Test syslog reception:"
echo "  bash test-syslog.sh"
echo ""
echo "Stop the pipeline:"
echo "  docker compose down"
echo ""

echo -e "${GREEN}🎉 3-in-1 Pipeline setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Edit .env with your S1 credentials and source configurations"
echo "2. Run: docker compose up -d"
echo "3. Test with: bash test-syslog.sh"
echo "4. Check logs appear in SentinelOne with proper parsing"
echo ""
echo -e "${CYAN}💡 Tips:${NC}"
echo "- This solution excels at differentiating logs by content"
echo "- Configure SOURCE*_ variables for each log type" 
echo "- Use different parsers to properly categorize your logs"