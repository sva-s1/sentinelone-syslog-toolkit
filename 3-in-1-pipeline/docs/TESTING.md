# Testing the Syslog Collector

This document describes how to test the syslog collector with sample messages and verify DataSource attributes are working correctly.

## Quick Testing

### Local Testing
```bash
# Make the test script executable
chmod +x utils/send.sh

# Run the test script
./utils/send.sh
```

This will send 3 sample messages:
1. **Cisco Firewall** (hostname: `firewall4`) → matches `firewall*` pattern
2. **Cisco Router** (hostname: `router01`) → matches `router*` pattern  
3. **Palo Alto Firewall** (appname: `PA-220`) → matches `PA-*` pattern

### GitHub Actions Testing
The repository includes automated testing via GitHub Actions:

- **Manual trigger**: Go to Actions tab → "Test Syslog Collector" → "Run workflow"
- **Automatic trigger**: Pushes to main branch or PRs affecting config/scripts
- **Validates**: Configuration files, dynamic source detection, message processing

## Test Files Structure

```
syslog-collector/
├── utils/
│   └── send.sh                    # Test script
├── samples/
│   ├── cisco-firewall.log         # Cisco ASA firewall sample
│   ├── cisco-router.log           # Cisco router OSPF sample
│   └── palo-alto.log              # Palo Alto threat log sample
└── .github/workflows/
    └── test-syslog.yml            # GitHub Actions workflow
```

## Sample Log Formats

### Cisco Firewall (ASA)
```
<134>1 2025-07-29T00:37:12.000Z docker-desktop firewall4 12345 INTF-ALERT [exampleSDID@32473 iut="3" eventSource="cisco"] %ASA-4-313001: Built inbound TCP connection for faddr 10.20.30.40/12345 gaddr 192.168.1.1/80 laddr 172.16.0.2/443
```

### Cisco Router (OSPF)
```
<134>1 2025-07-29T00:37:12.000Z router01 ospf 23456 LINK-STATE [exampleSDID@32473 iut="2" eventSource="cisco"] %OSPF-5-ADJCHG: Process 1, Nbr 192.168.1.100 on GigabitEthernet0/1 from LOADING to FULL, Loading Done
```

### Palo Alto Firewall (Threat Log)
```
<134>1 2025-07-29T00:37:12.000Z PA-220 PA-220 - THREAT,virus,2025/07/29 15:10:22,192.168.1.10,10.1.30.45,203.0.113.5,198.51.100.100,Block-Malware,jsmith,unknown,web-browsing,vsys1,Trust,Untrust,ethernet1/2,ethernet1/6,Forward-to-SIEM,123456789,1,51820,80,50900,80,0x40000000,6,reset-both,malicious_file.exe,32001,any,high,0,8947368293,0,United States,United States
```

## Expected DataSource Attributes

After sending test messages, verify these attributes appear in SentinelOne SDL:

| Source Type | Category | Name | Vendor |
|-------------|----------|------|--------|
| Cisco Firewall | security | Cisco Firepower Threat Defense | Cisco |
| Cisco Router | security | Cisco Router | Cisco |
| Palo Alto Firewall | security | Palo Alto Firewall | Palo Alto Networks |

## Verification Commands

```bash
# Check container logs
docker compose logs config-generator  # See dynamic source detection
docker compose logs scalyr-agent      # See agent processing
docker compose logs syslog-ng         # See message reception

# Check generated agent.json
docker exec syslog-collector-scalyr-agent-1 cat /etc/scalyr-agent-2/agent.json

# Check for dataSource attributes in agent.json
docker exec syslog-collector-scalyr-agent-1 cat /etc/scalyr-agent-2/agent.json | grep -A5 -B5 dataSource
```

## Adding New Test Cases

1. **Create sample log file** in `samples/` directory
2. **Add source configuration** to `.env` file
3. **Update send.sh** to include new test case
4. **Update GitHub Actions** workflow if needed

Example for adding SOURCE4:
```bash
# In .env file
SOURCE4_NAME=new-device-type
SOURCE4_PARSER=newDeviceParser
SOURCE4_ATTRIBUTE=hostname
SOURCE4_MATCHER=new-*
SOURCE4_DATASOURCE_NAME="New Device Type"
SOURCE4_DATASOURCE_VENDOR="New Vendor"
SOURCE4_DATASOURCE_CATEGORY="network"
```

## Troubleshooting

### Common Issues
- **No messages received**: Check UDP port 514 is accessible
- **Wrong parser applied**: Verify matcher patterns in SOURCE*_MATCHER
- **Missing dataSource attributes**: Check post-processing logs in config-generator
- **Container health issues**: Check docker compose logs for errors

### Debug Commands
```bash
# Check dynamic source detection
docker compose logs config-generator | grep -E "(Detecting|Processing|Found)"

# Verify agent.json structure
docker exec syslog-collector-scalyr-agent-1 cat /etc/scalyr-agent-2/agent.json | jq .

# Check syslog-ng file creation
docker compose exec syslog-ng ls -la /var/log/syslog-collector/
```
