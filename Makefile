GODOT_BIN := .godot-bin/godot
VENV := .venv
GDLINT := $(VENV)/bin/gdlint
GDFORMAT := $(VENV)/bin/gdformat
PYRIGHT := $(VENV)/bin/pyright
PYTHON := $(VENV)/bin/python3
GD_SOURCES := autoload scripts tests

.DEFAULT_GOAL := help

.PHONY: serve-web help setup import run lint format validate-data test check content-review generate-dictation-audio generate-sounds export-linux export-windows export-android export-macos export-web package screenshot

# Liste les commandes : toute cible suivie de « ## description » y figure.
help: ## Affiche cette aide
	@echo "Les Aventuriers des mots - commandes disponibles :"
	@grep -E '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "} {printf "  make %-26s %s\n", $$1, $$2}'

setup: ## Installe l'outillage (Godot, modeles d'export, lint, tests)
	tools/setup.sh

# Importe les ressources (polices, SVG, audio...) dans .godot/. Indispensable
# sur un depot fraichement clone : sans cela, l'export plante ou produit un
# jeu sans theme. Deux passes : le theme n'est valide qu'une fois les polices
# importees. La premiere passe peut echouer (theme charge avant les polices) :
# son code de retour est ignore, la seconde fait foi.
import: ## Importe les ressources dans .godot/ (deux passes)
	-@$(GODOT_BIN) --headless --path . --import >/dev/null 2>&1
	$(GODOT_BIN) --headless --path . --import >/dev/null

run: import ## Lance le jeu
	$(GODOT_BIN) --path .

lint: ## Analyse statique (gdlint, pyright)
	$(GDLINT) $(GD_SOURCES)
	$(PYRIGHT) tools/

format: ## Formate le GDScript
	$(GDFORMAT) $(GD_SOURCES)

validate-data: import ## Valide les JSON de data/ contre leurs schemas
	$(GODOT_BIN) --headless --path . -s res://scripts/data/validate_data_cli.gd

test: import ## Lance les tests en mode headless
	$(GODOT_BIN) --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit

check: lint validate-data test ## lint + validate-data + test (avant chaque commit)

content-review: ## Regenere docs/review/content-review.md
	$(PYTHON) tools/generate_content_review.py

generate-dictation-audio: ## Genere l'audio provisoire des dictees (Piper)
	$(PYTHON) tools/generate_dictation_audio.py

generate-sounds: ## Genere les effets sonores et musiques
	$(PYTHON) tools/generate_sounds.py

export-linux: import ## Exporte la version Linux dans build/
	mkdir -p build/linux
	$(GODOT_BIN) --headless --path . --export-release "Linux" build/linux/aventuriers_des_mots.x86_64

export-windows: import ## Exporte la version Windows dans build/
	mkdir -p build/windows
	$(GODOT_BIN) --headless --path . --export-release "Windows" build/windows/aventuriers_des_mots.exe

package: ## Reexporte tout et produit les archives dans dist/
	tools/package.sh

# Capture d'une scene dans une vraie fenetre (voir tools/screenshot.gd) :
#   make screenshot SCENE=res://scenes/world/world_map.tscn OUT=/tmp/map.png ARGS="CE2"
screenshot: import ## Capture une scene (SCENE=... OUT=... ARGS=...)
	$(GODOT_BIN) --path . -s res://tools/screenshot.gd -- $(SCENE) $(OUT) $(ARGS)

# Android : APK unique (arm64 + x86_64, donc aussi les Chromebooks). Signature
# de test avec la cle de debogage de Godot (standard, publique) : aucune cle
# privee dans le depot. Pour publier sur un magasin, fournir sa propre cle via
# GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD.
ANDROID_DEBUG_KEYSTORE ?= $(HOME)/.local/share/godot/keystores/debug.keystore

export-android: import ## Exporte l'APK Android / ChromeOS dans build/android/
	mkdir -p build/android
	GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-$(ANDROID_DEBUG_KEYSTORE)}" \
	GODOT_ANDROID_KEYSTORE_RELEASE_USER="$${GODOT_ANDROID_KEYSTORE_RELEASE_USER:-androiddebugkey}" \
	GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:-android}" \
	$(GODOT_BIN) --headless --path . --export-release "Android" build/android/aventuriers_des_mots.apk

export-macos: import ## Exporte l'application macOS (zip) dans build/macos/
	mkdir -p build/macos
	$(GODOT_BIN) --headless --path . --export-release "macOS" build/macos/aventuriers_des_mots.zip

export-web: import ## Exporte la version Web (navigateur, ChromeOS) dans build/web/
	mkdir -p build/web
	$(GODOT_BIN) --headless --path . --export-release "Web" build/web/index.html

serve-web: export-web ## Exporte puis sert la version web en local et ouvre le navigateur
	$(PYTHON) tools/serve_web.py build/web
