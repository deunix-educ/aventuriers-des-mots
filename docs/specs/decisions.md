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

## 15. Étape « Exports » : précisions prises en cours d'implémentation

- **`export_presets.cfg` écrit à la main**, pas via l'éditeur Godot (pas d'interface graphique disponible dans cet environnement). Un preset minimal — nom, plateforme, chemin d'export, architecture `x86_64` — suffit : Godot complète les options absentes avec ses valeurs par défaut pour la plateforme. Les deux exports (`make export-linux`, `make export-windows`) ont réellement été lancés et produisent un binaire qui démarre (vérifié en headless pour Linux ; pour Windows, seul le format du binaire a pu être vérifié — `file` confirme un PE32+ valide, mais aucun moyen de l'exécuter dans cet environnement : pas de Wine installé, pas de machine Windows).
- **Modèles d'export** : dossier nommé avec un point avant `stable` (`4.6.3.stable`), alors que `.godot-version` et les URLs de téléchargement utilisent un tiret (`4.6.3-stable`) — deux formats distincts à ne pas confondre. Téléchargés par `tools/setup.sh` (~1,2 Go), jamais commités (voir `.gitignore`, déjà configuré pour exclure `export_templates` implicitement via le chemin hors dépôt `~/.local/share/godot/`).
- **Exclusion de `tests/` et `addons/gut/` de l'export** (`exclude_filter` des deux presets) : ce sont des dépendances de développement, elles n'ont rien à faire dans un exécutable livré à un enfant. Vérifié par la taille du `.pck` (124 Ko après exclusion contre 1,5 Mo avant).
- **`export_presets.cfg` vérifié avant commit** : aucun champ de signature, de clé ou de chemin d'identifiants (ces champs n'existent que pour Android/iOS/macOS, hors périmètre). Rien à nettoyer.
- **Non vérifié** : exécution réelle du binaire Windows (pas d'environnement Windows ni Wine disponible ici) ; comportement sur une distribution Linux différente de celle de cet environnement (cahier des charges §13 : « tester sur les distributions cibles et leurs dépendances graphiques ») ; macOS, Android, iOS restent hors périmètre de cette version.

## 16. Bug signalé manuellement : correction de phrase trop stricte

**Symptôme** : sur la mission « Le pont des phrases », toucher « petit » puis taper « petits » affichait « Pas tout à fait » au lieu d'être accepté.

**Cause** : `AnswerValidator.validate_sentence_correction` comparait le texte saisi au texte attendu avec `!=`, une égalité de chaîne brute, sans aucune des tolérances déjà prévues pour les dictées (point 6) — pas de normalisation de casse, d'apostrophe typographique, d'espaces ou d'accents décomposés. Une différence incidente (ex. une majuscule ajoutée par une autocapitalisation du système) suffisait à rejeter une réponse pourtant correcte sur le fond (l'accord), ce qui contredit l'invariant pédagogique « une réponse ambiguë n'est pas déclarée fausse automatiquement ».

**Correction** : la comparaison passe maintenant par `TextNormalizer.normalize(...).to_lower()` des deux côtés (même normalisation que pour les dictées), tout en gardant le texte brut saisi dans `found` pour l'affichage du retour. Un test automatisé avec la séquence exacte rapportée (toucher une fois, taper, valider) n'avait pas reproduit le bug — preuve que la logique fonctionnait pour une saisie identique au caractère près ; c'est la tolérance aux variations incidentes qui manquait, pas la logique d'association mot/correction elle-même. Trois tests couvrent maintenant la casse, les espaces superflus et les accents décomposés.

**Leçon** : toute comparaison de texte saisi par l'enfant doit passer par `TextNormalizer`, pas par une égalité de chaîne brute — à vérifier si d'autres types d'exercices à saisie libre sont ajoutés plus tard.

## 17. Bug signalé manuellement : « Bravo » sans suite visible

**Symptôme** : après « Bravo ! » sur la mission « Le pont des phrases », cliquer sur « Continuer » semblait ne rien faire.

