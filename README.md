# Les Aventuriers des mots

Jeu éducatif de français pour les CE1-CE2 (7-9 ans) : une aventure 2D hors ligne, avec une carte à explorer, un personnage guide, et des exercices de grammaire, d'orthographe et de dictées.

Projet open source, en développement. Statut actuel : squelette technique (voir `docs/specs/decisions.md` pour les décisions de cadrage et `docs/specs/cahier-des-charges.md` pour la spécification complète).

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
| `make export-linux` / `make export-windows` | exports dans `build/` (à partir de l'étape export) |

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
