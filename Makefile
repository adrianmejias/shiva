.PHONY: help update-fivem submodule-status submodule-sync submodule-link-add submodule-link-remove submodule-links-add submodule-links-remove

.DEFAULT_GOAL := help

ROOT := $(CURDIR)
BIN_DIR := $(ROOT)/bin
HELP_SCRIPT := $(BIN_DIR)/help.sh
SUBMODULES_SCRIPT := $(BIN_DIR)/submodules.sh
UPDATE_FIVEM_SCRIPT := $(BIN_DIR)/update-fivem.sh

DEFAULT_SUBMODULE_BRANCH ?= main
DEFAULT_SUBMODULE_UPDATE ?= rebase
UPDATE_FIVEM_ARGS ?=

# Default target
help:
	@bash "$(HELP_SCRIPT)"

update-fivem:
	@bash "$(UPDATE_FIVEM_SCRIPT)" $(if $(FIVEM_NUM),$(FIVEM_NUM),$(UPDATE_FIVEM_ARGS))

submodule-status:
	@bash "$(SUBMODULES_SCRIPT)" status

submodule-sync:
	@bash "$(SUBMODULES_SCRIPT)" sync

submodule-link-add:
	@bash "$(SUBMODULES_SCRIPT)" link-add "$(SUBMODULE_PATH)" "$(SUBMODULE_URL)" "$(SUBMODULE_BRANCH)" "$(SUBMODULE_UPDATE)"

submodule-link-remove:
	@bash "$(SUBMODULES_SCRIPT)" link-remove "$(SUBMODULE_PATH)"

submodule-links-add:
	@bash "$(SUBMODULES_SCRIPT)" links-add

submodule-links-remove:
	@bash "$(SUBMODULES_SCRIPT)" links-remove
