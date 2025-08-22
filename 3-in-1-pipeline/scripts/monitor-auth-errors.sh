#!/bin/bash

# Monitor scalyr-agent logs for authentication errors
# This script can be run alongside the main containers to detect API token issues

echo "🔍 Starting authentication error monitoring..."
echo "   Monitoring scalyr-agent logs for authentication failures"
echo "   Press Ctrl+C to stop monitoring"
echo ""

# Function to check for authentication errors in logs
check_auth_errors() {
    local log_output="$1"
    
    # Check for various authentication error patterns
    if echo "$log_output" | grep -qi "401\|unauthorized\|authentication.*failed\|invalid.*token\|forbidden"; then
        echo "❌ AUTHENTICATION ERROR DETECTED!"
        echo "   Time: $(date)"
        echo "   Error details:"
        echo "$log_output" | grep -i "401\|unauthorized\|authentication.*failed\|invalid.*token\|forbidden" | head -5
        echo ""
        echo "🔧 RECOMMENDED ACTIONS:"
        echo "   1. Check your AISIEM_LOGACCESS_WRITE_TOKEN environment variable"
        echo "   2. Verify the token is valid and not expired"
        echo "   3. Ensure the token has proper permissions for SDL"
        echo "   4. Restart containers after fixing the token: docker compose restart"
        echo ""
        return 1
    fi
    
    # Check for network connectivity issues
    if echo "$log_output" | grep -qi "connection.*refused\|timeout\|network.*error\|dns.*resolution"; then
        echo "⚠️  NETWORK CONNECTIVITY ISSUE DETECTED!"
        echo "   Time: $(date)"
        echo "   This may prevent SDL delivery even with valid credentials"
        echo ""
        return 1
    fi
    
    return 0
}

# Function to monitor logs continuously
monitor_logs() {
    local error_count=0
    local last_error_time=0
    
    # Follow scalyr-agent logs
    docker compose logs -f scalyr-agent 2>/dev/null | while read -r line; do
        # Check each line for errors
        if ! check_auth_errors "$line"; then
            error_count=$((error_count + 1))
            current_time=$(date +%s)
            
            # Rate limit error notifications (max 1 per minute)
            if [ $((current_time - last_error_time)) -gt 60 ]; then
                echo "📊 Total authentication errors detected: $error_count"
                last_error_time=$current_time
            fi
        fi
        
        # Also show successful requests for context
        if echo "$line" | grep -q "agent_requests.*requests_sent"; then
            echo "📈 $(date): $line"
        fi
    done
}

# Function to run a one-time check
check_recent_logs() {
    echo "🔍 Checking recent scalyr-agent logs for authentication errors..."
    
    # Get last 50 lines of logs
    recent_logs=$(docker compose logs scalyr-agent --tail 50 2>/dev/null)
    
    if [ -z "$recent_logs" ]; then
        echo "⚠️  Cannot access scalyr-agent logs. Is the container running?"
        echo "   Run: docker compose ps"
        return 1
    fi
    
    # Check for errors in recent logs
    if check_auth_errors "$recent_logs"; then
        echo "✅ No authentication errors found in recent logs"
        
        # Show recent request statistics
        echo ""
        echo "📊 Recent request statistics:"
        echo "$recent_logs" | grep "agent_requests" | tail -3
    fi
}

# Main execution
case "${1:-monitor}" in
    "check")
        check_recent_logs
        ;;
    "monitor")
        # Check if docker compose is available
        if ! command -v docker >/dev/null 2>&1; then
            echo "❌ Docker not found. Please install Docker first."
            exit 1
        fi
        
        # Check if containers are running
        if ! docker compose ps | grep -q "scalyr-agent.*Up"; then
            echo "❌ scalyr-agent container is not running"
            echo "   Start containers with: docker compose up -d"
            exit 1
        fi
        
        # Run initial check
        check_recent_logs
        echo ""
        echo "🔄 Starting continuous monitoring..."
        
        # Start continuous monitoring
        monitor_logs
        ;;
    *)
        echo "Usage: $0 [check|monitor]"
        echo "  check   - Check recent logs once for authentication errors"
        echo "  monitor - Continuously monitor logs for authentication errors (default)"
        exit 1
        ;;
esac
