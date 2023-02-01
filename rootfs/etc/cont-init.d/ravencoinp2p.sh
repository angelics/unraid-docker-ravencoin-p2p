#!/bin/sh
#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

# Make sure some directories are created.
mkdir -p /storage/.raven

# check conf
grep -q "server=1" /storage/.raven/raven.conf || echo 'server=1' >> /storage/.raven/raven.conf

# Generate machine id.
log "generating machine-id..."
cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id

# Take ownership of the config directory content.
find /storage/.raven -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# vim: set ft=sh :