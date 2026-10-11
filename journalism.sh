#!/bin/bash
# Запускать от root: sudo bash journalism.sh

set -u   # не роняем скрипт на пустых переменных; без -e, чтобы ошибки одной команды не рушили весь блок

mkdir -p /root/logaudit

{
echo "=== СИСТЕМА ==="
hostname
date
echo

echo "=== disk-usage ==="
journalctl --disk-usage
echo

echo "=== list-boots ==="
journalctl --list-boots
echo

echo "=== -u NetworkManager ==="
journalctl -u NetworkManager --no-pager 2>/dev/null | head -20
echo

echo "=== -b ==="
journalctl -b --no-pager | head -20
echo

echo "=== -p err ==="
journalctl -p err --no-pager | head -20
echo

echo "=== -p warning --since '-1 hour' ==="
journalctl -p warning --since '-1 hour' --no-pager | head -20
echo

echo "=== _PID=1 ==="
journalctl _PID=1 --no-pager | head -20
echo

echo "=== /usr/bin/sudo ==="
journalctl /usr/bin/sudo --no-pager 2>/dev/null | head -20
echo

echo "=== -k ==="
journalctl -k --no-pager | head -20
echo

echo "=== -o json-pretty ==="
journalctl -n 1 -o json-pretty --no-pager
echo

echo "=== ls -ld ==="
ls -ld /var/log/journal 2>/dev/null || echo "/var/log/journal отсутствует"
ls -ld /run/log/journal  2>/dev/null || echo "/run/log/journal отсутствует"
} > /root/logaudit/01-journal.txt 2>&1

echo "Готово. Результат: /root/logaudit/01-journal.txt"
wc -l /root/logaudit/01-journal.txt
