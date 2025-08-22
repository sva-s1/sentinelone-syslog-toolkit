#!/bin/sh

# Post-processing script to add dataSource attributes to agent.json
# This script is called after the config-generator creates the initial agent.json

AGENT_JSON="$1"

if [ -z "$AGENT_JSON" ] || [ ! -f "$AGENT_JSON" ]; then
    echo "Usage: $0 <path-to-agent.json>"
    exit 1
fi

echo "Post-processing $AGENT_JSON to add dataSource attributes..."

# Create a temporary file for the updated agent.json
TEMP_AGENT_JSON=$(mktemp)
trap "rm -f $TEMP_AGENT_JSON" EXIT

# Get all SOURCE* dataSource values from environment (dynamic detection)
echo "DEBUG: Detecting SOURCE* dataSource environment variables..."

# Use Python to process the JSON (more reliable than jq in containers)
python3 << EOF
import json
import sys
import os

# Read the original agent.json
try:
    with open('$AGENT_JSON', 'r') as f:
        agent_config = json.load(f)
except Exception as e:
    print(f"Error reading agent.json: {e}")
    sys.exit(1)

# Dynamically get all SOURCE* dataSource environment variables
source_configs = {}
for key, value in os.environ.items():
    # Only process SOURCE*_NAME variables (not DATASOURCE_NAME)
    if key.startswith('SOURCE') and key.endswith('_NAME') and '_DATASOURCE_' not in key:
        # Extract source number from SOURCE{N}_NAME
        source_num = key.split('_')[0].replace('SOURCE', '')
        if source_num not in source_configs:
            source_configs[source_num] = {}
        
        # Get the source name to determine source type (this is the SOURCE*_NAME value)
        source_name = value.strip()
        source_configs[source_num]['source_type'] = source_name
        
        # Get corresponding dataSource attributes
        ds_name = os.environ.get(f'SOURCE{source_num}_DATASOURCE_NAME', '').strip()
        ds_vendor = os.environ.get(f'SOURCE{source_num}_DATASOURCE_VENDOR', '').strip()
        ds_category = os.environ.get(f'SOURCE{source_num}_DATASOURCE_CATEGORY', '').strip()
        
        if ds_name or ds_vendor or ds_category:
            source_configs[source_num]['dataSource'] = {
                'name': ds_name,
                'vendor': ds_vendor,
                'category': ds_category
            }
            print(f"Found dataSource config for SOURCE{source_num}: {source_name} -> {ds_name}")

# Process each log entry
if 'logs' in agent_config:
    for log_entry in agent_config['logs']:
        if 'attributes' in log_entry:
            source_type = log_entry['attributes'].get('source_type', '')
            print(f"Processing log entry with source_type: '{source_type}'")
            
            # Find matching source configuration by source_type
            matched = False
            for source_num, config in source_configs.items():
                print(f"  Checking SOURCE{source_num} with source_type: '{config.get('source_type', '')}'")
                if 'dataSource' in config and config['source_type'] == source_type:
                    ds_attrs = config['dataSource']
                    print(f"  MATCH! Adding dataSource attributes to {source_type}")
                    
                    if ds_attrs['category']:
                        log_entry['attributes']['dataSource.category'] = ds_attrs['category']
                    if ds_attrs['name']:
                        log_entry['attributes']['dataSource.name'] = ds_attrs['name']
                    if ds_attrs['vendor']:
                        log_entry['attributes']['dataSource.vendor'] = ds_attrs['vendor']
                    matched = True
                    break
            
            if not matched:
                print(f"  No match found for source_type: '{source_type}'")

# Write the updated configuration
try:
    with open('$TEMP_AGENT_JSON', 'w') as f:
        json.dump(agent_config, f, indent=2)
    print("Successfully processed agent.json")
except Exception as e:
    print(f"Error writing updated agent.json: {e}")
    sys.exit(1)
EOF

# Check if the Python script succeeded
if [ $? -eq 0 ] && [ -s "$TEMP_AGENT_JSON" ]; then
    mv "$TEMP_AGENT_JSON" "$AGENT_JSON"
    echo "Successfully added dataSource attributes to agent.json"
else
    echo "Warning: Failed to process agent.json, keeping original"
    exit 1
fi
