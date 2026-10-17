# Les Aventuriers des mots

Jeu éducatif de français du CE1 au CM2 (7-11 ans) : une aventure 2D hors ligne, avec une carte à explorer, un personnage guide, et des exercices de grammaire, d'orthographe et de dictées.

Projet open source, en développement. Statut actuel : version 0.9.2, jouable hors ligne sur Linux, Android et dans un navigateur (versions testées à la main), avec des exports Windows, macOS et ChromeOS non encore testés sur matériel — profils, sauvegardes (avec export et restauration dans l'espace adulte), étoiles et collection d'objets, sons et musique, réglages (volumes, taille du texte, animations), tableau de progrès pour l'adulte, trois types d'exercices (choix multiple, correction de phrase, dictée), CE1, CE2, CM1 et CM2 en trois tableaux chacun (homophones, verbes, orthographe des mots), 111 missions. Contenu pédagogique entièrement en brouillon (`draft`, à valider) et voix des dictées provisoires (voir `assets/CREDITS.md` ; voir `docs/specs/decisions.md` pour les décisions de cadrage et `docs/specs/cahier-des-charges.md` pour la spécification complète).

## Télécharger

Les versions prêtes à jouer sont sur la page des [Releases](https://github.com/deunix-educ/aventuriers-des-mots/releases) : une archive par plateforme (Linux, Windows, macOS, Android, ChromeOS/navigateur) et `SHA256SUMS` pour vérifier les fichiers. Ce sont des versions préliminaires : contenu pédagogique en brouillon, voix provisoires. Chaque archive contient un fichier `LISEZMOI` qui explique le lancement.

## Pile technique

- Godot 4.6 (GDScript typé)
- Exercices et contenu pédagogique en données JSON, validées au chargement
- Tests headless (GUT), lint/format GDScript (gdtoolkit)

## Démarrer

```sh
make setup   # installe Godot (pinné), GUT et gdtoolkit en local, rien n'est commité
make run     # lance le jeu
```

## Commandes

| Commande | Effet |
|---|---|
| `make setup` | installe l'outillage (lint, tests, modèles d'export) |
| `make run` | lance le jeu |
| `make lint` / `make format` | analyse statique et formatage GDScript |
| `make validate-data` | valide les JSON de `data/` |
| `make test` | tests headless |
| `make check` | lint + validate-data + test, à passer avant chaque commit |
| `make content-review` | régénère `docs/review/content-review.md` (document de validation du contenu) |
| `make generate-dictation-audio` | génère l'audio provisoire des dictées |
| `make release` / `make release-dry-run` | publie (ou simule) une Release GitHub |
| `make help` | liste les commandes disponibles |
| `make export-play` | App Bundle (.aab) pour Google Play |
| `make serve-web` | exporte puis sert la version web en local et ouvre le navigateur |
| `make export-linux` / `make export-windows` / `make export-android` / `make export-macos` / `make export-web` | exports dans `build/` |
| `make package` | produit les archives distribuables dans `dist/` (exécutable unique + licence + crédits) |

## Structure

- `autoload/` : modules globaux (gestion du jeu, profils, progression, exercices, sauvegardes, audio, réglages)
- `scenes/` : scènes Godot, autonomes et communiquant par signaux
- `scripts/` : logique pure (correction, pédagogie) et chargement des données
- `data/` : contenu pédagogique en JSON, validé contre des schémas
- `assets/` : graphismes et audio (provisoires à ce stade, voir `assets/CREDITS.md`)
- `tests/` : tests headless (GUT)
- `docs/specs/` : cahier des charges et décisions de cadrage

## Licence

Code et contenu sous [GNU Affero General Public License v3](LICENSE).
