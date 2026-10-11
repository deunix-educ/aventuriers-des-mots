# Décisions validées en cours de projet

Ce document consigne les décisions prises à l'étape 0 (cadrage) et celles qui suivront. Il fait foi au même titre que le cahier des charges pour les points qu'il tranche ; en cas de contradiction avec `cahier-des-charges.md`, ce fichier a priorité car il représente la décision la plus récente. À tenir à jour à chaque décision significative.

## 0. Gouvernance du dépôt

- **Licence** : GNU Affero General Public License v3 (AGPL-3.0) pour le code. Fichier `LICENSE` à la racine.
- **Hébergement** : dépôt GitHub privé, `deunix-educ/aventuriers-des-mots`.
- **Identité des commits** : Denis Defolie <denis.defolie@gmail.com>, configurée localement pour ce dépôt (pas dans la config git globale de la machine).

## 1. Version de Godot

Godot **4.6** (branche stable la plus récente au démarrage du projet, sortie janvier 2026). Figée via un fichier `.godot-version` à la racine. Binaire officiel précompilé téléchargé manuellement, jamais committé.

## 2. Outillage

- Tests headless : addon **GUT** (`addons/gut`), exécuté par `godot --headless -s addons/gut/gut_cmdln.gd`.
- Lint / format GDScript : **gdtoolkit** (`gdlint`, `gdformat`), installé via `make setup`, configuré en 4 espaces d'indentation.
- Validation des données JSON : pas de bibliothèque GDScript mûre pour JSON Schema. Le validateur est écrit en GDScript et constitue la seule source de vérité : c'est le même code qui valide au chargement dans le jeu et que `make validate-data` invoque en headless. Aucun second validateur Python qui dupliquerait la logique.
- Outils Python éventuels dans `tools/` : annotations de type, zéro erreur `pyright`, usage limité à des scripts de support (pas de revalidation parallèle des données).

## 3. Schémas JSON

Schémas distincts : `rule`, `exercise` (un schéma par valeur de `type`, discriminé sur ce champ), `dictation` (modèle séparé, §8 du cahier des charges), `curriculum`, `save`.

**Interaction de correction de phrase** : l'enfant touche (ou clique) le mot fautif, puis saisit sa correction — pas de ressaisie complète de la phrase. Justification : plus adapté au tactile et à l'âge visé (7–9 ans), et la donnée devient une liste de tokens dont chacun des fautifs porte sa correction attendue et son `rule_id`, ce qui répond directement à l'exigence du §6 (« les erreurs identifiées et leur position »).

## 4. Structure de correction (§6)

Objet `CorrectionResult` retourné par `answer_validator` / `dictation_analyzer` :

- `is_correct: bool`
- `errors: Array[ErrorDetail]`, chaque `ErrorDetail` portant `position` (index du token), `error_type` (`lexical` | `grammatical` | `unclassified`), `rule_id`, `found`, `expected`
- `explanation: String`
- `hint: String` (facultatif)
- `remediation: Array[String]`

Les dictées produisent les mêmes `errors[]`, après l'alignement mot-à-mot décrit au point « Points durs » du prompt de lancement.

## 5. États de maîtrise (§9) et révisions

Constantes nommées (pas de valeurs en dur dispersées) :

| Transition | Seuil |
|---|---|
| Découverte → En acquisition | première réussite, aidée ou non |
| En acquisition → En consolidation | ≥2 réussites sans indice sur les 5 dernières tentatives, taux de réussite récent ≥0,6 |
| En consolidation → Acquise | taux de réussite ≥0,85 sur les 8 dernières tentatives, 0 indice sur les 4 dernières réussites, réussites réparties sur **≥3 séances distinctes** et **≥2 formats d'exercice différents** |
| → À réviser | un échec sur une compétence consolidée ou acquise, ou délai de révision atteint |

Révision planifiée en **séances comptées**, pas en jours calendaires seuls (l'horloge d'un appareil familial n'est pas fiable) : paliers à 1, 3, 6, 12 séances après la dernière réussite à ce palier (doublement façon répétition espacée). La date (`last_practiced`) reste enregistrée et affichée (espace adulte) mais n'est pas le déclencheur principal.

## 6. Tolérance des dictées (§5)

- **Accents** : exigés, comparés après alignement mot-à-mot (pour ne pas décaler les erreurs suivantes).
- **Apostrophes** : droite et typographique normalisées, traitées comme identiques.
- **Espaces** (y compris insécables) : normalisés avant comparaison, jamais une source d'erreur.
- **Majuscules** : comparaison insensible à la casse pour l'identité lexicale ; une majuscule attendue (début de phrase, nom propre) est vérifiée comme erreur à part, pilotée par une annotation de la donnée cible.
- **Ponctuation finale** : erreur distincte, non cascadée sur les mots qui suivent.
- **Variantes admises** : liste explicite par dictée dans les données.
- **Erreurs multiples dans un mot** : comptées comme une seule erreur sur ce mot, classée par la règle annotée dominante.

## 7. Écarts de `exercise-lifecycle.md`

Les deux propositions du document sont retenues telles que rédigées :

1. Chaque validation, juste ou fausse, produit un enregistrement de tentative transmis à `ProgressManager` ; l'écriture sur disque reste groupée en fin de mission.
2. Aide graduée sur 3 essais (indice, puis explication, puis réponse montrée + explication + marquage pour révision), le nombre d'essais étant un paramètre configurable, pas une constante en dur.

## 8. Audio provisoire des dictées

Synthèse vocale française générée hors ligne **au moment de la rédaction du contenu** (outil type eSpeak-ng), rendue une fois en fichiers `.ogg` versionnés dans `assets/audio/`. Jamais de génération à l'exécution, jamais de moteur TTS embarqué, aucun accès réseau. Chaque entrée audio provisoire porte `audio_provisional: true` dans la donnée, affiché comme badge « voix provisoire » par l'UI. Remplacement fichier par fichier, sans toucher au code. Source notée dans `assets/CREDITS.md`.

## 9. Écarts par rapport à l'arborescence du §7

Les 7 autoloads du cahier des charges sont conservés tels quels : chacun a une responsabilité réelle dès le périmètre §15 (y compris `AudioManager` pour les dictées et `SettingsManager` pour les réglages de volume).

Ajouts à l'arborescence proposée :

- `data/schemas/` : les schémas JSON eux-mêmes.
- `scripts/data/` : chargeurs de données et validateur GDScript.
- `addons/gut/` : framework de tests headless.
- `tests/` organisé en sous-dossiers miroir (`tests/correction/`, `tests/pedagogy/`, `tests/data/`, `tests/saves/`) plutôt qu'à plat.
- `docs/review/` (`content-review.md`) et `docs/testing/` (`manual-checklist.md`), déjà prévus par le prompt de lancement.

## 10. Questions restées ouvertes

- Licence et hébergement : tranchés ci-dessus (point 0).
- Validation du contenu CE1/CE2 par un enseignant avant diffusion : à organiser, pas de date fixée.
- Spécification minimale de performance pour « appareil familial » : non définie, à préciser avant les exports.
