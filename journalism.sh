#!/bin/sh

{
echo "=== disk-usage ==="
journalctl --disk-usage
echo "=== list-boots ==="
journalctl --list-boots
echo "=== -u NetworkManager ==="
journalctl -u NetworkManager --no-pager | head -20
echo "=== -b ==="
journalctl -b --no-pager | head -20
echo "=== -p err ==="
journalctl -p err --no-pager | head -20
echo "=== -p warning --since '-1 hour' ==="
journalctl -p warning --since '-1 hour' --no-pager | head -20
echo "=== _PID=1 ==="
journalctl _PID=1 --no-pager | head -20
echo "=== /usr/bin/sudo ==="
journalctl /usr/bin/sudo --no-pager | head -20
echo "=== -k ==="
journalctl -k --no-pager | head -20
echo "=== -o json-pretty ==="
journalctl -n 1 -o json-pretty --no-pager
echo "=== ls -ld ==="
ls -ld /var/log/journal /run/log/journal 2>/dev/null
} > /root/logaudit/01-journal.txt