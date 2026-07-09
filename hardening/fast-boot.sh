#!/bin/bash
# Fast boot optimizations for CM5 pedalboard.
# Reduces boot time by removing splash, wait-online, and unnecessary delays.
set -e

CMDLINE="/boot/firmware/cmdline.txt"

echo "=== Fast boot: kernel command line ==="
# Remove splash, add quiet + fastboot
if [ -f "$CMDLINE" ]; then
  sed -i 's/ splash//g' "$CMDLINE"
  sed -i 's/ plymouth.ignore-serial-consoles//g' "$CMDLINE"
  # Add loglevel=3 if not already present (reduce kernel verbosity)
  grep -q 'loglevel=' "$CMDLINE" || sed -i 's/$/ loglevel=3/' "$CMDLINE"
  echo "  cmdline.txt updated: $(cat $CMDLINE)"
fi

echo "=== Fast boot: disable wait-online ==="
systemctl disable --now NetworkManager-wait-online.service 2>/dev/null || true

echo "=== Fast boot: disable kernel splash ==="
# Remove plymouth if installed (text-mode boot is faster)
apt-get remove -y -qq plymouth 2>/dev/null || true

echo "=== Fast boot: disable console blanking ==="
# Prevent console blank timeout (irrelevant headless, saves a service)
systemctl mask console-setup.service 2>/dev/null || true

echo "Done. Reboot to apply kernel cmdline changes."
