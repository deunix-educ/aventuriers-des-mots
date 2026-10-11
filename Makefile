GODOT_BIN := .godot-bin/godot
VENV := .venv
GDLINT := $(VENV)/bin/gdlint
GDFORMAT := $(VENV)/bin/gdformat
PYRIGHT := $(VENV)/bin/pyright
PYTHON := $(VENV)/bin/python3
GD_SOURCES := autoload scripts tests

.PHONY: setup run lint format validate-data test check content-review generate-dictation-audio generate-sounds export-linux export-windows package screenshot

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

generate-dictation-audio:
	$(PYTHON) tools/generate_dictation_audio.py

generate-sounds:
	$(PYTHON) tools/generate_sounds.py

export-linux:
	mkdir -p build/linux
	$(GODOT_BIN) --headless --path . --export-release "Linux" build/linux/aventuriers_des_mots.x86_64

export-windows:
	mkdir -p build/windows
	$(GODOT_BIN) --headless --path . --export-release "Windows" build/windows/aventuriers_des_mots.exe

package:
	tools/package.sh

# Capture d'une scene dans une vraie fenetre (voir tools/screenshot.gd) :
#   make screenshot SCENE=res://scenes/world/world_map.tscn OUT=/tmp/map.png ARGS="CE2"
screenshot:
	$(GODOT_BIN) --path . -s res://tools/screenshot.gd -- $(SCENE) $(OUT) $(ARGS)
