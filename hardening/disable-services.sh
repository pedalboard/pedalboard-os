#!/bin/bash
# Disable unnecessary services for live pedalboard use.
# Run on CM5 as root (or with sudo).
set -e

echo "=== Disabling unnecessary system services ==="

# Bluetooth (not needed for pedalboard)
systemctl disable --now bluetooth.service hciuart.service 2>/dev/null || true

# Modem manager (no cellular hardware)
systemctl disable --now ModemManager.service 2>/dev/null || true

# Printing (no printers on a pedalboard)
systemctl disable --now cups.service cups-browsed.service 2>/dev/null || true

# Display manager (headless operation)
systemctl disable --now lightdm.service 2>/dev/null || true

# Desktop services (not needed headless)
systemctl disable --now accounts-daemon.service 2>/dev/null || true
systemctl disable --now udisks2.service 2>/dev/null || true
systemctl disable --now colord.service 2>/dev/null || true
systemctl disable --now triggerhappy.service 2>/dev/null || true
systemctl disable --now glamor-test.service 2>/dev/null || true
systemctl disable --now rp1-test.service 2>/dev/null || true
systemctl disable --now rpi-display-backlight.service 2>/dev/null || true
systemctl disable --now wayvnc-control.service 2>/dev/null || true

# Avahi (mDNS discovery — disable if not using .local hostname)
# Keep enabled: useful for cm5-dev.home resolution
# systemctl disable --now avahi-daemon.service 2>/dev/null || true

# Swap file (audio RT should never swap)
systemctl disable --now dphys-swapfile.service 2>/dev/null || true
swapoff -a 2>/dev/null || true

echo "=== Disabling PipeWire/PulseAudio user services ==="
# Mask globally for all users (survives reboot without linger)
systemctl --global disable pipewire.service pipewire-pulse.service wireplumber.service 2>/dev/null || true
systemctl --global mask pipewire.service pipewire-pulse.service wireplumber.service 2>/dev/null || true

echo "Done. Disabled services will not start on next boot."
