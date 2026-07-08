# Pedalboard OS

System configuration for the Open Pedalboard audio+MIDI platform running on Raspberry Pi CM5.

**Stack:** Debian Bookworm + JACK + AIDA-X + mod-host + pedalboard-bridge

## Prerequisites

- Raspberry Pi CM5 with Debian Bookworm
- Pedalboard soundcard (PCM1863 ADC + PCM5242 DAC) connected via I2S
- Pedalboard MIDI controller (RP2040) connected via USB

## Install

```bash
git clone https://github.com/pedalboard/pedalboard-os.git
cd pedalboard-os
make install
sudo reboot
```

## Services

| Service | Description |
|---------|-------------|
| `pedalboard-jack` | JACK audio+MIDI server (hw:3, 48kHz, 64 frames) |
| `pedalboard-bridge` | JACK MIDI client + WebSocket + mod-host audio switching |

## Configuration

```
/etc/pedalboard/
├── audio-patches.json    # Audio plugin chain per preset
└── models/               # AIDA-X neural amp models
```

## Local Development

```bash
make dev
```

Starts everything in Docker:

| Service | URL | Description |
|---------|-----|-------------|
| Bridge | http://localhost:8080 | JACK MIDI → mod-host audio switching |
| Simulator | http://localhost:3001 | Virtual pedalboard (buttons, encoders, LEDs) |
| MOD UI | http://localhost:8888 | Visual plugin chain designer |

All connected via JACK MIDI inside the container. Press buttons in the simulator → bridge switches audio patches.

Switch between live/design mode: `POST http://localhost:8080/mode?set=live|design`

Use the CLI against the dev environment:

```bash
pedalboard-cli monitor    # watch MIDI (uses PEDALBOARD_ADDR from .mise.toml)
pedalboard-cli upload examples/practice.yaml
```

First run builds the simulator in a Rust container (cached after that).

### Stop

```bash
make dev-down
```

### End-to-end tests

```bash
make e2e
```

## Manual Testing (on CM5)

```bash
systemctl status pedalboard-jack pedalboard-bridge
jack_lsp -c            # show all JACK audio+MIDI connections
speaker-test -D hw:3 -c 2 -t sine -f 440 -s 2
```

## License

[GPL-3.0](LICENSE)
