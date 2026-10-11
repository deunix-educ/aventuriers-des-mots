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

## 11. Étape « Données » : précisions prises en cours d'implémentation

- Le validateur générique (`scripts/data/schema_validator.gd`) implémente un sous-ensemble de JSON Schema (`type`, `required`, `properties`, `additionalProperties`, `items`, `enum`, `const`, bornes numériques, longueurs, `pattern`). Suffisant pour tous les schémas actuels ; pas de `patternProperties` ni de `if`/`then`.
- Le dispatch du schéma d'exercice se fait sur le champ `type` (`multiple_choice` → `exercise_multiple_choice.schema.json`, `sentence_correction` → `exercise_sentence_correction.schema.json`), dans `DataLoader.exercise_schema_name_for_type`. Un type absent de cette fonction est rejeté explicitement par `make validate-data`, conformément à l'invariant « liste fermée des types d'exercices ».
- Les contraintes croisées qu'un schéma ne peut pas exprimer (index `correct_answer` dans les bornes de `answers`, au moins un token fautif en correction de phrase avec une correction `expected`, cohérence entre `target_text` et `words` en dictée) vivent dans `scripts/data/semantic_checks.gd`, testées indépendamment du schéma.
- Schéma de dictée : `words` (annotation mot par mot : `rule_id` et `expects_capital` facultatifs) est **obligatoire**, pas facultatif — sans lui, l'erreur reste non classée (cf. « Points durs » du prompt de lancement). Le nombre de mots dans `words` doit correspondre à `target_text` découpé sur les espaces.
- Le schéma `save` reste provisoire pour le champ `skills` (`{"type": "object"}`, sans validation des clés dynamiques) : le validateur actuel ne sait pas exprimer un schéma pour des clés arbitraires. À affiner à l'étape « Profils et sauvegardes ».
- GUT est pinné en v9.6.0, pas la dernière version (9.7.1 référence le singleton `AccessibilityServer`, absent de Godot 4.6.3 en mode headless).
- `tools/setup.sh` lance `godot --headless --path . --import` en fin d'installation : nécessaire pour que les scripts `class_name` globaux (`SchemaValidator`, `DataLoader`, `SemanticChecks`) soient résolus avant la première exécution de `make test` / `make validate-data`. Même précaution après l'ajout de tout nouveau script `class_name` (ex. `AnswerValidator`, `DictationAnalyzer`, `ReviewScheduler` à l'étape « Logique pure ») : sans réimport, Godot échoue silencieusement avec « Nonexistent function ... in base 'GDScript' » au lieu de signaler l'erreur de compilation réelle.

## 12. Étape « Logique pure » : précisions prises en cours d'implémentation

- GDScript traite l'avertissement « inferred as Variant » (`var x := f()` quand `f()` retourne `Variant`) comme une erreur de compilation en mode script headless. Toujours typer explicitement (`var x: Variant = f()`) quand une fonction peut renvoyer `null`.
- `DictationAnalyzer` aligne les mots en comparant une version en minuscules (alignement insensible à la casse) : sinon une majuscule manquante en début de mot est vue comme une substitution par `WordAligner` et jamais testée comme erreur de capitalisation à part (point 6 des décisions). Les mots originaux (avec leur casse) restent utilisés pour construire les erreurs et pour la vérification de majuscule.
- `ReviewScheduler.record_attempt` est une fonction pure qui duplique l'état (`Dictionary.duplicate(true)`) plutôt que de le modifier en place ; `ProgressManager` (étape « Profils et sauvegardes ») sera responsable de stocker l'état retourné.
- Le planning de révision est entièrement piloté par le numéro de séance (`current_session`), jamais par une horloge : paliers `[1, 3, 6, 12]` séances après la dernière réussite à un palier donné, comme décidé au point 5. Une compétence « acquise » dont le délai est dépassé sans nouvelle tentative passe à « à réviser » via `ReviewScheduler.mark_overdue_as_review`, à appeler par `ProgressManager` en début de séance.

## 13. Étape « Profils et sauvegardes » : précisions prises en cours d'implémentation

- Pas de classes de modèle dans `scripts/models/` (présentes dans l'arborescence indicative du §7) : les sauvegardes restent des `Dictionary` validés contre `data/schemas/save.schema.json`, comme les autres données. Ajout à la liste des écarts du point 9 ci-dessus.
- Découpage en couches : `scripts/profiles/save_io.gd` (lecture/écriture atomique, copie de secours, pas pur — touche le système de fichiers), `save_migration.gd` et `save_factory.gd` (purs), `progress_updates.gd` (pur, s'appuie sur `ReviewScheduler`/`DifficultyManager`). Les autoloads `SaveManager`, `ProfileManager`, `ProgressManager` restent de la colle fine : aucune logique propre, seulement de l'orchestration et de l'état en mémoire (profil courant, sauvegarde courante).
- `id` de profil généré par `ProfileManager` : `profile_<epoch>_<alea>` (conforme au motif `^[a-z][a-z0-9_]*$` du schéma). Pas de saisie de pseudonyme distinct de `display_name` à ce stade — à revoir si besoin à l'étape « Scènes ».
- Génie du moteur JSON de Godot : les nombres relus depuis un fichier sont toujours des `float`, jamais des `int`, même pour un entier comme `session_count`. GDScript convertit implicitement à l'affectation dans une variable typée `int`, mais les comparaisons strictes dans les tests doivent caster explicitement (`int(...)`), sinon GUT émet un avertissement.
- `JSON.parse_string` sur un contenu invalide imprime une erreur moteur (`Parse JSON failed`), même quand l'appelant la gère correctement via la valeur de retour. GUT la compte comme un échec de test par défaut : les tests qui provoquent volontairement cette corruption doivent appeler `assert_engine_error("Parse JSON failed")` pour la marquer comme attendue.
- Les indicateurs « erreurs fréquentes » et l'espace adulte (§9) ne sont pas implémentés : explicitement hors périmètre de la première version jouable (prompt de lancement, Objectif).

## 14. Étape « Scènes » : précisions prises en cours d'implémentation

- **Nouveau type de donnée : mission.** Ni le cahier des charges ni le prompt de lancement ne décrivaient de schéma pour les « lieux » de la carte. Ajout de `data/schemas/mission.schema.json` et `data/missions/*.json` : chaque mission porte un `rule_id`, un `exercise_type`, un `narrative_context` (texte destiné à l'enfant, donc en données, jamais en dur) et une position normalisée (`map_position.x/y` dans [0,1]) résolue par la scène de carte en ancres fractionnelles, pas en pixels fixes. Trois missions couvrent les trois lieux du §15, chacune associée à un des trois types d'exercice de cette version (choix multiple, correction de phrase, dictée), toutes sur l'unique règle CE1 disponible pour l'instant.
- **Validateur étendu : `additionalProperties` comme sous-schéma.** `SchemaValidator` ne savait valider que des clés listées explicitement. Extension pour accepter `"additionalProperties": { ...schema... }`, appliqué à toute clé non listée dans `properties` (clés dynamiques). Utilisé pour resserrer `save.schema.json` (chaque entrée de `skills` validée contre la forme réelle d'un `SkillState` de `ReviewScheduler`, qui restait non vérifiée depuis le point 11) et pour `localization.schema.json` (chaque clé de traduction doit être une chaîne non vide).
- **Textes destinés à l'enfant : fichier de traduction.** Conformément à CLAUDE.md (« aucun texte destiné à l'enfant en dur dans les scripts »), toutes les chaînes d'interface viennent de `data/localization/fr.json`, chargées par `scripts/data/ui_text.gd` (`UIText.get_text(cle)`). Une clé absente renvoie la clé elle-même (visible, donc détectable) plutôt que de planter.
- **Panneaux de règle et de retour : composants embarqués, pas des scènes routées.** `rule_panel.tscn` et `feedback_panel.tscn` sont instanciés en surimpression par `exercise_host`, pas atteints par `GameManager.goto()`. Seuls `boot`, `profile_select`, `profile_create`, `world_map`, `mission_intro`, `exercise_host` et `reward_screen` sont de vraies scènes routées (constantes dans `GameManager`).
- **Changement de scène différé.** `GameManager.goto()` appelle `get_tree().change_scene_to_file.call_deferred(...)` : l'appeler directement depuis `_ready()` de la scène en train d'être ajoutée à l'arbre échoue (« Parent node is busy »).
- **Longueur de mission fixée à 3 exercices** (`exercise_host.MISSION_LENGTH`), avec répétition autorisée du seul exercice disponible quand le contenu est encore insuffisant (le volume minimal du cahier des charges — 8 QCM et 4 corrections par règle, 3 dictées par chapitre — n'est pas encore atteint ; c'est un travail de contenu séparé, pas un défaut de la mécanique de sélection).
- **Difficulté adaptative effectivement branchée** : `exercise_host` relit `ProgressManager.next_difficulty_for_skill()` avant de choisir l'exercice suivant et après chaque exercice terminé, pour que `DifficultyManager` (construit à l'étape « Logique pure ») ait une responsabilité réelle plutôt que du code mort.
- **Récompense** : une étoile fixe par mission terminée, quel que soit le nombre d'aides utilisées ou le temps pris (principe « pas de récompense liée à la vitesse », cahier des charges §2). Calculée et sauvegardée par `reward_screen`, qui est aussi le seul point d'écriture groupée en fin de mission (`ProgressManager.save_now()`).
- **Pas de verrouillage de région** pour cette version : les trois missions sont accessibles d'emblée (correspond à « une carte avec trois lieux accessibles » du §15). Le champ `unlocked_regions` existe toujours dans la sauvegarde mais n'est pas encore lu par la carte.
- **Audio des dictées** : `AudioManager.play_dictation()` existe et cherche `assets/audio/dictations/<audio_id>.ogg`, mais aucun fichier n'a encore été généré (étape « Graphismes et audio provisoires », à venir) ; l'absence de fichier produit un avertissement, jamais un plantage.
- **Non vérifié visuellement** : voir `docs/testing/manual-checklist.md`. Un test headless instancie `exercise_host.tscn` et simule les signaux (sans jamais déclencher le changement de scène final, qui casserait le processus de test), mais aucun rendu, tactile, clavier virtuel ou audio n'a été vérifié à l'écran.
