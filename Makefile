GODOT_BIN := .godot-bin/godot
VENV := .venv
GDLINT := $(VENV)/bin/gdlint
GDFORMAT := $(VENV)/bin/gdformat
PYRIGHT := $(VENV)/bin/pyright
PYTHON := $(VENV)/bin/python3
GD_SOURCES := autoload scripts tests

.PHONY: setup run lint format validate-data test check content-review export-linux export-windows

setup:
	tools/setup.sh

run:
	$(GODOT_BIN) --path .

lint:
	$(GDLINT) $(GD_SOURCES)
	$(PYRIGHT) tools/

format:
	$(GDFORMAT) $(GD_SOURCES)

validate-data:
	$(GODOT_BIN) --headless --path . -s res://scripts/data/validate_data_cli.gd

test:
	$(GODOT_BIN) --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit

check: lint validate-data test

content-review:
	$(PYTHON) tools/generate_content_review.py

export-linux:
	@echo "Export Linux : pas encore configure (voir Ordre de construction, etape 6)."
	@exit 1

export-windows:
	@echo "Export Windows : pas encore configure (voir Ordre de construction, etape 6)."
	@exit 1
