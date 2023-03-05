

download:
	mkdir -p images
	rsync -P -avh christof@yocto-build:/home/christof/pedalboard-os/yocto/build/tmp/deploy/images/raspberrypi4-64/*.wic.bz2 images/


