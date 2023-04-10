.PHONY: help downlaod

.DEFAULT_GOAL := help

download: ## download the image from the build server
	mkdir -p images
	rsync -P -avh christof@yocto-build:/home/christof/pedalboard-os/yocto/build/tmp/deploy/images/raspberrypi4-64/*.wic.bz2 images/

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'



