# Distribuer l'application Android sans Google (F-Droid)

Google Play est écarté (frais de compte). Voies retenues, de la plus simple à la
plus lourde. Les règles des dépôts évoluent : confirmer sur leurs sites avant
toute demande.

## Ce que fournit le dépôt

- **L'APK seul dans chaque Release** : `aventuriers-des-mots-X.Y.Z-android.apk`
  (en plus de l'archive `android.zip`), signé avec la clé de publication
  (`make release`). Les dépôts tiers lisent ce fichier directement.
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
2. Ouvrir une demande d'inclusion sur le suivi des demandes d'IzzyOnDroid
   (hébergé sur Codeberg ; adresse sur izzyondroid.org, page « App Inclusion
   Policy »), avec l'adresse du dépôt GitHub.
3. Les utilisateurs ajoutent ensuite le dépôt IzzyOnDroid dans le client
   F-Droid (ou Droid-ify, Neo Store) et installent l'application.

Point d'attention : le modèle Android standard de Godot embarque un petit
module de vérification de licence Google Play (`com.android.vending.licensing`),
inactif sans Play Store. Les analyseurs de F-Droid le signalent ; IzzyOnDroid est
plus tolérant, mais la demande peut le relever.

## Voie 2 : dépôt F-Droid personnel (facultatif)

Héberger soi-même un dépôt compatible F-Droid (outil `fdroidserver`, fichiers
statiques sur GitHub Pages). Aucune revue, mais il faut publier l'index à chaque
version. Utile si IzzyOnDroid refuse ou tarde.

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
