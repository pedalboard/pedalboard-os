# Pedalboard OS

Low latency Audio Operating system based on the open source ELK Audio OS.

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

1. Include the CM4 device tree

The local.conf file of the Yocto build has to be adapted:

```
RPI_KERNEL_DEVICETREE_remove = "broadcom/bcm2711-rpi-400.dtb broadcom/bcm2711-rpi-cm4.dtb"
```

Remove broadcom/bcm2711-rpi-cm4.dtb

1. Enable USB host

On the compute module USB host is disabled by default.

Add the following line to config.txt to enable it.

```
dtoverlay=dwc2,dr_mode=host
```


