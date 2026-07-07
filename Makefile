.PHONY: install uninstall enable disable status help deps dev dev-live dev-down curate

.DEFAULT_GOAL := help

SERVICES = pedalboard-jack pedalboard-modhost pedalboard-bridge
CONFIG_DIR = /etc/pedalboard

deps: ## Install all audio dependencies (JACK, mod-host, plugins, AIDA-X)
	sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq jackd2 liblilv-dev libreadline-dev libfftw3-dev libjack-jackd2-dev lilv-utils
	@echo "Installing LV2 plugins (curated for guitar pedalboard)..."
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq calf-plugins guitarix-lv2 x42-plugins
	@echo "Installing MOD UI dependencies..."
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3 python3-pip python3-pil python3-numpy
	sudo pip3 install --break-system-packages 'tornado==4.5.3'
	@echo "Building mod-host from source..."
	cd /tmp && rm -rf mod-host && git clone https://github.com/mod-audio/mod-host.git && cd mod-host && make -j$$(nproc) && sudo make install
	@echo "Building AIDA-X (headless LV2) from source..."
	cd /tmp && rm -rf aidadsp-lv2 && git clone --depth 1 --recursive https://github.com/AidaDSP/aidadsp-lv2.git \
		&& cd aidadsp-lv2 && cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j$$(nproc)
	sudo mkdir -p /usr/lib/lv2/rt-neural-generic.lv2/modgui
	sudo cp /tmp/aidadsp-lv2/build/rt-neural-generic/rt-neural-generic.so /usr/lib/lv2/rt-neural-generic.lv2/
	sudo cp /tmp/aidadsp-lv2/rt-neural-generic/ttl/*.ttl /usr/lib/lv2/rt-neural-generic.lv2/
	sudo cp -r /tmp/aidadsp-lv2/rt-neural-generic/ttl/modgui/* /usr/lib/lv2/rt-neural-generic.lv2/modgui/
	@echo "Installing MOD UI..."
	@if [ ! -d /opt/mod-ui ]; then \
		sudo git clone --depth 1 https://github.com/mod-audio/mod-ui.git /opt/mod-ui; \
	fi
	@echo "Patching for Python 3.11 + Tornado 4.5 compatibility..."
	sudo sed -i '1s/^/import collections.abc\nimport collections\ncollections.MutableMapping = collections.abc.MutableMapping\ncollections.Callable = collections.abc.Callable\n/' /opt/mod-ui/server.py
	cd /opt/mod-ui/utils && make
	@echo "Installing MOD plugin GUIs..."
	cd /tmp && rm -rf mod-lv2-data && git clone --depth 1 https://github.com/moddevices/mod-lv2-data.git \
		&& for dir in /usr/lib/lv2/*.lv2; do \
			name=$$(basename $$dir); \
			if [ -d /tmp/mod-lv2-data/plugins-fixed/$$name/modgui ]; then \
				sudo cp -r /tmp/mod-lv2-data/plugins-fixed/$$name/modgui $$dir/; \
				sudo cp /tmp/mod-lv2-data/plugins-fixed/$$name/*.ttl $$dir/ 2>/dev/null || true; \
			elif [ -d /tmp/mod-lv2-data/plugins/$$name/modgui ]; then \
				sudo cp -r /tmp/mod-lv2-data/plugins/$$name/modgui $$dir/; \
				sudo cp /tmp/mod-lv2-data/plugins/$$name/*.ttl $$dir/ 2>/dev/null || true; \
			fi; \
		done && rm -rf /tmp/mod-lv2-data
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

# LV2 bundles to keep (curated for guitar pedalboard)
LV2_KEEP = calf.lv2 rt-neural-generic.lv2 \
	gxts9.lv2 gx_bmp.lv2 gx_aclipper.lv2 gx_fuzz.lv2 gx_fumaster.lv2 \
	gx_compressor.lv2 gx_mbreverb.lv2 gx_chorus.lv2 gx_tremolo.lv2 \
	gx_flanger.lv2 gx_phaser.lv2 gx_delay.lv2 gx_digital_delay.lv2 \
	gx_echo.lv2 gx_reverb.lv2 gx_cabinet.lv2 gx_amp.lv2 \
	gxtuner.lv2 gxbooster.lv2 gxechocat.lv2 \
	tuna.lv2 zeroconvo.lv2 fil4.lv2 darc.lv2

curate: ## Remove non-curated LV2 plugins (keeps only essentials)
	@echo "Removing non-curated plugins..."
	@cd /usr/lib/lv2 && for dir in *.lv2; do \
		keep=0; \
		for w in $(LV2_KEEP); do \
			[ "$$dir" = "$$w" ] && keep=1 && break; \
		done; \
		[ $$keep -eq 0 ] && [ -d "$$dir" ] && echo "  removing $$dir" && sudo rm -rf "$$dir" || true; \
	done
	@echo "Done. Kept $$(ls /usr/lib/lv2/*.lv2 -d 2>/dev/null | wc -l) plugin bundles."
