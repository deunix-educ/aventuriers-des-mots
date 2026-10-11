#!/usr/bin/env bash
# Installe l'outillage de developpement : binaire Godot pinne, addon GUT,
# environnement Python pour gdtoolkit. Rien de ceci n'est commite (voir .gitignore) :
# ce script est la seule source de verite pour reconstruire l'outillage.
set -euo pipefail

cd "$(dirname "$0")/.."

GODOT_VERSION="$(cat .godot-version)"
GODOT_BIN_DIR=".godot-bin"
GODOT_BIN="${GODOT_BIN_DIR}/godot"
GUT_VERSION="v9.6.0" # v9.6.1+ reference AccessibilityServer, absent de Godot 4.6.3
GDTOOLKIT_VERSION="4.5.0"

mkdir -p "${GODOT_BIN_DIR}"

if [ ! -x "${GODOT_BIN}" ]; then
    echo "Telechargement de Godot ${GODOT_VERSION}..."
    TMP_ZIP="$(mktemp)"
    curl -sL -o "${TMP_ZIP}" \
        "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
    unzip -o -j "${TMP_ZIP}" -d "${GODOT_BIN_DIR}"
    mv "${GODOT_BIN_DIR}/Godot_v${GODOT_VERSION}_linux.x86_64" "${GODOT_BIN}"
    chmod +x "${GODOT_BIN}"
    rm -f "${TMP_ZIP}"
else
    echo "Godot deja present dans ${GODOT_BIN}."
fi

if [ ! -d "addons/gut" ]; then
    echo "Telechargement de GUT ${GUT_VERSION}..."
    TMP_TAR="$(mktemp)"
    TMP_DIR="$(mktemp -d)"
    curl -sL -o "${TMP_TAR}" \
        "https://github.com/bitwes/Gut/archive/refs/tags/${GUT_VERSION}.tar.gz"
    tar xzf "${TMP_TAR}" -C "${TMP_DIR}"
    mkdir -p addons
    cp -r "${TMP_DIR}"/Gut-*/addons/gut addons/gut
    rm -rf "${TMP_TAR}" "${TMP_DIR}"
else
    echo "GUT deja present dans addons/gut."
fi

if [ ! -d ".venv" ]; then
    echo "Creation de l'environnement Python pour gdtoolkit..."
    python3 -m venv .venv
fi
./.venv/bin/pip install --quiet --upgrade pip
./.venv/bin/pip install --quiet "gdtoolkit==${GDTOOLKIT_VERSION}"

echo "Setup termine : Godot ${GODOT_VERSION}, GUT ${GUT_VERSION}, gdtoolkit ${GDTOOLKIT_VERSION}."
