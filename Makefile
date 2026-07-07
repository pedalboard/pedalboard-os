.PHONY: install uninstall enable disable status help

.DEFAULT_GOAL := help

SERVICES = pedalboard-jack pedalboard-modhost pedalboard-bridge
CONFIG_DIR = /etc/pedalboard

deps: ## Install all audio dependencies (JACK, mod-host, plugins, AIDA-X)
	sudo apt-get update -qq
	sudo apt-get install -y -qq jackd2 liblilv-dev libreadline-dev libfftw3-dev libjack-jackd2-dev lilv-utils calf-plugins x42-plugins
	@echo "Building mod-host from source..."
	cd /tmp && rm -rf mod-host && git clone https://github.com/mod-audio/mod-host.git && cd mod-host && make -j4 && sudo make install
	@echo "Building AIDA-X from source..."
	cd /tmp && rm -rf AIDA-X && git clone --recursive https://github.com/AidaDSP/AIDA-X.git && cd AIDA-X && cmake -B build -DCMAKE_BUILD_TYPE=Release && cd build && make -j4
	sudo cp -r /tmp/AIDA-X/build/bin/AIDA-X.lv2 /usr/lib/lv2/
	@echo "All dependencies installed."

install: ## Install services and configuration
	@echo "Installing pedalboard services for user $(USER)..."
	sed 's/User=laenzi/User=$(USER)/' pedalboard-jack.service | sudo tee /etc/systemd/system/pedalboard-jack.service >/dev/null
	sed 's/User=laenzi/User=$(USER)/' pedalboard-modhost.service | sudo tee /etc/systemd/system/pedalboard-modhost.service >/dev/null
	sed 's/User=laenzi/User=$(USER)/' pedalboard-modui.service | sudo tee /etc/systemd/system/pedalboard-modui.service >/dev/null
	sed 's/User=laenzi/User=$(USER)/' pedalboard-bridge.service | sudo tee /etc/systemd/system/pedalboard-bridge.service >/dev/null
	sudo mkdir -p $(CONFIG_DIR)/models
	sudo cp env $(CONFIG_DIR)/env
	sudo cp mod-hardware-descriptor.json /etc/mod-hardware-descriptor.json
	sudo cp models/*.json $(CONFIG_DIR)/models/
	@if [ ! -f $(CONFIG_DIR)/audio-patches.json ]; then \
		sudo cp audio-patches.json $(CONFIG_DIR)/audio-patches.json; \
	else \
		echo "$(CONFIG_DIR)/audio-patches.json already exists, skipping"; \
	fi
	sudo systemctl daemon-reload
	@echo "Done. Run 'make enable' to start on boot."

uninstall: disable ## Remove services and configuration
	sudo rm -f /etc/systemd/system/pedalboard-jack.service
	sudo rm -f /etc/systemd/system/pedalboard-bridge.service
	sudo systemctl daemon-reload
	@echo "Services removed. Config left in $(CONFIG_DIR)."

enable: ## Enable and start services
	sudo systemctl enable --now $(addsuffix .service,$(SERVICES))

disable: ## Stop and disable services
	sudo systemctl disable --now $(addsuffix .service,$(SERVICES))

status: ## Show service status
	@systemctl status $(addsuffix .service,$(SERVICES)) --no-pager || true

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
