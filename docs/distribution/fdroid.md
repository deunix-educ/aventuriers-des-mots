# Distribuer l'application Android sans Google (F-Droid)

Google Play est écarté (frais de compte). Voies retenues, de la plus simple à la
plus lourde. Les règles des dépôts évoluent : confirmer sur leurs sites avant
toute demande.

## Ce que fournit le dépôt

- **L'APK seul dans chaque Release** : `aventuriers-des-mots-X.Y.Z-android-arm64.apk`
  (arm64 uniquement, environ 28 Mo : IzzyOnDroid refuse au-delà de 30 Mo), signé
  avec la clé de publication (`make release` vérifie signature et taille). L'APK
  arm64 + x86_64 reste dans `android.zip`. Marge faible : si le contenu grossit
  (plus de dictées), l'APK dépassera 30 Mo : compresser davantage l'audio ou
  demander une dérogation.
- **Métadonnées de magasin** dans `fastlane/metadata/android/fr-FR/` : titre,
  descriptions courte et longue, icône 512 px, quatre captures d'écran, notes
  de version par `versionCode` (`changelogs/903.txt` pour la 0.9.3). C'est le
  format lu par F-Droid et IzzyOnDroid. Pour chaque nouvelle version, ajouter
  `changelogs/<versionCode>.txt` (`versionCode = major*10000 + minor*100 + patch`).
- Dossier `fastlane/` ignoré par Godot (`.gdignore`) et exclu des exports.
- Licences compatibles : code et illustrations AGPL-3.0, police OFL, voix CC BY
  4.0 (attribution dans `assets/CREDITS.md`), aucun traqueur, aucune permission
  Internet.

## Voie 1 (recommandée) : dépôt IzzyOnDroid

Dépôt compatible F-Droid qui publie les APK officiels des développeurs, pris
dans les Releases GitHub. Pas de frais, pas de recompilation, mise à jour
automatique quand un tag et une Release portant un APK sont publiés.

1. Avoir au moins une Release avec l'APK (voir plus haut) : publier la 0.9.3.
2. Ouvrir un ticket sur https://codeberg.org/IzzyOnDroid/repodata/issues (compte
   Codeberg gratuit ; page « New app inclusions » du site). Brouillon prêt dans
   `docs/distribution/izzyondroid-request.md`, avec la mention du développement
   assisté par IA (leur politique rejette les apps « vibe-coded »).
3. Les utilisateurs ajoutent ensuite le dépôt IzzyOnDroid dans le client
   F-Droid (ou Droid-ify, Neo Store) et installent l'application.

Point d'attention : le modèle Android standard de Godot embarque un petit
module de vérification de licence Google Play (`com.android.vending.licensing`),
inactif sans Play Store. Les analyseurs de F-Droid le signalent ; IzzyOnDroid est
plus tolérant, mais la demande peut le relever.

## Voie 2 : dépôt F-Droid personnel (en place)

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
   `https://deunix-educ.github.io/aventuriers-des-mots/repo`.
3. Vérifier l'empreinte SHA-256 affichée par `make fdroid-repo` (à publier dans
   le README) pour être sûr de la source ; installer « Les Aventuriers des mots ».

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

- Aucune demande déposée ; l'acceptation d'IzzyOnDroid n'est pas garantie.
- Installation via un client F-Droid non testée.