**Diagnostic** : un test automatisé confirme que la mission avance bien (un nouvel exercice est réellement chargé, `completed_count` augmente). Le contenu pédagogique de cette mission ne contient qu'une seule correction de phrase (`ce1_accord_adjectif_correction_01`, voir le point 14 sur le volume de contenu encore minimal) : le deuxième exercice de la mission est donc **exactement la même phrase**, ce qui donne l'impression visuelle de n'avoir pas bougé alors que la mission en est à l'exercice 2 sur 3.

**Correction** : ajout d'un repère visuel permanent (« Exercice N/3 ») en haut de `exercise_host`, mis à jour à chaque exercice chargé. Ne corrige pas le manque de contenu (qui reste à écrire), mais rend la répétition explicite plutôt que silencieuse.

## 18. Contenu : corrections de phrase de `regle_accord_adjectif` portées à 4

**Contexte** : le point 14 notait que le volume minimal du cahier des charges (prompt-lancement.md : « par règle, au moins 8 choix multiples et 4 corrections de phrase, répartis sur les niveaux de difficulté ») n'était pas atteint — une seule correction de phrase existait, cause directe de la répétition constatée au point 17.

**Ajout** : trois corrections de phrase supplémentaires pour `regle_accord_adjectif` (`ce1_accord_adjectif_correction_02` à `_04`), portant le total à 4 et couvrant les trois niveaux de difficulté (1, 2, 3) ainsi que les deux axes de l'accord (genre et nombre), avec un cas difficulté 3 où le nom et l'adjectif sont séparés par d'autres mots. Toutes en `review_status: draft` (non relues par un humain, cf. CLAUDE.md).

**Reste à faire** : les 8 choix multiples par règle (2 existent) et les 3 dictées par chapitre (1 existe) ne sont pas couverts par ce travail ; le volume minimal du cahier des charges n'est donc pas encore entièrement atteint pour cette règle.

## 19. Audio provisoire des dictées : génération effective

**Constat manuel** : testée à la main, la mission « La clairière de l'écho » ne pouvait pas être réellement jouée — aucun fichier audio n'existait (point 8), donc rien à écouter avant de dicter la phrase.

**Mise en œuvre** : `tools/generate_dictation_audio.py` génère chaque dictée marquée `audio_provisional: true` en deux étapes outillées localement, sans accès réseau à l'exécution du jeu ni moteur TTS embarqué (conforme au point 8 et à l'invariant « aucun accès réseau ») : synthèse vocale hors ligne avec eSpeak NG (voix `fr-fr`, débit ralenti à 135 mots/minute pour un enfant de 7-9 ans) vers un `.wav` temporaire, puis encodage en Ogg Vorbis avec ffmpeg vers `assets/audio/dictations/<audio_id>.ogg`. N'écrase jamais un fichier existant sans `--force`. Exposé via `make generate-dictation-audio`. eSpeak NG n'est pas vendorisé (contrairement à Godot/GUT) : il doit être installé au niveau système (`apt install espeak-ng` ou équivalent) avant d'utiliser cette commande ; un message d'erreur explicite guide si l'outil est absent.

**Généré** : `ce1_accord_adjectif_dictee_01.ogg` (seule dictée existante). Source notée dans `assets/CREDITS.md`.

**Vérification** : nouveau test headless (`tests/data/test_dictation_audio.gd`) qui échoue si une dictée `audio_provisional` n'a pas de fichier `.ogg` chargeable — garde-fou contre un futur ajout de dictée sans régénération de l'audio, repéré plus tôt que par un test manuel. La qualité d'écoute elle-même (volume, clarté) reste non vérifiable sans écran/haut-parleur, donc à faire à la main (voir `docs/testing/manual-checklist.md`).

**Suite** : la voix eSpeak NG utilisée ici s'est révélée inintelligible à l'écoute (voir point 20) et a été remplacée.

## 20. Audio provisoire des dictées : eSpeak NG remplacé par une voix neuronale Piper

