# Pedalboard OS

System configuration for the Open Pedalboard audio+MIDI platform running on Raspberry Pi CM5.

**Stack:** Debian Bookworm + JACK + AIDA-X + mod-host + pedalboard-bridge

## Hardware

- Raspberry Pi CM5 with Debian Bookworm
- Pedalboard soundcard (PCM1863 ADC + PCM5242 DAC) via I2S
- Pedalboard MIDI controller (RP2040) via USB

## Fresh install

### 1. Install audio dependencies (once, takes ~10 min on CM5)

```bash
git clone https://github.com/pedalboard/pedalboard-os.git
cd pedalboard-os
make deps
```

### 2. Deploy latest release

```bash
make deploy
```

This downloads and installs:
- `pedalboard-os.deb` — systemd units, udev rules, config files, AIDA-X models
- `pedalboard-bridge` — the Rust JACK MIDI + audio switching service (arm64 binary)

### 3. Enable and start

```bash
make enable
sudo reboot
```

## Updating

```bash
cd ~/projects/pedalboard-os && git pull && make deploy
```

One command — downloads the latest release of both the OS config and bridge binary,
installs them, and restarts the bridge service.

## Services

| Service | Description |
|---------|-------------|
| `pedalboard-jack` | JACK audio+MIDI server (48kHz, 64 frames) |
| `pedalboard-modhost` | mod-host LV2 plugin host |
| `pedalboard-bridge` | JACK MIDI + WebSocket + audio patch switching |
| `pedalboard-modui` | MOD UI web plugin editor (studio mode only) |

## Operating modes

The system supports two modes switchable at runtime without rebooting:

| Mode | Trigger | Services |
|------|---------|----------|
| **Studio** | Default / A+F 3s | Full stack — audio + SSH + WiFi + MOD UI |
| **Gig** | A+F held 3s | Audio only — SSH, WiFi, MOD UI stopped |

Switch via controller (hold buttons A+F for 3 seconds) or CLI:

```bash
pedalboard-cli mode gig
pedalboard-cli mode studio
```

Or directly via HTTP (works even when WiFi is down in gig mode, use IP):

```bash
curl -X POST http://192.168.1.166:8080/mode?set=studio
```

## Configuration

```
/etc/pedalboard/
├── env                   # AUDIO_CARD, MIDI_MATCH, BRIDGE_PORT
├── audio-patches.json    # Audio plugin chain configuration
├── mod-hardware-descriptor.json
└── models/               # AIDA-X neural amp models (.json)
```

`/etc/pedalboard/env` is a conffile — preserved on package upgrades.

## Local development

```bash
make dev
```

Starts everything in Docker:

| Service | URL |
|---------|-----|
| Bridge | http://localhost:8080 |
| Simulator | http://localhost:3001 |
| MOD UI | http://localhost:8888 |

```bash
make dev-down   # stop
make e2e        # end-to-end tests
```

## Manual checks (on CM5)

```bash
make status                        # service status
jack_lsp -c                        # JACK connections
curl http://localhost:8080/        # bridge status
```

## License

[GPL-3.0](LICENSE)
