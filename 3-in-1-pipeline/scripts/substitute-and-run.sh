#!/bin/sh

# API Token validation function
validate_api_token() {
    local api_token="$1"
    local server_url="$2"
    
    if [ -z "$api_token" ]; then
        echo "❌ FATAL ERROR: API token is empty or not set!"
        echo "   Please check AISIEM_LOGACCESS_WRITE_TOKEN environment variable"
        exit 1
    fi
    
    if [ -z "$server_url" ]; then
        echo "❌ FATAL ERROR: Server URL is empty or not set!"
        echo "   Please check AISIEM_SERVER environment variable"
        exit 1
    fi
    
    echo "🔐 Validating API token with SentinelOne SDL..."
    
    # Test API token by making a simple request to the server
    # Use a lightweight endpoint to validate credentials
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" \
        "$server_url/api/v1/addEvents" \
        -d '[]' \
        --connect-timeout 10 \
        --max-time 30)
    
    case "$response" in
        "200"|"400") # 200=success, 400=bad request but auth OK
            echo "✅ API token validation successful"
            return 0
            ;;
        "401"|"403")
            echo "❌ FATAL ERROR: API token authentication failed (HTTP $response)"
            echo "   The provided API token is invalid or expired"
            echo "   Please check your AISIEM_LOGACCESS_WRITE_TOKEN"
            exit 1
            ;;
        "000")
            echo "⚠️  WARNING: Cannot connect to SentinelOne SDL server"
            echo "   Server: $server_url"
            echo "   This may be a network connectivity issue"
            echo "   Proceeding with startup, but SDL delivery may fail"
            return 0
            ;;
        *)
            echo "⚠️  WARNING: Unexpected response from SDL server (HTTP $response)"
            echo "   Proceeding with startup, but SDL delivery may fail"
            return 0
            ;;
    esac
}

