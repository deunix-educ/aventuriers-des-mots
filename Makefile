GODOT_BIN := .godot-bin/godot
VENV := .venv
GDLINT := $(VENV)/bin/gdlint
GDFORMAT := $(VENV)/bin/gdformat
PYRIGHT := $(VENV)/bin/pyright
PYTHON := $(VENV)/bin/python3
GD_SOURCES := autoload scripts tests

.DEFAULT_GOAL := help

.PHONY: android-template export-play release release-dry-run serve-web help setup import run lint format validate-data test check content-review generate-dictation-audio generate-sounds export-linux export-windows export-android export-macos export-web package screenshot

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

# Android : APK unique (arm64 + x86_64, donc aussi les Chromebooks). La cle de
# publication (hors depot) est lue dans RELEASE_ENV : trois variables
# GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD. Sans ce fichier, repli
# sur la cle de debogage publique de Godot : acceptable pour un essai local,
# jamais pour une publication (tools/release.sh le refuse).
RELEASE_ENV ?= $(HOME)/.config/aventuriers-des-mots/release.env
ANDROID_DEBUG_KEYSTORE ?= $(HOME)/.local/share/godot/keystores/debug.keystore

export-android: import ## Exporte l'APK Android / ChromeOS dans build/android/
	mkdir -p build/android
	set -a; [ -f "$(RELEASE_ENV)" ] && . "$(RELEASE_ENV)"; set +a; \
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

release: ## Publie une pre-release GitHub (STABLE=1 pour une version stable)
	tools/release.sh $(if $(STABLE),--stable,)

release-dry-run: ## Verifie tout et construit les archives sans rien publier
	tools/release.sh --dry-run

# Modele de projet Android (Gradle), requis pour l'App Bundle de Google Play.
# Extrait des modeles d'export de la version Godot pinnee ; android/ n'est pas
# versionne (regenerable, 200 Mo).
GODOT_TEMPLATE_DIR := $(HOME)/.local/share/godot/export_templates/$(subst -,.,$(shell cat .godot-version))

android-template: ## Installe le modele Gradle Android (android/build) pour Google Play
	@if [ "$$(cat android/.build_version 2>/dev/null)" != "$(subst -,.,$(shell cat .godot-version))" ]; then \
		rm -rf android; mkdir -p android/build; \
		unzip -q "$(GODOT_TEMPLATE_DIR)/android_source.zip" -d android/build; \
		printf '%s' "$(subst -,.,$(shell cat .godot-version))" > android/.build_version; \
	fi

export-play: import android-template ## Exporte l'App Bundle (.aab) pour Google Play dans build/play/
	@[ -f "$(RELEASE_ENV)" ] || { echo "ERREUR : cle de publication absente ($(RELEASE_ENV))" >&2; exit 1; }
	mkdir -p build/play
	set -a; . "$(RELEASE_ENV)"; set +a; \
	$(GODOT_BIN) --headless --path . --export-release "Android Play" build/play/aventuriers_des_mots.aab
