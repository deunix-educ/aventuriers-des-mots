#!/usr/bin/env bash
# Construit (et, avec --publish, publie) le depot F-Droid personnel du projet.
#
#   tools/fdroid_repo.sh [--publish]
#
# Etat local hors depot : ~/.local/share/aventuriers-des-mots/fdroid/ (APK
# accumules, index signe). La cle du depot (distincte de la cle de signature
# des APK) et son mot de passe sont crees au premier lancement :
#   ~/.local/share/aventuriers-des-mots/fdroid-repo.keystore
#   ~/.config/aventuriers-des-mots/fdroid.env   (droits 600)
# Publication : branche orpheline gh-pages (force-push, sans historique) servie
# par GitHub Pages sur https://deunix-educ.github.io/aventuriers-des-mots/fdroid/repo
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

PUBLISH=0
[ "${1:-}" = "--publish" ] && PUBLISH=1

fail() { echo "ERREUR : $*" >&2; exit 1; }

APP_ID="org.deunix.aventuriersdesmots"
DATA="${HOME}/.local/share/aventuriers-des-mots"
CONF="${HOME}/.config/aventuriers-des-mots"
KEYSTORE="${DATA}/fdroid-repo.keystore"
ENV_FILE="${CONF}/fdroid.env"
STATE="${DATA}/fdroid"
SDK="${ANDROID_HOME:-${HOME}/Android/Sdk}"
FDROID="${ROOT}/.venv/bin/fdroid"
KEEP=3

[ -x "${FDROID}" ] || fail "fdroidserver absent : lancer make setup"
[ -d "${SDK}/build-tools" ] || fail "Android SDK introuvable (${SDK})"

VERSION="$(sed -n 's/^config\/version="\(.*\)"/\1/p' project.godot)"
APK="dist/aventuriers-des-mots-${VERSION}-android-arm64.apk"
[ -f "${APK}" ] || fail "${APK} absent : lancer make package"

# Cle du depot, creee une seule fois. A SAUVEGARDER : la perdre oblige les
# utilisateurs a retirer puis rajouter le depot.
if [ ! -f "${KEYSTORE}" ]; then
    mkdir -p "${DATA}" "${CONF}"
    chmod 700 "${DATA}" "${CONF}"
    PASS="$(python3 -c "import secrets,string;print(''.join(secrets.choice(string.ascii_letters+string.digits) for _ in range(32)))")"
    keytool -genkeypair -keystore "${KEYSTORE}" -alias aventuriers-repo \
        -keyalg RSA -keysize 4096 -validity 10000 -storepass "${PASS}" -keypass "${PASS}" \
        -dname "CN=Les Aventuriers des mots (depot), O=deunix-educ, C=FR" >/dev/null 2>&1
    chmod 600 "${KEYSTORE}"
    (umask 077; printf 'FDROID_KEYSTORE_PASS=%s\n' "${PASS}" > "${ENV_FILE}")
    echo "Cle du depot creee : ${KEYSTORE} (a sauvegarder hors de la machine)"
fi
# shellcheck disable=SC1090
. "${ENV_FILE}"

mkdir -p "${STATE}/repo" "${STATE}/metadata"
cp "${APK}" "${STATE}/repo/"
cp fastlane/metadata/android/fr-FR/images/icon.png "${STATE}/icon.png"
rm -f "${STATE}/repo/icons/icon.png"
# Ne garder que les KEEP versions les plus recentes.
mapfile -t OLD < <(ls -1 "${STATE}"/repo/aventuriers-des-mots-*-android-arm64.apk | sort -V | head -n -"${KEEP}")
for old in "${OLD[@]}"; do rm -f "${old}"; done

sed -e "s|@SDK@|${SDK}|" -e "s|@KEYSTORE@|${KEYSTORE}|" -e "s|@PASS@|${FDROID_KEYSTORE_PASS}|" \
    fdroid/config.template.yml > "${STATE}/config.yml"
chmod 600 "${STATE}/config.yml"

# Metadonnees : fiche yml + textes et images localises (memes que fastlane).
cp "fdroid/metadata/${APP_ID}.yml" "${STATE}/metadata/"
rm -rf "${STATE}/metadata/${APP_ID}"
mkdir -p "${STATE}/metadata/${APP_ID}"
cp -r fastlane/metadata/android/fr-FR "${STATE}/metadata/${APP_ID}/"

(cd "${STATE}" && ANDROID_HOME="${SDK}" "${FDROID}" update --create-metadata --pretty)

FPR="$(keytool -list -keystore "${KEYSTORE}" -storepass "${FDROID_KEYSTORE_PASS}" 2>/dev/null \
    | sed -n 's/.*SHA-256) *: *//p;s/^Empreinte du certificat (SHA-256) *: *//p' | head -1)"
echo
echo "Depot construit : ${STATE}/repo"
echo "Empreinte de la cle du depot (SHA-256) : ${FPR}"
echo "Adresse du depot : https://deunix-educ.github.io/aventuriers-des-mots/fdroid/repo"

[ "${PUBLISH}" -eq 1 ] || { echo "(simulation : rien n'est publie ; --publish pour publier)"; exit 0; }

echo "== Publication sur la branche gh-pages =="
[ -z "$(git status --porcelain)" ] || fail "arbre de travail non propre"
REMOTE_URL="$(git remote get-url origin)"
PUB="$(mktemp -d)"
trap 'rm -rf "${PUB}"' EXIT
# Le client F-Droid attend une adresse se terminant par /fdroid/repo.
mkdir -p "${PUB}/fdroid"
cp -r "${STATE}/repo" "${PUB}/fdroid/repo"
cat > "${PUB}/index.html" <<'HTML'
<!doctype html><meta charset="utf-8"><title>Les Aventuriers des mots - dépôt F-Droid</title>
<meta http-equiv="refresh" content="0; url=fdroid/repo/">
<a href="fdroid/repo/">Dépôt F-Droid de Les Aventuriers des mots</a>
HTML
touch "${PUB}/.nojekyll"
(
    cd "${PUB}"
    git init -q -b gh-pages
    git add -A
    git -c user.name="$(git -C "${ROOT}" config user.name)" -c user.email="$(git -C "${ROOT}" config user.email)" \
        commit -q -m "F-Droid repository ${VERSION}"
    git push -q -f "${REMOTE_URL}" gh-pages
)
echo "Publie : branche gh-pages. Activer GitHub Pages (Settings > Pages > gh-pages) si ce n'est pas fait."
