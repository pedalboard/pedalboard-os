# Pedalboard OS

Low latency Audio Operating system based on the open source ELK Audio OS.

## Hardware
* Raspberry Pi Compute Module 4, 4 GB RAM, 32GB eMMC, Wireless
* Waveshare [CM4 Nano A](https://www.waveshare.com/wiki/CM4-NANO-A)
* [HiFiBerry DAC+ADC](https://www.hifiberry.com/shop/boards/hifiberry-dac-adc-pro/)

## Configuration

The Pedalboard OS is based on [Elk Audio OS](https://elk-audio.github.io/elk-docs/html/index.html).

Since the open source version is only supported on Raspberry PI 4 (not the compute module),
some changes are requried and a custom Elk OS version (based v0.11.0) has to be build.

1. Upgrade the RPI firmware

The RPI firmware is not compatible with the CM4. Therfore it has to be updated:

```diff
--- a/recipes-bsp/common/raspberrypi-firmware.inc
+++ b/recipes-bsp/common/raspberrypi-firmware.inc
@@ -1,9 +1,9 @@
-RPIFW_DATE ?= "20210421"
-SRCREV ?= "2ac4de4eaac5c1d1b25acec4a5e0a9fdb16f0c91"
+RPIFW_DATE ?= "20230106"
+SRCREV ?= "78852e166b4cf3ebb31d051e996d54792f0994b0"
 RPIFW_SRC_URI ?= "https://github.com/raspberrypi/firmware/archive/${SRCREV}.tar.gz;downloadfilename=raspberrypi-firmware-${SRCREV}.tar.gz"
 RPIFW_S ?= "${WORKDIR}/firmware-${SRCREV}"

 SRC_URI = "${RPIFW_SRC_URI}"
-SRC_URI[sha256sum] = "c687aa1b5127a8dc0773e8aefb1f009f24bf71ccb4c9e8b40a1d46cbbb7bee0c"
+SRC_URI[sha256sum] = "d71b4a941b297b1327564dd22a9bf70bee885a38e206c54cebec91b4824e21d8"
```

2. Include the CM4 device tree

The local.conf file of the Yocto build has to be adapted:

```
RPI_KERNEL_DEVICETREE_remove = "broadcom/bcm2711-rpi-400.dtb broadcom/bcm2711-rpi-cm4.dtb"
```

Remove broadcom/bcm2711-rpi-cm4.dtb

3. Enable USB host

On the compute module USB host is disabled by default.

Add the following line to config.txt to enable it.

```
dtoverlay=dwc2,dr_mode=host
```

Enable HiFi Berry

```
sudo elk_system_utils --set-audio-hat hifiberry-dac-plus-adc-pro
```

Connect to WLAN

```
$ sudo connmanctl
# Now you should see a connmanctl shell where to type these extra commands:
$ connmanctl> agent on
$ connmanctl> scan wifi
$ connmanctl> services
# The last command should have showed you a list of WiFi network available with their SSID and a
# long code starting with wifi_
$ connmanctl> connect wifi_xxx # choose the code for the desired network. You can tab-complete.
$ connmanctl> Ctrl+D

# This will show you the IP address assigned to the board by DHCP
$ ip a
```

## Backup on OSX

1. run [usbbot](https://github.com/raspberrypi/usbboot)
2. find disk `diskutil list`
3. copy `sudo dd if=/dev/diskX of=backup/pedalboard-audio-20230129.dmg`
4. shrink the image with [pyshrink](https://github.com/lisanet/PiShrink-macOS)


