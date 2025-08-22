#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 SentinelOne Syslog Solutions Toolkit${NC}"
echo "========================================"
echo ""
echo "This toolkit helps you choose the right syslog solution for your environment."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed.${NC}"
    echo "Please install Docker before proceeding: https://docs.docker.com/engine/install/"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null && ! docker-compose --version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not available.${NC}"
    echo "Please install Docker Compose before proceeding: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✅ Docker and Docker Compose are available${NC}"
echo ""

echo -e "${YELLOW}Which solution fits your needs?${NC}"
echo ""
echo -e "${BLUE}1) Simple Collector${NC} - Basic multi-port syslog collection"
echo "   ✅ Easy setup, multiple ports, S1 supported"
echo "   📦 1 container, addEvents API"
echo "   ⏱️  Setup time: ~5 minutes"
echo ""
echo -e "${BLUE}2) 3-in-1 Pipeline${NC} - Content-based log differentiation" 
echo "   ✅ Advanced routing, config generation, S1 supported"
echo "   📦 3 containers, addEvents API"
echo "   ⏱️  Setup time: ~15 minutes"
echo ""
echo -e "${BLUE}3) Rootless Syslog-NG${NC} - High-performance, single container"
echo "   ✅ Rootless, HEC endpoint, community supported"
echo "   📦 1 container, HEC API (higher throughput)"
echo "   ⏱️  Setup time: ~10 minutes"
echo ""
echo -e "${BLUE}4) View all solutions${NC} (stay in root directory)"
echo ""
echo -e "${BLUE}5) Exit${NC}"
echo ""

while true; do
    read -r -p "Choose your solution (1-5): " choice
    
    case $choice in
        1)
            echo ""
            echo -e "${GREEN}🚀 Setting up Simple Collector...${NC}"
            echo "This solution provides basic multi-port syslog collection with S1 official support."
            if [ -d "simple-collector" ]; then
                cd simple-collector || exit 1
                if [ -f "setup.sh" ]; then
                    chmod +x setup.sh
                    ./setup.sh
                else
                    echo -e "${YELLOW}Setup script not found. Please see simple-collector/README.md for manual setup.${NC}"
                fi
            else
                echo -e "${RED}❌ Simple collector directory not found.${NC}"
            fi
            break
            ;;
        2)
            echo ""
            echo -e "${GREEN}🔧 Setting up 3-in-1 Pipeline...${NC}"
            echo "This solution provides advanced content-based log routing with S1 official support."
            if [ -d "3-in-1-pipeline" ]; then
                cd 3-in-1-pipeline || exit 1
                if [ -f "setup.sh" ]; then
                    chmod +x setup.sh
                    ./setup.sh
                else
                    echo -e "${YELLOW}Setup script not found. Please see 3-in-1-pipeline/README.md for manual setup.${NC}"
                fi
            else
                echo -e "${RED}❌ 3-in-1 pipeline directory not found.${NC}"
            fi
            break
            ;;
        3)
            echo ""
            echo -e "${GREEN}⚡ Setting up Rootless Syslog-NG...${NC}"
            echo "This solution provides high-performance, security-focused log collection."
            if [ -d "rootless-syslog-ng" ]; then
                cd rootless-syslog-ng || exit 1
                if [ -f "setup.sh" ]; then
                    chmod +x setup.sh
                    ./setup.sh
                else
                    echo -e "${YELLOW}Setup script not found. Please see rootless-syslog-ng/README.md for manual setup.${NC}"
                fi
            else
                echo -e "${RED}❌ Rootless syslog-ng directory not found.${NC}"
            fi
            break
            ;;
        4)
            echo ""
            echo -e "${CYAN}📁 Staying in root directory.${NC}"
            echo "Explore the solutions manually:"
            echo "  - simple-collector/"
            echo "  - 3-in-1-pipeline/"
            echo "  - rootless-syslog-ng/"
            echo ""
            echo "Each directory contains a complete solution with its own README.md"
            break
            ;;
        5)
            echo ""
            echo -e "${CYAN}👋 Goodbye!${NC}"
            echo "Visit the individual solution directories when you're ready to proceed."
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid choice. Please enter 1, 2, 3, 4, or 5.${NC}"
            ;;
    esac
done

echo ""
echo -e "${CYAN}📚 Need help?${NC}"
echo "  - Check the solution's README.md for detailed instructions"
echo "  - Review shared/samples/ for test log files"
echo "  - Visit shared/docs/ for architecture information"