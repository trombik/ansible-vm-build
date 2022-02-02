#!/bin/sh

set -e
set -x

sed -e 's/\(ttyv[^0].*getty.*\)on /\1off/' /etc/ttys | sudo tee /etc/ttys > /dev/null
echo 'firewall_enable="YES"' | sudo tee -a /etc/rc.conf
echo 'firewall_script="/etc/ipfw.conf"' | sudo tee -a /etc/rc.conf
sudo tee /etc/ipfw.conf <<'EOF'
fwcmd="/sbin/ipfw"
${fwcmd} -f flush
${fwcmd} check-state
${fwcmd} add 65000 pass all from any to any keep-state
EOF

sudo pkg install -y lang/python3 py38-ansible rsync

# when the release EoLed, or no update is available, freebsd-update exits with
# non-zero status.
sudo freebsd-update --not-running-from-cron fetch || true
if sudo freebsd-update --not-running-from-cron install && [ $? -ne 2 ]; then
    exit $?
fi
