GODOT_BIN := .godot-bin/godot
VENV := .venv
GDLINT := $(VENV)/bin/gdlint
GDFORMAT := $(VENV)/bin/gdformat
GD_SOURCES := autoload scripts tests

.PHONY: setup run lint format validate-data test check export-linux export-windows

setup:
	tools/setup.sh

run:
	$(GODOT_BIN) --path .

lint:
	$(GDLINT) $(GD_SOURCES)

format:
	$(GDFORMAT) $(GD_SOURCES)

validate-data:
	$(GODOT_BIN) --headless --path . -s res://scripts/data/validate_data_cli.gd

test:
	$(GODOT_BIN) --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

check: lint validate-data test

export-linux:
	@echo "Export Linux : pas encore configure (voir Ordre de construction, etape 6)."
	@exit 1

export-windows:
	@echo "Export Windows : pas encore configure (voir Ordre de construction, etape 6)."
	@exit 1
