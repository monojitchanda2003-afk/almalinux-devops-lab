#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo "=== $(date '+%F %T') ==="
echo "Disk:";   df -h / | tail -1
echo "Memory:"; free -m | awk '/Mem:/ {printf "%d%% used\n", $3/$2*100}'
echo "Load:";   uptime
for s in sshd nginx firewalld; do
  echo "$s: $(systemctl is-active $s)"
done
echo "SELinux: $(getenforce)"
