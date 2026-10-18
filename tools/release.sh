#!/usr/bin/env bash
# Publie une Release GitHub a partir de la version de project.godot.
#
#   tools/release.sh [--dry-run] [--stable]
#
# Par defaut la Release est marquee « pre-release » (contenu pedagogique en
# brouillon). --dry-run fait toutes les verifications et construit les
# archives, sans tag ni publication. La cle de publication Android est lue
# dans ~/.config/aventuriers-des-mots/release.env (hors depot).
set -euo pipefail

cd "$(dirname "$0")/.."

DRY_RUN=0
PRERELEASE=1
for arg in "$@"; do
    case "${arg}" in
        --dry-run) DRY_RUN=1 ;;
        --stable) PRERELEASE=0 ;;
        *) echo "Option inconnue : ${arg}" >&2; exit 2 ;;
    esac
done

fail() { echo "ERREUR : $*" >&2; exit 1; }
trap 'echo "ERREUR : arret inattendu a la ligne ${LINENO} (code $?)" >&2' ERR

VERSION="$(sed -n 's/^config\/version="\(.*\)"/\1/p' project.godot)"
[ -n "${VERSION}" ] || fail "config/version absent de project.godot"
TAG="v${VERSION}"
RELEASE_ENV="${RELEASE_ENV:-${HOME}/.config/aventuriers-des-mots/release.env}"
DEBUG_CERT_DN="CN=Godot, OU=Godot Engine"

echo "== Verifications (${TAG}) =="
[ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || fail "la publication se fait depuis la branche main"
[ -z "$(git status --porcelain)" ] || fail "arbre de travail non propre : commiter d'abord"
git fetch -q origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || fail "main differe de origin/main : pousser ou tirer d'abord"
if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
    fail "le tag ${TAG} existe deja : incrementer config/version dans project.godot"
fi
[ -f "${RELEASE_ENV}" ] || fail "cle de publication absente (${RELEASE_ENV})"
if [ "${DRY_RUN}" -eq 0 ]; then
    gh auth status >/dev/null 2>&1 || fail "gh n'est pas authentifie (gh auth login)"
fi

echo "== make check =="
make check

echo "== make package =="
make package
[ -z "$(git status --porcelain)" ] || fail "make package a modifie le depot (versions des presets ?) : verifier puis commiter"

echo "== Controle des archives =="
ARCHIVES=(
    "dist/aventuriers-des-mots-${VERSION}-linux-x86_64.tar.gz"
    "dist/aventuriers-des-mots-${VERSION}-windows-x86_64.zip"
    "dist/aventuriers-des-mots-${VERSION}-android.zip"
    "dist/aventuriers-des-mots-${VERSION}-android-arm64.apk"
    "dist/aventuriers-des-mots-${VERSION}-macos-universal.zip"
    "dist/aventuriers-des-mots-${VERSION}-chromeos.zip"
)
for archive in "${ARCHIVES[@]}"; do
    [ -s "${archive}" ] || fail "archive manquante : ${archive}"
done
(cd dist && sha256sum -c SHA256SUMS >/dev/null) || fail "SHA256SUMS ne correspond pas aux archives"

# L'APK ne doit jamais etre signe avec la cle de debogage publique de Godot.
APKSIGNER="$(ls -d "${ANDROID_HOME:-${HOME}/Android/Sdk}"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1)"
[ -x "${APKSIGNER}" ] || fail "apksigner introuvable (Android SDK build-tools)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
CERTS="$("${APKSIGNER}" verify --print-certs "dist/aventuriers-des-mots-${VERSION}-android-arm64.apk")"
if grep -q "${DEBUG_CERT_DN}" <<<"${CERTS}"; then
    fail "l'APK est signe avec la cle de debogage Godot : verifier ${RELEASE_ENV}"
fi
echo "${CERTS}" | sed -n '1,2p'

NOTES="${TMP}/notes.md"
cat > "${NOTES}" <<NOTES
Les Aventuriers des mots ${VERSION}

**Version préliminaire.** Le contenu pédagogique est entièrement en brouillon
(\`review_status: draft\`) et en attente de validation par des enseignants ;
les voix des dictées sont provisoires (synthèse vocale).

| Plateforme | Archive | Testé à la main |
|---|---|---|
| Linux | \`linux-x86_64.tar.gz\` | oui |
| Android | \`android-arm64.apk\` (téléphones et tablettes ARM) ou \`android.zip\` (arm64 + x86_64, avec notice) | oui |
| Navigateur / ChromeOS | \`chromeos.zip\` (version web + APK) | web : oui |
| Windows | \`windows-x86_64.zip\` | non |
| macOS | \`macos-universal.zip\` | non |

Chaque archive contient un fichier LISEZMOI, la licence (AGPL-3.0) et les
crédits. Vérifier l'intégrité avec \`SHA256SUMS\`. Les exécutables ne sont pas
signés par un éditeur identifié : Windows SmartScreen et macOS Gatekeeper
demandent une confirmation au premier lancement.

L'APK est signé avec la clé de publication du projet : une mise à jour par
dessus une installation existante fonctionne.
NOTES

if [ "${DRY_RUN}" -eq 1 ]; then
    echo "== Simulation terminee : rien n'a ete tague ni publie =="
    echo "Commandes qui seraient lancees :"
    echo "  git tag -a ${TAG} -m 'Release ${VERSION}' && git push origin ${TAG}"
    echo "  gh release create ${TAG} dist/* $([ "${PRERELEASE}" -eq 1 ] && echo --prerelease)"
    exit 0
fi

echo "== Publication =="
git tag -a "${TAG}" -m "Release ${VERSION}"
git push origin "${TAG}"
gh release create "${TAG}" \
    "${ARCHIVES[@]}" dist/SHA256SUMS \
    --title "Les Aventuriers des mots ${VERSION}" \
    --notes-file "${NOTES}" \
    $([ "${PRERELEASE}" -eq 1 ] && echo --prerelease)
echo "Publie : $(gh release view "${TAG}" --json url -q .url)"
