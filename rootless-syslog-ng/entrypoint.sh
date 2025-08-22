#!/bin/sh
set -eu

# Template and output paths
TEMPLATE=/etc/syslog-ng/syslog-ng.conf.tmpl
RENDERED=/etc/syslog-ng/syslog-ng.conf

# Substitute only specific environment variables in the template
# This preserves syslog-ng variables like ${MSG}, ${PRI}, etc.
envsubst '$S1_INGEST_URL $S1_WRITE_TOKEN' < "$TEMPLATE" > "$RENDERED"

# Validate the configuration
/usr/sbin/syslog-ng -s -f "$RENDERED"

# Execute syslog-ng with the rendered config
exec "$@" -f "$RENDERED"
