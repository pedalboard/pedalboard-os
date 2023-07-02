# Pedalboard OS

Low latency Audio Operating system based on the open source ELK Audio OS.

## Hardware
* Raspberry Pi Compute Module 4, 4 GB RAM, 32GB eMMC, Wireless
* Waveshare [CM4 Nano A](https://www.waveshare.com/wiki/CM4-NANO-A)
* [HiFiBerry DAC+ADC](https://www.hifiberry.com/shop/boards/hifiberry-dac-adc-pro/)

## Configuration

The Pedalboard OS is based on [Elk Audio OS](https://elk-audio.github.io/elk-docs/html/index.html).

Since v1.0.0 RPI CM4 is supported natively.

1. Enable USB host

On the compute module USB host is disabled by default.

Add the following line to config.txt to enable it.

```
dtoverlay=dwc2,dr_mode=host
```

2. Enable WiFi

- boot the board connected to LAN and ssh into it with `ssh mind@elk-pi`
- follow https://elk-audio.github.io/elk-docs/html/embedded/working_with_elk_board.html#over-wifi


3. Change hostname

```
sudo echo pedalboard > /etc/hostname
sudo reboot
ssh-copy-id mind@pedalboard
ssh mind@pedalboard
```

4. Install pedalboard software

Midi
```
sudo mkdir /mnt/pico
cd /udata
git clone https://github.com/pedalboard/pedalboard-midi.git
cd pedalboard-midi
```


Audio
```
cd /udata
git clone https://github.com/pedalboard/pedalboard-audio.git
cd pedalboard-audio
make install-plugins
make install
make restart
make status
```





## Backup on OSX

1. run [usbbot](https://github.com/raspberrypi/usbboot)
2. find disk `diskutil list`
3. copy `sudo dd if=/dev/diskX of=backup/pedalboard-audio-20230129.dmg`
4. shrink the image with [pyshrink](https://github.com/lisanet/PiShrink-macOS)


