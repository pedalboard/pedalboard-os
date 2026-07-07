.PHONY: install uninstall enable disable status help deps dev dev-live dev-down

.DEFAULT_GOAL := help

SERVICES = pedalboard-jack pedalboard-modhost pedalboard-bridge
CONFIG_DIR = /etc/pedalboard

deps: ## Install all audio dependencies (JACK, mod-host, plugins, AIDA-X)
	sudo apt-get update -qq
	sudo apt-get install -y -qq jackd2 liblilv-dev libreadline-dev libfftw3-dev libjack-jackd2-dev lilv-utils
	@echo "Installing LV2 plugins (curated for guitar pedalboard)..."
	sudo apt-get install -y -qq calf-plugins guitarix-lv2 x42-plugins
	@echo "Installing MOD UI dependencies..."
	sudo apt-get install -y -qq python3 python3-pip python3-pil python3-numpy
	sudo pip3 install 'tornado>=4.3,<5'
	@echo "Building mod-host from source..."
	cd /tmp && rm -rf mod-host && git clone https://github.com/mod-audio/mod-host.git && cd mod-host && make -j$$(nproc) && sudo make install
	@echo "Building AIDA-X (headless LV2) from source..."
	cd /tmp && rm -rf aidadsp-lv2 && git clone --depth 1 --recursive https://github.com/AidaDSP/aidadsp-lv2.git \
		&& cd aidadsp-lv2 && cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr && cmake --build build -j$$(nproc)
	sudo cmake --install /tmp/aidadsp-lv2/build
	@echo "Installing MOD UI..."
	@if [ ! -d /opt/mod-ui ]; then \
		sudo git clone --depth 1 https://github.com/mod-audio/mod-ui.git /opt/mod-ui; \
	fi
	cd /opt/mod-ui/utils && make
	@echo "All dependencies installed."
	@echo ""
	@echo "Recommended plugins for guitar pedalboard:"
	@echo "  Amp:    AIDA-X (neural amp modeler)"
	@echo "  Drive:  GxTubeScreamer, GxBigMuffPi, GxRat"
	@echo "  Delay:  Calf Vintage Delay, Calf Reverse Delay"
	@echo "  Reverb: Calf Reverb, GxMultiBandReverb"
	@echo "  Mod:    Calf Flanger, GxChorus-Stereo, GxTremolo"
	@echo "  Util:   Calf Compressor, x42 Instrument Tuner"

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
	@if [ -d /opt/mod-ui/data ]; then \
		if [ ! -f /opt/mod-ui/data/favorites.json ] || [ "$$(cat /opt/mod-ui/data/favorites.json)" = "[]" ]; then \
			sudo cp mod-favorites.json /opt/mod-ui/data/favorites.json; \
		fi; \
	fi
	@if [ ! -f $(CONFIG_DIR)/audio-patches.json ]; then \
		sudo cp audio-patches.json $(CONFIG_DIR)/audio-patches.json; \
	else \
		echo "$(CONFIG_DIR)/audio-patches.json already exists, skipping"; \
	fi
	-sudo systemctl daemon-reload
	@echo "Done. Run 'make enable' to start on boot."

uninstall: disable ## Remove services and configuration
	sudo rm -f /etc/systemd/system/pedalboard-jack.service
	sudo rm -f /etc/systemd/system/pedalboard-bridge.service
	-sudo systemctl daemon-reload
	@echo "Services removed. Config left in $(CONFIG_DIR)."

enable: ## Enable and start services
	sudo systemctl enable --now $(addsuffix .service,$(SERVICES))

disable: ## Stop and disable services
	sudo systemctl disable --now $(addsuffix .service,$(SERVICES))

status: ## Show service status
	@systemctl status $(addsuffix .service,$(SERVICES)) --no-pager || true

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

dev: ## Run local test environment in Docker (MOD UI on localhost:8888)
	docker compose up --build

dev-live: ## Run local test environment in bridge/live mode (localhost:8080)
	MODE=live docker compose up --build

dev-down: ## Stop local test environment
	docker compose down