**Symptôme** : test manuel sur `ce1_accord_adjectif_dictee_01.ogg` (point 19, voix eSpeak NG par synthèse de formants) : « voix inintelligible ». Ralentir le débit ou ajuster les paramètres d'eSpeak NG ne change pas la nature du problème — une synthèse par formants reste mécanique par construction, ce n'est pas qu'une question de vitesse.

**Remplacement** : `tools/generate_dictation_audio.py` utilise maintenant une voix neuronale hors ligne via la bibliothèque Python `piper-tts` (modèle `fr_FR-siwis-medium`, un locuteur, qualité medium, licence MIT pour Piper / CC-BY 4.0 pour le corpus SIWIS sous-jacent — attribution dans `assets/CREDITS.md`). Toujours aucun accès réseau à l'exécution du jeu : le modèle de voix (~60 Mo) est téléchargé une seule fois, à la demande, dans `.cache/piper-voices/` (non versionné, voir `.gitignore`), au moment de la rédaction de contenu, jamais par le jeu lui-même. `LENGTH_SCALE = 1.1` ralentit légèrement le débit par rapport à une diction adulte par défaut. eSpeak NG n'est plus une dépendance du projet ; `ffmpeg` (déjà présent sur la machine) reste utilisé pour l'encodage final en Ogg Vorbis. `piper-tts` est ajouté à `tools/setup.sh` (environnement Python partagé avec gdtoolkit/pyright).

**Effet de bord** : `pyright` ne résolvait pas l'import `piper` en ciblant l'environnement Python par défaut plutôt que `.venv/`. Ajout de `pyrightconfig.json` (`venvPath`/`venv`) à la racine pour que `make lint` continue de fonctionner sans option supplémentaire.

**Régénéré** : `ce1_accord_adjectif_dictee_01.ogg` avec la nouvelle voix. Non encore réécouté par un humain au moment d'écrire ceci — à confirmer en test manuel que l'intelligibilité est bien résolue, pas seulement supposée meilleure.

**Confirmation manuelle** : voix jugée parfaitement intelligible par un test humain. Voir le point 21 pour le bug distinct révélé par ce même test.

## 21. Bug signalé manuellement : dictée correcte refusée (ponctuation finale)

**Symptôme** : en écoutant la dictée (point 20, voix maintenant intelligible) et en tapant exactement « Les petits chats dorment » tel qu'entendu, la réponse n'était pas validée comme correcte.

**Cause** : `data/dictations/ce1_accord_adjectif_dictee_01.json` attend le texte avec un point final (`"target_text": "Les petits chats dorment."`), mais aucune voix (provisoire ou future) ne vocalise la ponctuation terminale — rien dans ce que l'enfant entend ne lui indique qu'il faut écrire ce point. `DictationAnalyzer` comparait le texte tel quel : l'absence du point faisait échouer la comparaison exacte, puis l'alignement mot à mot traitait « dorment » et « dorment. » comme deux mots différents (une substitution), signalée comme une erreur non classée. Un test reproduisant exactement l'interaction rapportée (`tests/exercises/test_exercise_host_dictation.gd`) a confirmé le problème avant toute correction.

**Correction** : `DictationAnalyzer` ignore désormais la ponctuation terminale (`.`, `!`, `?`, `…`) à la comparaison — aussi bien dans le test d'égalité exacte (et celui des variantes acceptées) que dans l'alignement mot à mot, où elle est retirée avant la découpe en mots plutôt qu'après coup. La ponctuation interne à la phrase n'est pas concernée. Quatre tests couvrent : omission du point, point remplacé par un autre signe, et absence de faux négatif (une vraie faute sur le dernier mot reste détectée malgré la tolérance de ponctuation).

**Leçon** : une tolérance de comparaison doit correspondre à ce que le canal d'entrée (ici l'audio) peut réellement transmettre à l'enfant — exiger une information qu'il n'a pas reçue revient à le punir d'une faute qu'il n'a pas commise (CLAUDE.md, invariants pédagogiques). À revoir si l'audio final fait un jour entendre la ponctuation (pause marquée, voix qui annonce « point »).

