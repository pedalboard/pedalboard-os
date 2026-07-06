.PHONY: install uninstall enable disable status help

.DEFAULT_GOAL := help

SERVICES = pedalboard-jack pedalboard-bridge
CONFIG_DIR = /etc/pedalboard

install: ## Install services and configuration
	@echo "Installing pedalboard services..."
	sudo cp pedalboard-jack.service /etc/systemd/system/
	sudo cp pedalboard-bridge.service /etc/systemd/system/
	sudo mkdir -p $(CONFIG_DIR)/models
	sudo cp env $(CONFIG_DIR)/env
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
