# Les Aventuriers des mots

Jeu éducatif de français CE1–CE2 (7–9 ans), aventure 2D, hors ligne, Godot 4 / GDScript typé. Projet open source.

- Spécification de référence : `docs/specs/cahier-des-charges.md`. Elle fait foi. En cas de contradiction ou d'ambiguïté, poser la question au lieu de trancher seul.
- Cycle de vie d'un exercice : `docs/specs/exercise-lifecycle.md`.
- Décisions validées en cours de projet : `docs/specs/decisions.md` (à tenir à jour).

## Commandes

Le `Makefile` est le seul point d'entrée pour les opérations système. Tenir cette liste à jour.

- `make setup` : installe l'outillage (lint, tests, modèles d'export)
- `make run` : lance le jeu
- `make lint` / `make format` : analyse statique et formatage
- `make validate-data` : valide tous les JSON de `data/` contre leurs schémas
- `make test` : tests en mode headless
- `make check` : lint + validate-data + test (à passer avant chaque commit)
- `make content-review` : régénère `docs/review/content-review.md` à partir de `data/`
- `make generate-dictation-audio` : génère l'audio provisoire des dictées (voix neuronale Piper via `.venv`, `ffmpeg` requis sur la machine) dans `assets/audio/dictations/`, sans écraser l'existant (`--force` pour régénérer)
- `make export-linux` / `make export-windows` : exports dans `build/`
- `make package` : réexporte puis produit les archives distribuables (exécutable unique + licence + crédits + notice) et `SHA256SUMS` dans `dist/`

## Conventions de code

- Identifiants, noms de fichiers et messages de commit en anglais.
- Commentaires et docstrings en français.
- Aucun texte destiné à l'enfant en dur dans les scripts : il vit dans `data/` ou dans les fichiers de traduction.
- Indentation : 4 espaces, dans tous les langages, GDScript compris. Jamais de tabulation. `.editorconfig` et le formateur sont configurés en conséquence ; dans l'éditeur Godot, régler Editor Settings → Text Editor → Behavior → Indent → Type sur Spaces.
- GDScript : typage statique partout (variables, paramètres, retours, tableaux typés). Les déclarations non typées sont traitées comme des erreurs.
- Outils Python éventuels (`tools/`) : annotations de type, zéro erreur pyright.
- `README.md` (français) et `README-EN.md` (anglais) restent synchronisés.

## Git

- `.gitattributes` tenu à jour : fins de ligne LF pour le texte, assets marqués binaires.
- `.gitignore` exclut `.godot/`, `build/`, et tout secret : keystores, identifiants d'export, `.env`, mots de passe, adresses e-mail personnelles.
- Vérifier qu'`export_presets.cfg` ne contient aucun secret avant de le commiter.
- Un commit par unité de travail cohérente, `make check` au vert avant chaque commit.

## Invariants d'architecture

- Trois couches strictement séparées : moteur du jeu, données pédagogiques, progression par enfant.
- Les exercices sont des données JSON, validées au chargement. La liste des types d'exercices est fermée et définie dans le moteur.
- Une donnée ne peut jamais exécuter du code : pas d'`Expression`, pas de `str_to_var`, pas de chargement de script ou de scène depuis les données.
- Les fichiers référencés par les données (audio, images) le sont par identifiant, résolu par le moteur dans un répertoire fixe. Jamais de chemin libre.
- Les scènes sont autonomes et communiquent par signaux. Une scène d'exercice ne touche ni à la sauvegarde ni à la progression.
- Correction, difficulté et planification des révisions sont du code pur, sans dépendance à l'arbre de scènes, testable en headless. Horloge et hasard y sont injectés, jamais lus directement.
- Les explications viennent des données validées, jamais d'une génération à l'exécution.
- Aucun accès réseau.
- Sauvegardes dans `user://` : un fichier par profil, `schema_version`, écriture atomique (fichier temporaire puis remplacement), copie de secours, migration entre versions.
- Interface en conteneurs et ancres, sans positions fixes. Clavier, souris et tactile. Réussite et erreur ne sont jamais signalées par la seule couleur.
- Ne pas créer de module ou d'autoload sans responsabilité réelle.

## Invariants pédagogiques

- Une erreur déclenche une explication, jamais une punition. Aucune récompense liée à la vitesse.
- Contenu original uniquement : ne jamais reproduire le texte, les exemples ou les exercices du BLED ni d'aucun manuel. Le nom « BLED » n'apparaît ni dans le jeu ni dans les données.
- Tout exercice a une réponse attendue, un `rule_id`, un indice et une explication.
- Tout contenu rédigé par Claude porte `"review_status": "draft"` jusqu'à validation humaine.
- Une réponse ambiguë n'est pas déclarée fausse automatiquement.

## Vérification

Tests headless obligatoires pour la correction, la progression et les sauvegardes. Ce qui ne peut pas être vérifié sans écran (rendu, animations, audio, tactile, clavier virtuel) est signalé explicitement comme non vérifié, avec la marche à suivre pour le tester à la main.