**Revu au point 22** : cette tolérance a été annulée après discussion — majuscule et point final sont une convention générale, pas une information dictée.

## 22. Majuscule et point final : exigés comme convention générale, pas tolérés

**Contexte** : en poursuivant le test manuel du point 21, une réponse tapée sans majuscule initiale (« les petits chats dorment ») a aussi échoué, sur une erreur de catégorie « capitalization ». Question posée (CLAUDE.md : « en cas d'ambiguïté, poser la question plutôt que trancher seul ») plutôt que d'étendre seul la tolérance du point 21 à la majuscule : la majuscule en début de phrase et le point final sont-ils une information que l'audio devrait transmettre (comme supposé au point 21), ou une convention générale que l'enfant applique de lui-même, indépendamment de ce qu'il entend — comme en classe, où l'enseignant ne dit pas toujours « majuscule » ou « point » avant chaque dictée ?

**Décision** : convention générale. Les deux sont exigés, comme n'importe quel autre mot de la phrase. La tolérance du point 21 est annulée : `DictationAnalyzer` retrouve sa comparaison d'origine (plus de `_strip_terminal_punctuation`), majuscule et point final doivent à nouveau être écrits exactement.

**Contrepartie** : exiger une convention que l'audio ne signale pas suppose que l'enfant la connaît déjà par ailleurs, pas qu'il la devine dictée par dictée. Ajout d'un rappel permanent et visible dans la scène de dictée (`dictation.tscn`, label `ConventionHintLabel`, clé `dictation.convention_hint` dans `data/localization/fr.json` : « N'oublie pas : une majuscule au début de la phrase et un point à la fin ! »). C'est la réponse concrète à « il faudra indiquer les règles quelque part » : la règle est communiquée par l'interface, pas supposée acquise silencieusement.

**Tests** : `tests/correction/test_dictation_analyzer.gd` vérifie que l'omission du point est à nouveau une erreur (la majuscule l'était déjà, test existant) ; `tests/exercises/test_exercise_host_dictation.gd` vérifie la même chose au niveau de la scène complète.

## 23. Contenu : choix multiples de `regle_accord_adjectif` portés à 8

**Ajout** : six choix multiples supplémentaires (`ce1_accord_adjectif_qcm_03` à `_08`), portant le total à 8 — le minimum du cahier des charges pour ce type d'exercice sur une règle (prompt-lancement.md). Répartition : 4 en difficulté 1 (déterminant pluriel/singulier directement visible), 2 en difficulté 2 (adjectif après le nom, sans marqueur de déterminant pluriel comme repère), 2 en difficulté 3 (nom et adjectif séparés par un complément, comme au point 18 pour les corrections de phrase). Couvre les quatre combinaisons genre/nombre et deux adjectifs (« petit », « joli ») pour varier le vocabulaire. Toutes en `review_status: draft`.

**Reste à faire** : les 3 dictées par chapitre (1 existe) restent en dessous du minimum du cahier des charges pour cette règle.

## 24. Contenu : dictées du chapitre « accords du groupe nominal » portées à 3

**Ajout** : deux dictées supplémentaires (`ce1_accord_adjectif_dictee_02`, difficulté 2, féminin singulier ; `ce1_accord_adjectif_dictee_03`, difficulté 3, féminin pluriel avec nom et adjectif séparés par un complément, comme aux points 18 et 23), portant le total à 3 pour ce chapitre — le minimum du cahier des charges. Audio généré avec `make generate-dictation-audio` (voix Piper, voir point 20), crédité dans `assets/CREDITS.md`. Toutes en `review_status: draft`.

**Volume minimal du cahier des charges désormais atteint pour `regle_accord_adjectif`** : 8 choix multiples (point 23), 4 corrections de phrase (point 18), 3 dictées (ci-dessus). Les deux autres règles CE1 prévues par prompt-lancement.md (pluriel du nom, accord du déterminant) et le chapitre CE2 (homophones grammaticaux) restent à écrire entièrement.
