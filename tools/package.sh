#!/usr/bin/env bash
# Produit les archives distribuables dans dist/ : un executable unique par
# plateforme (PCK embarque) + licence, credits et notice. Reexporte toujours
# depuis zero pour ne jamais empaqueter un build perime.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="$(sed -n 's/^config\/version="\(.*\)"/\1/p' project.godot)"
[ -n "${VERSION}" ] || { echo "config/version absent de project.godot" >&2; exit 1; }

rm -rf build dist
make export-linux export-windows >/dev/null

write_notice() {
    cat > "$1/LISEZMOI.txt" <<NOTICE
Les Aventuriers des mots ${VERSION}
Jeu éducatif de français CE1-CE2, hors ligne.

Lancer : $2
Aucune installation ni connexion Internet n'est nécessaire.

Les profils et la progression sont enregistrés localement :
  $3
Sauvegarder ce dossier suffit à conserver la progression.

Les voix des dictées sont provisoires (synthèse vocale) ; voir CREDITS.md.
Licence : GNU AGPL v3 (fichier LICENSE). Code source : voir README.md.
NOTICE
}

stage() {
    local name="$1" src="$2" launch="$3" saves="$4"
    local dir="dist/${name}"
    mkdir -p "${dir}"
    cp "${src}" "${dir}/"
    for doc in LICENSE README.md README-EN.md assets/CREDITS.md; do
        [ -s "${doc}" ] || { echo "${doc} est vide : paquet refuse" >&2; exit 1; }
    done
    cp LICENSE README.md README-EN.md "${dir}/"
    cp assets/CREDITS.md "${dir}/CREDITS.md"
    write_notice "${dir}" "${launch}" "${saves}"
}

LINUX="aventuriers-des-mots-${VERSION}-linux-x86_64"
WINDOWS="aventuriers-des-mots-${VERSION}-windows-x86_64"

stage "${LINUX}" build/linux/aventuriers_des_mots.x86_64 \
    "./aventuriers_des_mots.x86_64 (au besoin : chmod +x aventuriers_des_mots.x86_64)" \
    "~/.local/share/godot/app_userdata/Les Aventuriers des mots/"
stage "${WINDOWS}" build/windows/aventuriers_des_mots.exe \
    "double-clic sur aventuriers_des_mots.exe" \
    "%APPDATA%\\Godot\\app_userdata\\Les Aventuriers des mots\\"

(cd dist && tar czf "${LINUX}.tar.gz" "${LINUX}" && zip -qr "${WINDOWS}.zip" "${WINDOWS}")
(cd dist && sha256sum "${LINUX}.tar.gz" "${WINDOWS}.zip" > SHA256SUMS)
rm -rf "dist/${LINUX}" "dist/${WINDOWS}"
ls -lh dist
