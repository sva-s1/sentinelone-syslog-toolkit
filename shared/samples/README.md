# Sample Log Files

This directory contains sample log files for testing the various syslog solutions in this toolkit.

## Available Samples

### FortiGate Firewall
- **File:** `fortigate-sample.log`
- **Use Case:** Network security appliance logs
- **Parser:** `marketplace-fortinetfortigate-latest`
- **Format:** Traditional syslog with structured data

### ZScaler Internet Access  
- **File:** `zscaler-sample.log`
- **Use Case:** Web proxy and security logs
- **Parser:** `marketplace-zscalerinternetaccess-latest`
- **Format:** CEF (Common Event Format)

### Linux System Logs
- **File:** `linux-sample.log`
- **Use Case:** General Linux/Unix system logs
- **Parser:** `linuxSyslog`
- **Format:** Standard RFC3164 syslog

### Cisco Firewall
- **File:** `cisco-firewall.log`
- **Use Case:** Cisco ASA/Firepower logs
- **Parser:** `ciscoFirewall1` or similar
- **Format:** Cisco proprietary syslog format

### Cisco Router
- **File:** `cisco-router.log`
- **Use Case:** Cisco router and switch logs
- **Parser:** `ciscoRouter1` or similar
- **Format:** Cisco IOS syslog format

### Palo Alto Networks
- **File:** `palo-alto.log`
- **Use Case:** Palo Alto firewall logs
- **Parser:** `marketplace-paloaltonetworksfirewall-latest`
- **Format:** Structured syslog with key=value pairs

## Testing with Samples

### Using netcat (nc)
```bash
# Send a sample to UDP port 514
cat fortigate-sample.log | nc -u localhost 514

# Send a sample to TCP port 601  
cat cisco-firewall.log | nc localhost 601
```

### Using logger command
```bash
# Send via UDP
logger -P 514 -n 127.0.0.1 -p user.info "$(cat linux-sample.log)"

# Send via TCP
logger -T 601 -n 127.0.0.1 -p user.info "$(cat palo-alto.log)"
```

### Using Docker (Alpine NC)
```bash
# For rootless-syslog-ng (port 5514)
cat zscaler-sample.log | docker run -i --rm --network host ghcr.io/sva-s1/alpine-nc:latest /bin/ash -c "nc -u -w 1 127.0.0.1 5514"
```

## Adding Your Own Samples

When adding new sample files:

1. Use descriptive filenames: `vendor-product-sample.log`
2. Include parser information in comments or README
3. Ensure samples don't contain sensitive information
4. Test samples with the appropriate solution
5. Document the expected outcome in SentinelOne

## Sample File Format

Each sample should be a valid syslog message that can be sent directly to the syslog solutions. Examples:

```
# FortiGate format
<190>date=2023-12-01 time=10:30:45 devname="FortiGate-100E" devid="FG100E1234567890" logid="0000000013" type="traffic" subtype="forward" level="notice" ...

# Linux syslog format  
<134>Dec  1 10:30:45 ubuntu-server sshd[12345]: Accepted publickey for admin from 192.168.1.100 port 55432 ssh2

# Palo Alto format
<14>Dec 01 10:30:45 PA-VM TRAFFIC,1,2023/12/01 10:30:45,001801009999,TRAFFIC,end,2560,2023/12/01 10:30:45...
```

---

_These samples help verify that your syslog solution is working correctly and parsing logs as expected._