# Cleanup function to remove sensitive files
cleanup() {
    if [ -f "$SECURE_INPUT" ]; then
        rm -f "$SECURE_INPUT"
    fi
    if [ -p "$FIFO_PATH" ]; then
        rm -f "$FIFO_PATH"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Create a secure temporary file with restricted permissions
SECURE_INPUT=$(mktemp -t syslog-config.XXXXXX)
chmod 600 "$SECURE_INPUT"

# Generate syslog.yaml from template using environment variables
# Use a safer approach that handles special characters properly
cp /etc/syslog-collector/config/syslog.yaml "$SECURE_INPUT"

# Function to safely replace variables using printf for proper escaping
safe_replace() {
    local var_name="$1"
    local var_value="$2"
    local temp_file="$SECURE_INPUT.tmp"
    
    # Use a different delimiter that's unlikely to appear in values
    sed "s|\${${var_name}}|${var_value}|g" "$SECURE_INPUT" > "$temp_file"
    mv "$temp_file" "$SECURE_INPUT"
}

# Replace basic configuration variables
safe_replace "AISIEM_LOGACCESS_WRITE_TOKEN" "$(printenv AISIEM_LOGACCESS_WRITE_TOKEN)"
safe_replace "AISIEM_SERVER" "$(printenv AISIEM_SERVER)"
safe_replace "SYSLOG_HOST" "$(printenv SYSLOG_HOST)"
safe_replace "PORT1_PROTOCOL" "$(printenv PORT1_PROTOCOL)"
safe_replace "PORT1_NUMBER" "$(printenv PORT1_NUMBER)"
safe_replace "PORT1_TYPE" "$(printenv PORT1_TYPE)"
safe_replace "PORT2_PROTOCOL" "$(printenv PORT2_PROTOCOL)"
safe_replace "PORT2_NUMBER" "$(printenv PORT2_NUMBER)"
safe_replace "PORT2_TYPE" "$(printenv PORT2_TYPE)"

# Dynamically generate source-types configuration
echo "DEBUG: Detecting SOURCE* environment variables..."
SOURCE_CONFIG=""
SOURCE_COUNT=0

# Find all SOURCE*_NAME variables to determine configured sources
for var in $(printenv | grep '^SOURCE[0-9]*_NAME=' | sort -V); do
    source_num=$(echo "$var" | sed 's/SOURCE\([0-9]*\)_NAME=.*/\1/')
    source_name=$(echo "$var" | sed 's/SOURCE[0-9]*_NAME=//')
    
    # Skip if source name is empty
    if [ -z "$source_name" ]; then
        continue
    fi
    
    # Get all required variables for this source
    parser_var="SOURCE${source_num}_PARSER"
    attribute_var="SOURCE${source_num}_ATTRIBUTE"
    matcher_var="SOURCE${source_num}_MATCHER"
    
    parser_val=$(printenv "$parser_var")
    attribute_val=$(printenv "$attribute_var")
    matcher_val=$(printenv "$matcher_var")
    
    # Skip if any required variable is missing
    if [ -z "$parser_val" ] || [ -z "$attribute_val" ] || [ -z "$matcher_val" ]; then
        echo "DEBUG: Skipping SOURCE${source_num} - missing required variables"
        continue
    fi
    
    echo "DEBUG: Processing SOURCE${source_num}: $source_name"
    
    # Get optional dataSource variables
    ds_name_var="SOURCE${source_num}_DATASOURCE_NAME"
    ds_vendor_var="SOURCE${source_num}_DATASOURCE_VENDOR"
    ds_category_var="SOURCE${source_num}_DATASOURCE_CATEGORY"
    
    ds_name_val=$(printenv "$ds_name_var")
    ds_vendor_val=$(printenv "$ds_vendor_var")
    ds_category_val=$(printenv "$ds_category_var")
    
    # Build source configuration
    SOURCE_CONFIG="${SOURCE_CONFIG}  - ${source_name}:\n"
    SOURCE_CONFIG="${SOURCE_CONFIG}     parser: ${parser_val}\n"
    
    # Add attributes section if any dataSource attributes are defined
    if [ -n "$ds_name_val" ] || [ -n "$ds_vendor_val" ] || [ -n "$ds_category_val" ]; then
        SOURCE_CONFIG="${SOURCE_CONFIG}     attributes:\n"
        [ -n "$ds_category_val" ] && SOURCE_CONFIG="${SOURCE_CONFIG}       dataSource.category: ${ds_category_val}\n"
        [ -n "$ds_name_val" ] && SOURCE_CONFIG="${SOURCE_CONFIG}       dataSource.name: ${ds_name_val}\n"
        [ -n "$ds_vendor_val" ] && SOURCE_CONFIG="${SOURCE_CONFIG}       dataSource.vendor: ${ds_vendor_val}\n"
    fi
    
    # Add matchers section
    SOURCE_CONFIG="${SOURCE_CONFIG}     matchers:\n"
    SOURCE_CONFIG="${SOURCE_CONFIG}     - attribute: ${attribute_val}\n"
    SOURCE_CONFIG="${SOURCE_CONFIG}       matcher: \"${matcher_val}\"\n"
    
    SOURCE_COUNT=$((SOURCE_COUNT + 1))
    
    # Debug output
    echo "DEBUG: SOURCE${source_num}_DATASOURCE_NAME='$ds_name_val'"
    echo "DEBUG: SOURCE${source_num}_DATASOURCE_VENDOR='$ds_vendor_val'"
    echo "DEBUG: SOURCE${source_num}_DATASOURCE_CATEGORY='$ds_category_val'"
done

echo "DEBUG: Found $SOURCE_COUNT configured sources"

# Replace the placeholder with generated source configuration
if [ $SOURCE_COUNT -gt 0 ]; then
    # Create a temporary file with the source configuration
    TEMP_SOURCES=$(mktemp)
    printf "%s" "$SOURCE_CONFIG" | sed 's/\\n/\n/g' > "$TEMP_SOURCES"
    
    # Use awk to replace the placeholder with the file contents
    awk '
    /# DYNAMIC_SOURCES_PLACEHOLDER/ {
        while ((getline line < "'"$TEMP_SOURCES"'") > 0) {
            print line
        }
        close("'"$TEMP_SOURCES"'")
        next
    }
    { print }
    ' "$SECURE_INPUT" > "$SECURE_INPUT.tmp" && mv "$SECURE_INPUT.tmp" "$SECURE_INPUT"
    
    rm -f "$TEMP_SOURCES"
