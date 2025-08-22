#!/bin/bash
# Setup script for Python testing environment

set -e

echo "🐍 Setting up Python testing environment..."

# Check if we're in the right directory
if [ ! -f "../docker-compose.yml" ]; then
    echo "❌ Please run this script from the testing/ directory"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source .venv/bin/activate

# Install requirements
echo "📥 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "✅ Setup complete!"
echo ""
echo "To use the testing environment:"
echo "  1. cd testing/"
echo "  2. source .venv/bin/activate"
echo "  3. python send_syslog.py --help"
echo ""
echo "Example usage:"
echo "  python send_syslog.py --all"
echo "  python send_syslog.py --source cisco-asa --uuid"
