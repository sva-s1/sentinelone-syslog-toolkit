#!/usr/bin/env python3
"""
Syslog Test Script with UUID Injection Support

This script sends test syslog messages to the collector and optionally injects
UUIDs for traceability when INJECT_UUID=true in the environment.

Usage:
    python send_syslog.py --source cisco-asa
    python send_syslog.py --source palo-alto
    python send_syslog.py --source linux-syslog
    python send_syslog.py --all
"""

import socket
import uuid
import os
import sys
import argparse
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables from parent directory .env file
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env'))

# Syslog configuration
SYSLOG_HOST = '127.0.0.1'
SYSLOG_PORT = 514

# Test log messages for each source type
LOG_MESSAGES = {
    'cisco-router': {
        'message': '<134>1 2025-08-01T13:47:39.000Z router01 ospf 23456 LINK-STATE [exampleSDID@32473 iut="2" eventSource="cisco"] %OSPF-5-ADJCHG: Process 1, Nbr 192.168.1.100 on GigabitEthernet0/1 from LOADING to FULL, Loading Done',
        'description': 'Cisco Router (hostname=router01) - RFC 5424',
        'expected_parser': 'ciscoRouter2',
        'port': 514
    },
    'palo-alto': {
        'message': '<134>Aug  1 13:47:39 firewall01 PA-220-PA-220: THREAT: virus detected from 192.168.1.10 to 203.0.113.5, action=reset-both, file=malicious_file.exe',
        'description': 'Palo Alto Firewall (appname=PA-220-PA-220) - RFC 3164',
        'expected_parser': 'paloAltoFirewall',
        'port': 514
    },
    'cisco-firewall': {
        'message': '<134>1 2025-08-01T13:47:39.000Z docker-desktop firewall4 12345 INTF-ALERT [exampleSDID@32473 iut="3" eventSource="cisco"] %ASA-4-313001: Built inbound TCP connection for faddr 10.20.30.40/12345 gaddr 192.168.1.1/80 laddr 172.16.0.2/443',
        'description': 'Cisco Firewall (hostname=docker-desktop) - RFC 5424',
        'expected_parser': 'ciscoFirewall2',
        'port': 514
    }
}

def generate_uuid():
    """Generate a UUID for traceability"""
    return str(uuid.uuid4())

def inject_uuid_into_message(message, test_uuid):
    """
    Inject UUID into syslog message for traceability.
    This adds a custom field that can be extracted by the collector.
    """
    # For RFC 3164 messages, append UUID as a custom field
    if message.startswith('<') and '>' in message:
        # Find the end of the priority and timestamp
        priority_end = message.find('>')
        if priority_end != -1:
            # Insert UUID field after the standard syslog header
            # This will be available for extraction by syslog-ng
            uuid_field = f" [TEST_UUID={test_uuid}]"
            # Find a good insertion point (after hostname/appname)
            parts = message.split(' ', 4)
            if len(parts) >= 4:
                # Insert UUID field before the message content
                return ' '.join(parts[:4]) + uuid_field + ' ' + parts[4] if len(parts) > 4 else ' '.join(parts) + uuid_field
    
    # Fallback: append UUID to end of message
    return f"{message} [TEST_UUID={test_uuid}]"

def send_syslog_message(source_type, inject_uuid=False):
    """Send a syslog message for the specified source type"""
    
    if source_type not in LOG_MESSAGES:
        print(f"❌ Unknown source type: {source_type}")
        return False
    
    log_config = LOG_MESSAGES[source_type]
    message = log_config['message']
    port = log_config['port']
    test_uuid = None
    
    # Generate and inject UUID if requested
    if inject_uuid:
        test_uuid = generate_uuid()
        message = inject_uuid_into_message(message, test_uuid)
        print(f"🔍 Generated UUID for traceability: {test_uuid}")
    
    try:
        # Create UDP socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        
        # Send the message to the correct port
        sock.sendto(message.encode('utf-8'), (SYSLOG_HOST, port))
        sock.close()
        
        print(f"✅ Sent {log_config['description']}")
        print(f"   Port: {port}")
        print(f"   Expected Parser: {log_config['expected_parser']}")
        if test_uuid:
            print(f"   Trace UUID: {test_uuid}")
        print(f"   Message: {message}")
        print()
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to send {source_type}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Send test syslog messages to the collector')
    parser.add_argument('--source', choices=['cisco-router', 'palo-alto', 'cisco-firewall'], 
                       help='Send message for specific source type')
    parser.add_argument('--all', action='store_true', 
                       help='Send messages for all source types')
    parser.add_argument('--uuid', action='store_true',
                       help='Force UUID injection (overrides INJECT_UUID env var)')
    
    args = parser.parse_args()
    
    if not args.source and not args.all:
        parser.print_help()
        sys.exit(1)
    
    # Check UUID injection setting
    inject_uuid = args.uuid or os.getenv('INJECT_UUID', 'false').lower() == 'true'
    
    if inject_uuid:
        print("🔍 UUID injection enabled for traceability")
    else:
        print("ℹ️  UUID injection disabled (set INJECT_UUID=true or use --uuid to enable)")
    
    print(f"📡 Sending to syslog collector at {SYSLOG_HOST}:{SYSLOG_PORT}")
    print("=" * 60)
    
    success_count = 0
    total_count = 0
    
    if args.all:
        # Send all message types
        for source_type in LOG_MESSAGES.keys():
            total_count += 1
            if send_syslog_message(source_type, inject_uuid):
                success_count += 1
    else:
        # Send specific message type
        total_count = 1
        if send_syslog_message(args.source, inject_uuid):
            success_count += 1
    
    print("=" * 60)
    print(f"📊 Results: {success_count}/{total_count} messages sent successfully")
    
    if inject_uuid and success_count > 0:
        print("\n💡 Troubleshooting Tips:")
        print("   - Use the UUID(s) above to search for events in SentinelOne SIEM")
        print("   - Query with parser-based searches for better accuracy")
        print("   - Check container logs: docker-compose logs syslog-ng")

if __name__ == '__main__':
    main()