else
    echo "WARNING: No valid SOURCE configurations found!"
    # Remove the placeholder line
    sed '/# DYNAMIC_SOURCES_PLACEHOLDER.*/d' "$SECURE_INPUT" > "$SECURE_INPUT.tmp" && mv "$SECURE_INPUT.tmp" "$SECURE_INPUT"
fi

# Dynamic source configuration complete

# Dynamic source generation handles attributes properly - no cleanup needed

# Set INPUT to point to the secure substituted file
export INPUT="$SECURE_INPUT"

# Check for required files
abort=0
for f in /etc/syslog-collector/config/syslog.yaml /etc/syslog-collector/syslog.crt /etc/syslog-collector/syslog.key; do
  test -e "$f" || { echo "$(basename "$f") not found"; abort=1; }
done
if [ $abort -eq 1 ]; then
    cleanup
    exit 1
fi

# Create cert directory and copy certificates
mkdir -p /out/etc/syslog-ng/cert.d
(cd /etc/syslog-collector && cp -f syslog.crt syslog.key /out/etc/syslog-ng/cert.d)

# Validate API token before starting config-generator
# Extract API token and server from the secure input file
API_TOKEN=$(grep '^api-token:' "$SECURE_INPUT" | sed 's/^api-token: *//')
DESTINATION=$(grep '^destination:' "$SECURE_INPUT" | sed 's/^destination: *//')

# Convert destination to full URL if needed
if echo "$DESTINATION" | grep -q '^https\?://'; then
    SERVER_URL="$DESTINATION"
else
    SERVER_URL="https://$DESTINATION"
fi

# Validate the API token
validate_api_token "$API_TOKEN" "$SERVER_URL"

# Run the config-generator with all required parameters in background
config-generator \
  -i "$INPUT" \
  -o "$AGENT_OUTPUT" \
  -s "$SYSLOG_OUTPUT" \
  -lc "$LOGROTATE_CONFIG_OUTPUT" \
  -ls "$LOGROTATE_SCRIPT_OUTPUT" \
  -l "$LOGPATH" \
  -d "$SYSLOG_IMAGE" \
  -e "$VERSION" &

CONFIG_GENERATOR_PID=$!
echo "DEBUG: Config-generator started with PID $CONFIG_GENERATOR_PID"

# Wait for the initial config files to be created
echo "DEBUG: Waiting for agent.json to be created..."
for i in $(seq 1 30); do
    if [ -f "$AGENT_OUTPUT" ]; then
        echo "DEBUG: agent.json found after ${i} seconds"
        break
    fi
    sleep 1
done

# Set up continuous post-processing monitoring
if [ -f "/etc/syslog-collector/scripts/post-process-agent.sh" ]; then
    echo "DEBUG: Setting up continuous post-processing monitoring..."
    cp "/etc/syslog-collector/scripts/post-process-agent.sh" "/tmp/post-process-agent.sh"
    chmod +x "/tmp/post-process-agent.sh"
    
    # Start monitoring loop in background
    (
        LAST_MODIFIED=""
        while true; do
            if [ -f "$AGENT_OUTPUT" ]; then
                CURRENT_MODIFIED=$(stat -c %Y "$AGENT_OUTPUT" 2>/dev/null || stat -f %m "$AGENT_OUTPUT" 2>/dev/null)
                if [ "$CURRENT_MODIFIED" != "$LAST_MODIFIED" ]; then
                    echo "DEBUG: agent.json modified, re-applying dataSource attributes..."
                    /tmp/post-process-agent.sh "$AGENT_OUTPUT"
                    LAST_MODIFIED="$CURRENT_MODIFIED"
                fi
            fi
            sleep 5
        done
    ) &
    MONITOR_PID=$!
    echo "DEBUG: Post-processing monitor started with PID $MONITOR_PID"
else
    echo "WARNING: post-process-agent.sh not found, dataSource attributes will be missing"
fi

# Wait for the config-generator to continue running
echo "DEBUG: Waiting for config-generator to continue..."
wait $CONFIG_GENERATOR_PID
CONFIG_EXIT_CODE=$?

# Clean up monitoring process
if [ ! -z "$MONITOR_PID" ]; then
    echo "DEBUG: Stopping post-processing monitor..."
    kill $MONITOR_PID 2>/dev/null
fi

# Call cleanup and exit with the same code as the config generator
cleanup
exit $CONFIG_EXIT_CODE
