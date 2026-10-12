#!/usr/bin/env bash
# Produit les archives distribuables dans dist/ : un executable unique par
# plateforme (PCK embarque) + licence, credits et notice. Reexporte toujours
# depuis zero pour ne jamais empaqueter un build perime.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="$(sed -n 's/^config\/version="\(.*\)"/\1/p' project.godot)"
[ -n "${VERSION}" ] || { echo "config/version absent de project.godot" >&2; exit 1; }

# Les presets d'export portent leur propre numero de version : on les aligne
# sur project.godot (version/code = major*10000 + minor*100 + patch).
IFS=. read -r V_MAJOR V_MINOR V_PATCH <<<"${VERSION}"
VERSION_CODE=$((V_MAJOR * 10000 + V_MINOR * 100 + V_PATCH))
sed -i \
    -e "s/^version\/name=.*/version\/name=\"${VERSION}\"/" \
    -e "s/^version\/code=.*/version\/code=${VERSION_CODE}/" \
    -e "s/^application\/short_version=.*/application\/short_version=\"${VERSION}\"/" \
    -e "s/^application\/version=.*/application\/version=\"${VERSION}\"/" \
    export_presets.cfg

rm -rf build dist
make export-linux export-windows export-android export-macos export-web >/dev/null

write_notice() {
    cat > "$1/LISEZMOI.txt" <<NOTICE
Les Aventuriers des mots ${VERSION}
Jeu éducatif de français CE1 à CM2, hors ligne.

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

ANDROID="aventuriers-des-mots-${VERSION}-android"
MACOS="aventuriers-des-mots-${VERSION}-macos-universal"
CHROMEOS="aventuriers-des-mots-${VERSION}-chromeos"

stage "${ANDROID}" build/android/aventuriers_des_mots.apk \
    "copier l'APK sur la tablette ou le téléphone, l'ouvrir et accepter l'installation depuis cette source (Android 7 ou plus ; arm64 et x86_64)" \
    "stockage privé de l'application (Réglages Android > Applications)"

# macOS : application non signée par un développeur identifié (signature ad hoc).
stage "${MACOS}" build/macos/aventuriers_des_mots.zip \
    "décompresser l'archive interne, puis clic droit > Ouvrir la première fois (application non notariée)" \
    "~/Library/Application Support/Godot/app_userdata/Les Aventuriers des mots/"
unzip -q "dist/${MACOS}/aventuriers_des_mots.zip" -d "dist/${MACOS}"
rm "dist/${MACOS}/aventuriers_des_mots.zip"

# ChromeOS : l'APK (runtime Android) ou la version Web servie en local.
stage "${CHROMEOS}" build/android/aventuriers_des_mots.apk \
    "soit installer l'APK (Chromebook avec Android activé), soit servir le dossier web/ (voir LISEZMOI-WEB.txt)" \
    "stockage privé de l'application, ou du navigateur pour la version web"
mkdir -p "dist/${CHROMEOS}/web"
cp build/web/* "dist/${CHROMEOS}/web/"
cp tools/serve_web.py "dist/${CHROMEOS}/lancer-web.py"
cat > "dist/${CHROMEOS}/lancer-web.sh" <<'LAUNCH'
#!/usr/bin/env bash
cd "$(dirname "$0")" && exec python3 lancer-web.py
LAUNCH
chmod +x "dist/${CHROMEOS}/lancer-web.sh"
printf '@echo off\r\ncd /d "%%~dp0"\r\npy lancer-web.py || python lancer-web.py\r\n' \
    > "dist/${CHROMEOS}/lancer-web.bat"
cat > "dist/${CHROMEOS}/LISEZMOI-WEB.txt" <<WEB
Version web (navigateur, hors ligne une fois servie localement)

Lancer : double-clic sur lancer-web.sh (Linux, macOS) ou lancer-web.bat
(Windows), ou en terminal : python3 lancer-web.py
Python 3 est nécessaire. Le navigateur s'ouvre sur le jeu ; cliquer une
fois dans la page pour activer le son. Ctrl+C dans le terminal arrête le
serveur.

La progression est conservée dans le stockage du navigateur : ne pas
effacer les données du site, et utiliser l'espace adulte pour exporter.
WEB

(cd dist && tar czf "${LINUX}.tar.gz" "${LINUX}" \
    && zip -qr "${WINDOWS}.zip" "${WINDOWS}" \
    && zip -qr "${ANDROID}.zip" "${ANDROID}" \
    && zip -qr "${MACOS}.zip" "${MACOS}" \
    && zip -qr "${CHROMEOS}.zip" "${CHROMEOS}")
(cd dist && sha256sum "${LINUX}.tar.gz" "${WINDOWS}.zip" "${ANDROID}.zip" \
    "${MACOS}.zip" "${CHROMEOS}.zip" > SHA256SUMS)
rm -rf "dist/${LINUX}" "dist/${WINDOWS}" "dist/${ANDROID}" "dist/${MACOS}" "dist/${CHROMEOS}"
ls -lh dist
