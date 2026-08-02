#!/bin/bash
# Real-time audio optimizations for CM5 pedalboard.
# Run once as part of 'make harden'.
set -e

echo "=== CPU governor: performance ==="
# Prevent frequency scaling mid-performance which causes latency spikes.
if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
    echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    echo "  CPU governor set to performance"
    # Persist across reboots via a systemd-tmpfiles dropin
    cat > /etc/systemd/system/cpu-performance-governor.service << 'EOF'
[Unit]
Description=Set CPU governor to performance for RT audio
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable cpu-performance-governor.service
    echo "  Persisted via cpu-performance-governor.service"
else
    echo "  cpufreq not available (skipped)"
fi

echo "=== IRQ affinity: pin USB + I2S to core 0 ==="
# Keep cores 2+3 clean for JACK audio processing.
# USB IRQs (xhci_hcd) → core 0
for irq in $(grep xhci /proc/interrupts | awk -F: '{print $1}' | tr -d ' '); do
    echo 1 > /proc/irq/$irq/smp_affinity 2>/dev/null || true
done
# I2S/PCM IRQs → core 0
for irq in $(grep -E "i2s|pcm|hifiberry" /proc/interrupts | awk -F: '{print $1}' | tr -d ' '); do
    echo 1 > /proc/irq/$irq/smp_affinity 2>/dev/null || true
done
echo "  USB and I2S IRQs pinned to core 0"

echo "=== threadirqs kernel parameter ==="
# Forces hard IRQ handlers into threads, making them preemptible
# by JACK's RT thread. Add to cmdline.txt if not already present.
CMDLINE="/boot/firmware/cmdline.txt"
if [ -f "$CMDLINE" ]; then
    if ! grep -q "threadirqs" "$CMDLINE"; then
        sed -i 's/$/ threadirqs/' "$CMDLINE"
        echo "  Added threadirqs to cmdline.txt (reboot required)"
    else
        echo "  threadirqs already in cmdline.txt"
    fi
fi

echo "Done. Reboot to apply kernel parameter changes."
