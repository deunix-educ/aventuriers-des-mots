# Distribuer l'application Android sans Google (F-Droid)

Google Play est écarté (frais de compte). Voies retenues, de la plus simple à la
plus lourde. Les règles des dépôts évoluent : confirmer sur leurs sites avant
toute demande.

## Ce que fournit le dépôt

- **L'APK seul dans chaque Release** : `aventuriers-des-mots-X.Y.Z-android-arm64.apk`
  (arm64 uniquement, environ 28 Mo, utilisé par le dépôt personnel), signé avec la
  clé de publication (`make release` vérifie la signature). L'APK
  arm64 + x86_64 reste dans `android.zip`.
- **Métadonnées de magasin** dans `fastlane/metadata/android/fr-FR/` : titre,
  descriptions courte et longue, icône 512 px, quatre captures d'écran, notes
  de version par `versionCode` (`changelogs/903.txt` pour la 0.9.3). C'est le
  format lu par F-Droid. Pour chaque nouvelle version, ajouter
  `changelogs/<versionCode>.txt` (`versionCode = major*10000 + minor*100 + patch`).
- Dossier `fastlane/` ignoré par Godot (`.gdignore`) et exclu des exports.
- Licences compatibles : code et illustrations AGPL-3.0, police OFL, voix CC BY
  4.0 (attribution dans `assets/CREDITS.md`), aucun traqueur, aucune permission
  Internet.

## Voie 1 : dépôt IzzyOnDroid (refusée)

La demande d'inclusion déposée (octobre 2026) a reçu une réponse négative
(motif à consigner ici s'il est communiqué). Leur politique mentionne le rejet
des applications « vibe-coded » et un plafond de 30 Mo par APK ; le projet est
développé avec une IA. Le texte déposé figurait dans
`docs/distribution/izzyondroid-request.md` (retiré, visible dans l'historique
git). Pas de nouvelle demande prévue ; la voie 2 couvre le besoin.

## Voie 2 : dépôt F-Droid personnel (voie retenue ; en place, publié le 2026-10-17, installation testée sur Pixel 8)

Dépôt compatible F-Droid hébergé par GitHub Pages. Aucune revue : les
utilisateurs ajoutent l'adresse du dépôt dans leur client (F-Droid, Droid-ify,
Neo Store) et reçoivent les mises à jour. Les APK sont ceux de la Release,
signés avec la clé de publication ; l'index est signé par une **clé de dépôt
distincte**.

**Pour le propriétaire**
- `make fdroid-repo` : construit le dépôt localement à partir de l'APK arm64 de
  `dist/` (donc après `make package` ou `make release`). État dans
  `~/.local/share/aventuriers-des-mots/fdroid/` (trois dernières versions).
- `make fdroid-publish` : fait de même, puis publie sur la branche orpheline
  `gh-pages` (force-push, sans historique). Une seule fois : activer GitHub
  Pages (Settings > Pages > Source : branche `gh-pages`, dossier `/`).
- Au premier lancement, la clé du dépôt est créée :
  `~/.local/share/aventuriers-des-mots/fdroid-repo.keystore`, mot de passe dans
  `~/.config/aventuriers-des-mots/fdroid.env` (droits 600). **À sauvegarder hors
  de la machine** : la perdre oblige tous les utilisateurs à retirer puis
  rajouter le dépôt.
- `fdroidserver` est installé par `make setup` (`.venv`).
- Fichiers versionnés : `fdroid/config.template.yml`,
  `fdroid/metadata/org.deunix.aventuriersdesmots.yml` ; les textes et images
  viennent de `fastlane/`.

**Pour les utilisateurs** (une fois publié)
1. Installer F-Droid (f-droid.org) ou un client compatible.
2. Réglages > Dépôts > Ajouter un dépôt, saisir
   `https://deunix-educ.github.io/aventuriers-des-mots/fdroid/repo`.
3. Vérifier l'empreinte SHA-256 affichée par `make fdroid-repo` (à publier dans
   le README) pour être sûr de la source ; installer « Les Aventuriers des mots ».

Support imprimable (QR code, adresse, 4 étapes, empreinte) : `docs/distribution/support-imprimable.pdf`
(`make generate-flyer` le régénère ; adresse et empreinte sont dans
`tools/generate_flyer.py`).

Limite : arm64 seulement (téléphones et tablettes ARM récents) ; une tablette
x86_64 utilise l'APK de `android.zip`.

## Voie 3 : F-Droid officiel (lourde, plus tard)

F-Droid recompile l'application sur ses serveurs, à partir des sources, sans
binaire pré-compilé. Pour un projet Godot, d'après les retours de la
communauté, cela veut dire construire le moteur et le modèle d'export Android
depuis les sources dans la recette de build, et retirer les modules Google Play
du modèle. Faisable mais long (recette dans le dépôt `fdroiddata`, revue
humaine, compilation de Godot). À envisager seulement après validation du
contenu.

## ChromeOS

Sans Google Play, un Chromebook peut :
- utiliser la **version web** (`chromeos.zip`, `lancer-web.sh`) ;
- utiliser le **binaire Linux** dans Crostini (Linux sur ChromeOS) ;
- installer l'APK si Android est activé et l'installation hors Play autorisée
  (rarement le cas sur les Chromebooks scolaires gérés).

Les Chromebooks scolaires gérés sont donc le cas difficile : prévoir avec
l'établissement l'une de ces trois options.

## Non vérifié

- Installation via un client F-Droid non testée.
