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

## 25. Extension explicite au-delà du périmètre prototype du §15

**Contexte** : prompt-lancement.md est explicite — « Tout ce qui sort du §15 est hors périmètre [...] Ne l'implémente pas [sans le signaler] », et le §15 du cahier des charges scope la première version jouable à « une carte avec trois lieux accessibles » et « un chapitre CE1 sur les accords dans le groupe nominal » (sans préciser que les trois règles de ce chapitre doivent toutes être jouables). Les trois missions existantes couvraient déjà ce périmètre : une par type d'exercice, toutes sur `regle_accord_adjectif`. Ajouter les deux règles CE1 restantes du chapitre (pluriel du nom, accord du déterminant), chacune avec ses trois missions (comme pour `regle_accord_adjectif`), porte la carte à neuf lieux — au-delà du §15. Conformément à CLAUDE.md (« en cas de contradiction ou d'ambiguïté, poser la question »), la question a été posée avant d'implémenter : extension confirmée.

**Décision** : extension assumée au-delà du prototype §15, en production de contenu plutôt qu'en validation d'architecture. `scenes/world/world_map.gd` reste purement piloté par les données (aucune limite codée en dur sur le nombre de missions), donc aucun changement de code n'était nécessaire pour accueillir plus de lieux — seul le commentaire de tête de fichier, qui affirmait « trois lieux », a été corrigé pour ne pas induire en erreur.

**Ajouté** :
- Deux nouvelles règles CE1, même compétence `accord_groupe_nominal` que `regle_accord_adjectif` (même granularité de suivi de maîtrise que l'existant) : `regle_pluriel_nom` (« on forme le pluriel d'un nom en ajoutant un -s ») et `regle_accord_determinant` (« le déterminant s'accorde en genre et en nombre avec le nom »).
- Pour chacune : 8 choix multiples, 4 corrections de phrase, 3 dictées — le même volume minimal que pour `regle_accord_adjectif` (points 18, 23, 24), réparti sur les 3 niveaux de difficulté. Vocabulaire volontairement restreint à des noms réguliers (chat, fleur, pomme, cahier, porte, voiture, chien, maison, arbre...) pour rester sur la règle enseignée sans exposer d'exceptions (ex. pluriels en -x) non couvertes par l'énoncé de la règle.
- Six nouvelles missions (`mission_04` à `mission_09`), une par type d'exercice et par règle, sur le thème de « La forêt des accords » déjà établi. `data/curriculum/ce1_accords_groupe_nominal.json` mis à jour avec les trois `rule_ids` (toujours non consommé par le moteur, voir point 14 — métadonnée de référence uniquement).
- Audio des 6 nouvelles dictées généré avec `make generate-dictation-audio` (voix Piper, point 20), crédité dans `assets/CREDITS.md`.

**Non vérifié** : la disposition des 9 lieux sur la carte (positions fractionnelles choisies à l'écart les unes des autres, mais jamais vues à l'écran) — à vérifier à la main, voir `docs/testing/manual-checklist.md`.

## 26. Bug signalé manuellement : deux marqueurs de mission se chevauchaient

**Symptôme** : « La clairière » (`mission_03_clairiere_echo`) et « La cabane » (`mission_08_cabane_etiquettes`) se chevauchaient sur la carte — exactement le risque signalé sans être vérifié au point 25.

**Cause** : leurs positions fractionnelles (0.8, 0.65) et (0.92, 0.78) étaient trop proches pour la taille des marqueurs (`MARKER_HALF_WIDTH`/`MARKER_HALF_HEIGHT` dans `world_map.gd`) à la résolution par défaut du projet (aucune taille de fenêtre fixée dans `project.godot`, donc le viewport par defaut de Godot, 1152x648).

**Correction** : les 9 missions sont replacées sur une grille régulière 3x3 (x, y ∈ {0.15, 0.5, 0.85}), avec un écart de 0.35 entre positions adjacentes — largement supérieur à la largeur/hauteur des marqueurs rapportée à la fenêtre par défaut. Les trois missions historiques (`mission_01` à `_03`) sont déplacées elles aussi, pas seulement les nouvelles, pour que la grille soit cohérente partout plutôt que patchée au cas par cas.

**Garde-fou** : nouveau test headless (`tests/data/test_mission_positions.gd`) qui échoue si deux missions ont un écart fractionnel inférieur à 0.3 sur les deux axes — ne remplace pas une vérification visuelle (l'écart réel en pixels dépend de la taille de fenêtre réelle, non fixée), mais attrape la classe d'erreur qui vient de se produire avant qu'elle ne soit signalée à la main.

## 27. Chapitre CE2 « homophones grammaticaux » et carte par niveau

**Décision** : le chapitre CE2 est traité avec les mêmes directives que le CE1 (point 25), sans question préalable (autorisation explicite de ne s'arrêter que sur une contradiction de la spécification ou un changement du format des données/sauvegardes — aucun des deux ici : `school_level` existait déjà dans la sauvegarde, `skills` accepte tout identifiant de compétence, aucun schéma modifié).

**Contenu** (tout en `review_status: draft`, accents corrects, un seul niveau d'orthographe `orthographe`) : quatre règles `regle_homophone_a_a` (a/à), `regle_homophone_et_est` (et/est), `regle_homophone_son_sont` (son/sont), `regle_homophone_on_ont` (on/ont), chacune avec son test de substitution dans l'énoncé, l'indice et l'explication (« avait », « était », « étaient »/« mon », « avaient »/« il »). Compétence commune `homophones_grammaticaux` (même granularité que `accord_groupe_nominal` au CE1). Par règle : 8 choix multiples, 4 corrections de phrase, 3 dictées (3 par règle et non 3 par chapitre, comme au CE1, pour que chaque mission de dictée ait de quoi varier) ; 3 missions par règle (12 au total, `mission_10` à `mission_21`). Audio des 12 dictées généré avec Piper (point 20). `data/curriculum/ce2_homophones_grammaticaux.json` ajouté (région `marais_des_homophones`, toujours non consommé par le moteur).

**Carte par niveau** : 21 missions sur une seule carte ne tiennent pas (marqueurs de 160 px sur 1152 px). `ExerciseEngine.get_missions_for_level()` filtre sur le niveau de la règle de la mission (pas de champ supplémentaire dans les missions), `ProgressManager.school_level()` expose le niveau du profil, et `world_map` n'affiche que les missions du niveau du profil. Le cahier des charges (« un enfant de CE2 qui rencontre une difficulté sur une notion de CE1 pourra revenir à un entraînement adapté ») est respecté par un bouton « Revoir le CE1 » / « Retour au CE2 » visible uniquement pour un profil CE2. Un profil CE1 ne voit pas le CE2. Disposition CE2 : grille 4 colonnes (une par règle) × 3 lignes (QCM, correction, dictée) ; le test d'écart (point 26) vérifie maintenant chaque niveau séparément.

**Non vérifié** : rendu de la carte CE2 (12 marqueurs), du bouton de bascule, et écoute des 12 voix — voir `docs/testing/manual-checklist.md`. Les textes CE1 sans accents sont corrigés au point 28.

## 28. Accents manquants dans les textes CE1

**Constat** : les indices, explications, consignes, énoncés de règle et récits de mission écrits pour le CE1 (points 18, 23-25 et contenu initial) étaient sans accents (« feminin », « ecrire », « determinant », « etiquettes », « a la fin »...), alors que ce sont des textes lus par l'enfant.

**Correction** : restauration des accents sur 76 lignes de 44 fichiers de `data/` (champs `instruction`, `question`, `hint`, `explanation`, `statement`, `example`, `title`, `narrative_context` uniquement ; aucun identifiant, `target_text`, mot de dictée ni token modifié, donc aucun lien entre données ni audio touché). Cas particuliers : « a » devenu « à » (préposition) et « annonce » devenu « annoncé ». Le tag interne `feminin` de `review_tags` est conservé (identifiant, non affiché).

**Règle pour la suite** : tout texte destiné à l'enfant est écrit avec ses accents dès la rédaction.

## 29. Production de la version 0.1.0 (relecture du cahier des charges)

**Relecture** : le §15 (première version jouable) demande un export Linux et Windows ; le §12 demande « une version installable et testée » par plateforme ; le §13 recommande de valider d'abord Linux et Windows, Android/macOS/iOS venant ensuite (hors périmètre, prompt-lancement.md). La version est donc produite pour Linux x86_64 et Windows x86_64.

**Mise en œuvre** : `config/version="0.1.0"` dans `project.godot` ; PCK embarqué dans l'exécutable (`binary_format/embed_pck=true`) pour un fichier unique par plateforme ; `make package` (`tools/package.sh`) réexporte depuis zéro puis crée `dist/` : `.tar.gz` Linux et `.zip` Windows contenant l'exécutable, `LICENSE`, `README.md`, `README-EN.md`, `CREDITS.md` et une notice `LISEZMOI.txt` (lancement, emplacement des sauvegardes, voix provisoires), plus `SHA256SUMS`. Le script refuse d'empaqueter un document vide (un README tronqué par une erreur d'édition a été détecté pendant cette production).

**Écarts connus par rapport au cahier des charges, non traités** (hors périmètre du §15 ou nécessitant des ressources/décisions humaines) : voix préenregistrées naturelles (§16 : voix de synthèse provisoires), illustrations originales et personnage guide animé (formes simples, §11/§16), espace adulte et export/restauration des sauvegardes (§9/§10), écran de réglages (volume, taille du texte, animations — `SettingsManager` existe sans interface), tests sur appareils réels et sur d'autres distributions/Windows (§12/§13), contenu entièrement en `draft` (validation humaine requise avant diffusion).

## 30. Phase « Score et récompenses » (version 0.2.0)

**Origine** : retour utilisateur après la version 0.1.0 — « un jeu attrayant, moderne, avec notation, récompenses, sauvegardes ». Quatre chantiers retenus (habillage, récompenses et collection, réglages et espace adulte, son) ; ordre validé : la logique testable d'abord (cette phase), l'habillage ensuite. « Notation » = score de jeu, pas une note scolaire (§9) ni liée à la vitesse (§2) ; confirmé par l'utilisateur.

**Score d'une mission** (`MissionScoring`, code pur) : 3 étoiles si tous les exercices sont réussis du premier coup ; 2 si tout est trouvé mais avec au moins un indice ou une explication ; 1 si une réponse a dû être montrée. Une mission terminée rapporte toujours au moins 1 étoile (une erreur n'est jamais punie). `exercise_host` note l'issue de chaque exercice (`first_try`, `with_help`, `revealed`) et la transmet à l'écran de récompense via `GameManager.last_outcomes`.

**Format de sauvegarde — `schema_version` 2** (décision engageant le format, signalée avant implémentation) : nouveau champ obligatoire `mission_results` (mission_id → `best_stars`, `last_stars`, `completions`). `SaveMigration` monte les sauvegardes v1 en v2 en ajoutant `mission_results: {}` ; `rewards.stars` et `rewards.items` existants sont conservés tels quels. Le détail par mission n'existait pas en v1 : une mission déjà rejouée peut donc ajouter ses étoiles une seconde fois (au plus +1 étoile par mission déjà terminée sous v1, accepté plutôt que d'inventer un historique).

**Total d'étoiles** : on n'ajoute que l'amélioration par rapport au meilleur score de la mission (1 puis 3 étoiles = 3, pas 4) ; rejouer pour progresser est encouragé sans gonfler le total. L'ancienne `ProgressUpdates.add_stars` et la récompense fixe d'une étoile sont supprimées.

**Collection** : nouveau type de donnée `data/rewards/*.json` (schéma `reward_item`, validé au chargement et par `make validate-data`, avec contrôle que `mission_id` désigne une mission existante). 10 objets (`draft`) : 7 à seuil d'étoiles totales (3 à 45) et 3 trophées de mission (3 étoiles sur chacune des missions CE1 d'origine). `RewardRules` (pur) calcule les objets nouvellement débloqués ; un objet non débloqué reste « mystère » mais indique toujours comment l'obtenir. Objets sans illustration pour l'instant (texte seul) : l'habillage est la phase suivante.

**Interface** : écran de récompense (étoiles x/3, message sans jugement, « nouveau record », total, nouveaux objets, accès à la collection), écran « Ma collection », total d'étoiles et étoiles par mission sur la carte, marqueurs agrandis (48 px de demi-hauteur) pour trois lignes de texte avec retour à la ligne.

**Tests** : scoring, règles de déblocage, mise à jour de sauvegarde, migration v1→v2, validation du schéma, suivi des issues dans `exercise_host`, écran de récompense et collection de bout en bout. **Non vérifié** (sans écran) : rendu et lisibilité des trois lignes des marqueurs, mise en page de l'écran de récompense et de la collection, défilement de la liste.

**À faire (phases suivantes)** : habillage visuel et illustrations des objets, réglages et espace adulte (dont export/restauration des sauvegardes), son et musique.

## 31. Phase « Habillage visuel » et navigation (version 0.3.0)

**Navigation (demande utilisateur)** : bouton « Changer de profil » sur la carte (sauvegarde avant de quitter) ; bouton « Quitter la mission » dans l'hôte d'exercice avec confirmation. Quitter ne rapporte ni étoile ni objet et n'est jamais compté comme un échec ; les tentatives déjà faites restent enregistrées (vraies observations d'apprentissage) et sont sauvegardées.

**Vérification du rendu** : `tools/screenshot.gd` (`make screenshot`) charge une scène dans une vraie fenêtre et enregistre un PNG, avec actions scriptées (`continue_rule`, `answer:N`, `toggle:N`, `type:…`, `validate`, `outcomes:…`). Il a permis de relire le rendu réel et d'y corriger ce que les tests ne voient pas : marqueurs de la carte qui se chevauchaient (zone de carte plus basse que supposé au point 26), titres tronqués, vignettes de progression vides. Le test d'écart des positions (point 26) reste un garde-fou de données ; le rendu réel passe désormais par ces captures.

**Système visuel** : thème Godot unique (`assets/interface/theme.tres`, appliqué par `project.godot`) : police Atkinson Hyperlegible (libre, conçue pour la lisibilité ; tous les caractères français vérifiés), palette crème/vert/or, boutons à relief, cartes arrondies, focus clavier bleu épais, variantes de type (`SecondaryButton`, `MarkerButton`, `CardTitle`, `HeaderTitle`, `Pill`...). Fenêtre de base 1152x648 avec étirement `canvas_items`. Réussite/erreur : icône (coche / point d'interrogation) en plus du texte, jamais la couleur seule ; étoiles pleines/vides par la forme.

**Illustrations** (SVG vectoriels originaux, provisoires, générés par script jetable) : décors forêt (CE1) et marais (CE2) — le décor suit le niveau de la règle —, hibou Plume, étoiles, pictogrammes de types d'exercice, icônes de retour, 10 objets de collection. Résolution par identifiant dans un répertoire fixe (`ItemIcons`), repli sur un cadenas.

**Écrans refaits** : carte (barre du haut : profil, titre, total d'étoiles, collection ; lieux = cartes avec pictogramme, titre, étoiles ; position fractionnelle étalée sur toute la zone et recalculée au redimensionnement ; Plume en bas), choix et création de profil, introduction de mission (Plume porte le texte narratif, doublon supprimé), hôte d'exercice (décor + carte de contenu, indicateur d'exercice en pastille), panneaux de règle et de retour, récompense (étoiles qui apparaissent, objets débloqués illustrés), collection (grille).

**Animations** : `Motion` (apparition en rebond, fondu) respecte `SettingsManager.animations_enabled` (cahier des charges §11) ; l'écran de réglages qui le pilotera reste à faire (phase suivante).

**Non vérifié** : tactile, clavier virtuel, rendu sur d'autres résolutions que 1152x648, animations en mouvement (les captures montrent l'état final), rendu sous Windows.

## 32. Phase « Réglages et espace adulte » (version 0.4.0)

**Réglages de l'appareil** (`SettingsManager`, `AppSettings` pur) : volume, taille du texte (Normal 1,0 / Grand 1,15 / Très grand 1,3) et animations. Ils sont communs à tous les profils et stockés à part, dans `user://settings.json` (écriture atomique, valeurs hors limites ou fichier abîmé ramenés aux défauts sans erreur) : **le format de sauvegarde des profils n'est pas modifié** (toujours `schema_version` 2). Le volume agit sur le bus principal ; la taille du texte met à l'échelle les tailles du thème global, sauf `HeaderTitle`, `CardTitle` et `Window` (déjà grands, ils feraient déborder les barres d'en-tête ; le titre de la carte est tronqué avec « … » au plus grand réglage). Écran « Réglages » accessible sans barrière depuis la carte et le choix du profil (l'enfant doit pouvoir baisser le son).

**Espace adulte** (depuis les réglages, derrière une barrière) : barrière = un calcul (nombre de 12 à 19 × chiffre de 3 à 9, hasard injecté, `AdultGate`), simple frein à la curiosité et non une protection de sécurité. Contenu : tableau de progrès par profil (étoiles, missions réussies, objets, séances, et pour chaque notion : statut, réussites récentes, aides utilisées) via `ProgressReport` (pur). Une notion est « à retravailler » si son statut est « à réviser » ou si, avec au moins 3 essais récents, moins de 60 % sont réussis : c'est un signal pour l'adulte, formulé sans jugement sur l'enfant.

**Export et restauration** : l'export écrit la sauvegarde du profil telle quelle (JSON versionné) dans `Documents/AventuriersDesMots/` (repli `user://exports` si la plateforme n'expose pas Documents), sans jamais écraser un export précédent (`_2`, `_3`...). La restauration liste ce dossier, valide chaque fichier (migration + schéma ; les illisibles sont signalés et non restaurables) et crée toujours un NOUVEAU profil avec un identifiant neuf : aucun profil existant n'est jamais modifié. Aucun accès réseau, aucun sélecteur de fichier système (limite assumée : l'adulte dépose le fichier dans le dossier indiqué).

**Tests** : AppSettings, ProgressReport, AdultGate, SaveTransfer (export, non-écrasement, restauration non destructive, fichiers invalides, dossier absent), intitulés de notions présents dans la traduction, barrière de l'espace adulte. **Non vérifié** (sans humain) : curseur de volume à l'oreille (aucun son d'interface n'existe encore, phase suivante), tactile, export vers un vrai dossier Documents sous Windows, résolutions autres que 1152x648.

## 33. Phase « Son et musique » (version 0.5.0)

**Sons** : 5 effets (`click`, `success`, `try_again`, `star`, `fanfare`) et 2 musiques d'ambiance en boucle (`forest` pour le CE1, `marsh` pour le CE2), synthétisés de façon procédurale par `tools/generate_sounds.py` (`make generate-sounds`, numpy + ffmpeg, aucun échantillon tiers, donc aucune attribution à ajouter). Résolus par identifiant dans un répertoire fixe (`SoundCatalog`). Fichier absent : avertissement, pas de plantage.

**Intentions** : le retour « à retenter » est une courte phrase de deux notes douces qui montent, jamais un buzzer (une erreur n'est jamais punie) ; la fanfare ne retentit que pour 3 étoiles ou un objet gagné, sans lien avec la vitesse. Musiques calmes, sans percussions. Un clic sur n'importe quel bouton produit le même petit son (`AudioManager` observe les nouveaux boutons ; méta `silent` pour en exclure un).

**Mixage** : bus `Music` et `Effects` créés à l'exécution, enfants du bus principal. Réglages : volume général, musique, effets (trois curseurs, `user://settings.json`, format des sauvegardes de profil inchangé). La musique baisse de 12 dB pendant la lecture d'une dictée pour ne jamais couvrir la voix.

**Voix plus naturelles** : non traité. La voix Piper `fr_FR-siwis-medium` reste la voix provisoire (point 19) ; une voix plus naturelle suppose un enregistrement humain ou un autre modèle à évaluer à l'oreille, ce que je ne peux pas faire ici. Les dictées gardent le badge « voix provisoire ».

**Tests** : catalogue (fichiers présents, aucun chemin libre), `AudioManager` (lecture, musique mémorisée), bus idempotents, bornes des volumes. **Non vérifié** : tout ce qui s'entend (timbre, niveau relatif musique/effets/voix, boucle sans claquement, agrément) ; vérifié seulement : durées et niveaux de crête des fichiers (aucun écrêtage).

**Addendum (0.5.1) — choix de la musique de fond** (demande utilisateur) : 5 morceaux au choix, `forest`, `marsh`, `meadow` (prairie), `river` (rivière), `night` (nuit), plus un choix « Automatique » (par défaut : forêt en CE1, marais en CE2, comme avant). Le choix est un réglage de l'appareil (`music_track` dans `user://settings.json`, valeur inconnue ramenée à « auto ») : le format des sauvegardes de profil est inchangé. Sélectionner un morceau dans les réglages le fait entendre aussitôt. Sons toujours provisoires et jamais écoutés ici.

**Correctif (0.5.2)** : les cinq morceaux de 0.5.1 étaient trop proches (même timbre de nappe + cloches, même niveau) : l'utilisateur n'a pas perçu de différence. Le changement de morceau fonctionnait (vérifié : identifiant, flux et bus corrects à chaque choix) ; seul le matériau sonore était indiscernable. Les morceaux sont désormais construits sur des styles distincts : forêt (nappe + cloches), marais (bourdon grave qui respire, rares cloches creuses), prairie (pizzicati allègres, basse sur le temps), rivière (arpège continu et lié), nuit (boîte à musique aiguë en 3 temps). Mesure objective : centroïde spectral de 220 à 1277 Hz, durée de boucle de 12 à 46 s, densité d'attaques de 3 à 36/s. Toujours jamais écouté ici.

## 34. Corrections du 12 octobre (version 0.5.3)

**Export cassé sur dépôt frais** : sur un clone sans `.godot/`, `make export-*` échouait (erreurs de chargement des polices et du thème, segfault de l'export, aucun binaire). Cause : le thème global est chargé au démarrage avant que les polices soient importées, donc une première passe d'import échoue ; le dépôt ne versionne pas `.godot/`. Correctif : cible `make import` (deux passes, la première tolérée en échec), prérequis de `run`, `test`, `validate-data`, `export-linux`, `export-windows`, `screenshot`. Vérifié sur un clone neuf : `make export-linux` produit un binaire qui démarre sans erreur. L'export avec Godot 4.7.2 (celui de l'utilisateur dans `~/bin`) fonctionne aussi ; le projet reste épinglé en 4.6.3 (`.godot-version`).

**Élisions** : aucune élision manquante (« le arbre ») dans les données, vérifié sur tous les JSON y compris les listes de jetons ; garde-fou permanent `tests/data/test_elision.gd` (mots à « h » aspiré et exceptions listés ; l'assertion arrière écarte « écris-la en »). Si l'élision manquante vue en jeu vient d'ailleurs que des données, il faudra l'indication de l'écran concerné.

**Phrases en double** : 14 phrases apparaissaient dans deux exercices ou dans un exercice et une dictée (ex. « Le chat dort. »). Les énoncés des QCM et corrections concernés ont été remplacés par de nouvelles phrases originales (indice et explication ajustés) ; les dictées, dont l'audio est généré, n'ont pas été touchées. Garde-fou permanent `tests/data/test_no_duplicate_sentences.gd` (phrase reconstituée en version correcte, comparée sans casse ni ponctuation).

## 35. Plantage après redémarrage, profil relu depuis le disque (version 0.5.4)

**Bug** : `ProgressUpdates.next_difficulty_for_skill` affectait le tableau `recent_results` d'une sauvegarde relue depuis le JSON (un `Array` non typé) à un `Array[bool]` : erreur de script, l'exercice suivant ne se chargeait pas (blocage/plantage), dès qu'un profil avait déjà de l'historique sur la notion. Les tests ne le voyaient pas car ils construisaient l'état en mémoire (tableaux typés) sans passer par le disque. Signalé par l'utilisateur sur « La serre aux étiquettes » (profil CE2 existant). Corrigé par recopie dans un `Array[bool]` ; test de non-régression qui passe l'état par `JSON.stringify`/`parse`.

**Vérification** : copie des vrais profils de l'utilisateur dans un profil temporaire, puis parcours de chaque écran (récompense, carte, collection, espace adulte, réglages, introduction, choix de profil) et chargement de toutes les missions de leur niveau : aucune erreur de script. À retenir : tout état relu de JSON doit être converti avant d'être affecté à un tableau typé.

**Son (non reproduit)** : sur la machine de développement, les exports Linux (4.6.3 et 4.7.2) jouent bien la voix de la dictée par le parcours réel (flux PipeWire non coupé, niveau mesuré sur le moniteur du périphérique). Cause de l'absence de son chez l'utilisateur non identifiée ; diagnostic demandé (pilote audio, sortie par défaut, messages console).

## 36. Redites : jamais deux fois le même exercice dans une mission (version 0.5.5)

**Cause du « même énoncé deux fois »** : le tirage n'excluait que le dernier exercice vu, donc une mission de 3 exercices pouvait donner A, B, A (le point 34 n'avait traité que les doublons de contenu). Le tirage exclut maintenant tous les exercices déjà vus dans la mission (`ExercisePicker.pick_unseen`, `ExerciseEngine.pick_unseen_exercise_for_mission`) : d'abord à la difficulté visée, puis toutes difficultés, et ne répète que si le contenu est épuisé. Test de non-régression sur l'hôte d'exercice (10 missions simulées).

**Phrases quasi identiques** : 14 énoncés (QCM et corrections) trop proches d'une autre phrase (ex. « Les petits chiens courent. » / « Les petits chiens jouent. » / « Les petits chiens courent vite. ») ont été remplacés par des phrases originales distinctes, indices et explications ajustés. Garde-fou permanent `tests/data/test_no_near_duplicate_sentences.gd` : deux phrases d'au moins 4 mots ne peuvent pas partager 75 % ou plus de leurs mots. Les dictées (audio déjà généré) n'ont pas été modifiées.

**Voix** : l'utilisateur confirme que la voix de synthèse (« La fleur est belle. ») fonctionne avec le build Linux.

## 37. Suppression d'un profil réservée à l'adulte (version 0.5.6)

Demande utilisateur. Le bouton « Supprimer » est retiré de la sélection de profil (côté enfant) ; la suppression se fait dans l'espace adulte, derrière la barrière (point 32), via « Supprimer ce profil » avec une confirmation explicite qui nomme le profil et rappelle de l'exporter avant. Une suppression n'affecte jamais un autre profil. Le cahier des charges §9 (confirmation explicite) est respecté.

## 38. Plusieurs « tableaux » par niveau, niveaux CM1/CM2, tableau pilote (version 0.6.0)

Demande utilisateur : chaque niveau peut avoir jusqu'à 3 tableaux (lieux : forêt, marais, plage…) traitant d'autres règles de grammaire et d'orthographe, avec la même exigence « aucune phrase en double », et le jeu s'ouvre à CM1 et CM2 sur le même principe. Les notions s'inspirent de ce que travaillent les cahiers de ce type ; **seules les règles sont reprises, tous les textes sont originaux** (invariant du projet : rien du BLED n'est reproduit, son nom n'apparaît pas).

**Format (validé par l'utilisateur avant implémentation)** : le niveau scolaire des schémas (`save`, `rule`, `curriculum`, `dictation`, exercices) passe de CE1/CE2 à CE1/CE2/CM1/CM2. Ajout compatible : aucun profil existant n'est migré, `schema_version` reste 2 ; une ancienne version du jeu ne lirait pas un profil CM. La liste est unique (`SchoolLevels`, testée contre les schémas).

**Tableau = fichier de `data/curriculum/`** : nouveaux champs optionnels `region_title` (nom affiché), `order` (1 à 3) et `backdrop` (décor, liste fermée `BackdropKinds`, testée contre l'art disponible). Une mission appartient au tableau qui contient sa règle : aucun champ de plus dans les missions ni dans les sauvegardes. Garde-fous (`test_curriculum`) : une règle dans un seul tableau, du bon niveau, 3 tableaux maximum par niveau, toute mission rattachée à un tableau.

**Carte** : bouton « Aller : <tableau suivant> » pour passer d'un tableau à l'autre ; « Revoir le <niveau précédent> » / « Retour au <niveau> » généralisé ; on revient au dernier tableau consulté après une mission. Décor et musique automatique suivent le tableau (plage → morceau « rivière »). Création de profil : seuls les niveaux ayant du contenu sont proposés (CM1/CM2 apparaîtront avec leur premier tableau).

**Tableau pilote CE1 « La plage des sons »** (`order` 2, décor plage) : 3 règles (s/ss entre deux voyelles, c/ç devant a-o-u, m devant m-b-p), 24 QCM, 12 corrections, 9 dictées (voix Piper provisoire, audio généré), 9 missions, compétence « sons et lettres ». Contenu entièrement `draft`. Unicité : tous les énoncés passent les gardes-fous de phrases en double et quasi doubles (points 34 et 36).

**Reste à faire** : CE1 tableau 3 (« La montagne des verbes »), CE2 tableaux 2 et 3, CM1 et CM2 (3 tableaux chacun), d'autres décors et musiques par tableau. **Non vérifié** : lisibilité des nouvelles voix de dictée, pertinence pédagogique des règles et du niveau de difficulté (à relire), autres résolutions.

## 39. Tableaux CE1 n°3, CE2 n°2 et n°3 (version 0.7.0)

Suite du point 38, sur le même principe que le tableau pilote. Génération par script jetable, validée par les tests et les gardes-fous ; contenu entièrement `draft`.

- **CE1 n°3 « La montagne des verbes »** (décor montagne, compétence « verbes au présent ») : être au présent, avoir au présent, verbes en -er au présent.
- **CE2 n°2 « Le désert des verbes »** (décor désert, compétence « verbes : accords et formes ») : accord sujet-verbe (sujet éloigné ou double), é/er (test « vendre/vendu »), futur simple des verbes en -er.
- **CE2 n°3 « L'île des lettres »** (décor île, compétence « lettres et mots ») : féminin des noms et adjectifs, g/ge/gu, lettre muette finale (féminin, mot de la même famille).

Volume : 3 tableaux × 3 règles × (8 QCM + 4 corrections + 3 dictées) = 72 QCM, 36 corrections, 27 dictées (voix Piper provisoire, audio généré) et 27 missions (n° 31 à 57). CE1 compte maintenant 3 tableaux (27 missions), CE2 3 tableaux (30 missions). Nouveaux décors vectoriels : montagne, désert, île ; musique automatique associée (montagne → « prairie », désert → « nuit », île → « rivière »).

**Correctif de contenu** : dans le tableau pilote, la bonne réponse des QCM était toujours en première position (devinable sans lire). Les réponses sont désormais mélangées de façon déterministe ; garde-fou `test_curriculum` : aucune règle ne peut avoir sa bonne réponse toujours au même rang.

**Unicité** : les gardes-fous de doublons et de quasi-doublons ont attrapé 6 collisions pendant la rédaction, toutes corrigées avant livraison (phrases reformulées).

**Reste** : CM1 puis CM2 (3 tableaux chacun), à lancer après relecture de ces tableaux. **Non vérifié** : voix des 27 nouvelles dictées, niveau de difficulté et justesse pédagogique (indices, formulations), notamment le test « vendre/vendu » et la règle du futur, à faire relire.

## 40. CM1 et CM2, bouton « Quitter le jeu » (version 0.8.0)

**Quitter** (demande utilisateur) : bouton « Quitter le jeu » sur le choix du profil et dans les réglages (donc accessible depuis la carte), avec confirmation ; la progression du profil courant est sauvegardée avant la sortie (`GameManager.quit_game`, point d'arrêt remplaçable dans les tests).

**CM1 et CM2** : mêmes principes que CE1/CE2 (3 tableaux, 3 règles par tableau, 8 QCM + 4 corrections + 3 dictées par règle, 3 missions par règle). Contenu entièrement `draft`, rédigé en réutilisant les règles de cadrage du point 38 (règles inspirées de ce type de cahier, textes originaux).

- **CM1** : « Le château des homophones » (leur/leurs, ces/ses, c'est/s'est) ; « Le village des verbes » (imparfait, forme du participe passé, accord du participe avec être) ; « La jungle des mots » (pluriel en -aux/-eaux/-oux, ou/où, la/là/l'a).
- **CM2** : « La station des homophones » (quel/qu'elle, quand/quant/qu'en, plutôt/plus tôt) ; « Le volcan des verbes » (futur ou conditionnel, passé simple, accord du participe avec avoir et COD placé avant) ; « La bibliothèque des mots » (adverbes en -emment/-amment, -tion/-sion/-ssion, adjectifs de couleur).

Volume : 6 tableaux, 18 règles, 144 QCM, 72 corrections, 54 dictées (voix Piper provisoire, audio généré), 54 missions (n° 58 à 111). Le jeu compte 111 missions. Six nouveaux décors vectoriels (château, village, jungle, espace, volcan, bibliothèque) avec musique associée.

**Contrôles** : les gardes-fous de doublons et de quasi-doublons ont attrapé 14 collisions pendant la rédaction (dont avec CE2), toutes corrigées. Aucune dictée ne contient de point d'interrogation ou d'exclamation isolé (l'espace insécable avant « ? » rend la saisie ambiguë) ; ces phrases sont réservées aux QCM et corrections.

**Reste / limites** : CM1 et CM2 n'ont pas été relus pédagogiquement (indices, niveau de difficulté, règles du passé simple et de l'accord du participe avec COD, à faire valider) ; voix des 54 dictées non écoutées ; la création de profil propose désormais 4 niveaux (CE1, CE2, CM1, CM2).

**Correctif (0.8.1) — mots touchés avec élision** : dans « La coulée de lave », le mot touché était « j'achèterai » mais l'attendu « achèterais » (sans « j' ») : la réponse naturelle « j'achèterais » était refusée. Données corrigées (attendu « j'achèterais ») et validateur rendu tolérant : pour un mot touché avec élision, on accepte le mot entier ou seulement le verbe, avec apostrophe droite ou typographique. Tests : validateur (formes acceptées et refusées) et garde-fou de données (un attendu ne perd pas le préfixe d'élision du mot touché).

**Relecture CM1/CM2 (0.8.2)** — relecture complète des 144 QCM et 72 corrections, plus un audit automatique (attendu identique au texte, indice qui donne la réponse, dictées sans mot cible). Problèmes trouvés et corrigés :

- **Défaut de validation (le plus grave)** : un mot touché portant la ponctuation de la phrase (« roze. », « vertes. ») avait un attendu avec point ; taper « rose » sans point était refusé. La comparaison ignore maintenant la ponctuation finale, des deux côtés (concerne aussi le pilote CE1 et les tableaux CE2).
- **Énoncés ambigus** (les deux réponses étaient défendables) : ces/ses (« Julie a oublié … clés », « Pourquoi achètes-tu … pommes ? », « Léa a rangé ces affaires »), passé simple contre imparfait (sept énoncés sans marqueur d'action unique : « Soudain », « Puis… partit », « Enfin »…), futur contre conditionnel (« Ce soir, il … plus tard »), plutôt/plus tôt (« Je me couche … le samedi soir »). Reformulés avec un marqueur sans équivoque.
- **Faux mot « réel » comme distracteur** : « éruction » (mot qui existe) remplacé par « érupsion ».
- **Accord avec « être »** : « les enfants » n'est pas forcément masculin (remplacé par « les garçons »).
- **Indices qui donnent la réponse** (3 couleurs, « la ») : reformulés.
- **Énoncé de règle incomplet** : « travail → travaux » ajouté à la règle des pluriels en -aux.

**Non vérifié** : lecture faite par Claude, pas par un enseignant ; l'ambiguïté résiduelle possible (ex. « marron » parfois accordé dans l'usage) est assumée au profit de la norme.

**Relecture CE1/CE2 (0.8.3)** — même audit que pour les CM, sur les 6 tableaux CE1 et CE2 (QCM, corrections, dictées, règles). Trouvé et corrigé :

- **« Le arbre » (CE1, accord du déterminant)** : l'énoncé « ... arbre est grand. » avec les réponses Le/La n'avait aucune bonne réponse (il faut « l'arbre »). Remplacé par « ... fromage est délicieux. ». Même défaut, de la même famille, dans « La ... du volcan » (CM2, éruption) devenu « L'... du volcan ». Le garde-fou d'élision ne lisait pas les phrases à trous : il reconstitue maintenant la phrase correcte (blanc rempli, mot fautif corrigé) avant de la contrôler.
- **Règle g/ge/gu inexacte** : on écrit « ge » devant a et o (pas u) pour garder le son doux ; énoncé corrigé.
- **Pluriel en -x dans la règle du pluriel en -s** (CE1) : « oiseaux » remplacé par « arbres » (les pluriels en -aux/-eaux sont l'objet du CM1).
- **Indice qui donnait la réponse** (« avoir » avec « je ») reformulé.

Les corrections et les dictées CE1/CE2 n'ont pas révélé d'autre problème ; les tests de doublons, quasi-doublons et de position de la bonne réponse sont verts. **Non vérifié** : relecture par un enseignant.

**Plateformes et touche Entrée (0.9.0)**

- **Entrée valide** : dans la dictée et dans les champs de correction, la touche Entrée équivaut au bouton « Valider ». L'hôte d'exercice ignore toute validation tant que le panneau de retour est ouvert (une seule réponse comptée par essai).
- **Nouvelles cibles** : `make export-android` (APK arm64 + x86_64), `make export-macos` (application universelle, zip, signature ad hoc, non notariée), `make export-web` (Compatibility, sans threads). `make package` produit cinq archives.
- **ChromeOS** : pas de cible propre au moteur ; l'archive regroupe l'APK (runtime Android) et la version web à servir en local. Le binaire Linux couvre aussi Crostini.
- **Signature Android** : clé de débogage publique de Godot, via variables d'environnement (aucun secret dans le dépôt). Une publication sur un magasin demandera une vraie clé (`GODOT_ANDROID_KEYSTORE_RELEASE_*`).
- **Réglage de projet** : import ETC2/ASTC activé (exigé par les exports mobile et macOS universel).
- **Non vérifié** : aucune des trois nouvelles versions n'a été lancée sur un appareil. Le tactile (clavier virtuel Android pour les champs de saisie, taille des boutons), le stockage `user://` et l'audio sur Android/web restent à tester à la main.

**Son sur la version web (0.9.1)** : Godot 4.6 joue par défaut les sons du web en mode « échantillon » (Web Audio direct), qui ignore les bus créés à l'exécution (Music/Effects) et leurs volumes. Réglage `audio/general/default_playback_type.web = Stream` : le son passe par le moteur audio comme sur bureau. **Non vérifié** : aucun navigateur avec sortie audio dans l'environnement de développement ; à tester à la main (premier clic requis par le navigateur avant tout son).

**Lancement de la version web (0.9.2)** : `make serve-web` (export puis serveur local sur 127.0.0.1, ouverture du navigateur) et, dans l'archive ChromeOS, `lancer-web.sh` / `lancer-web.bat` / `lancer-web.py`. Retour de test manuel de l'utilisateur : Linux, Android et web fonctionnent ; Windows, macOS et ChromeOS restent à tester. README, cahier des charges (public CE1 à CM2, 7–11 ans) et listes de contrôle mis à jour pour CM1/CM2.

**Publication des versions (0.9.2)** — le dépôt est public (AGPL-3.0). Choix validé par l'utilisateur : cible `make release` (choix B), pas de CI pour l'instant.

- **Release** : `tools/release.sh` exige la branche `main` à jour de `origin`, un arbre propre, un tag `vX.Y.Z` inexistant, `make check` vert, puis `make package`, vérifie `SHA256SUMS`, refuse un APK signé avec la clé de débogage Godot, crée le tag annoté et la Release **pre-release** (tant que les enseignants n'ont pas validé le contenu ; `STABLE=1` ensuite). `make release-dry-run` fait tout sauf tag et publication.
- **Clé de publication Android** : générée localement (RSA 4096, validité 10000 jours, alias `aventuriers`), hors dépôt : `~/.local/share/aventuriers-des-mots/release.keystore` ; identifiants dans `~/.config/aventuriers-des-mots/release.env` (droits 600). **À sauvegarder hors de la machine** : une clé perdue ne se remplace pas, et changer de clé oblige les appareils à désinstaller avant de réinstaller. `make export-android` la lit automatiquement ; sans elle, repli sur la clé de débogage (essais locaux seulement).
- **Contrôle des secrets avant ouverture** : historique complet relu (fichiers, motifs de clés/jetons/mots de passe, chemins personnels) : rien. Seule donnée personnelle : l'adresse e-mail de l'auteur dans les métadonnées des commits et dans ce fichier (décision de l'utilisateur).

**Barre d'accents (0.9.3)** — sur Android (et partout où le clavier n'est pas réglé en français), l'enfant ne peut pas saisir les accents. Une rangée de boutons « é è ê ë à â î ï ô û ù ü ç œ » apparaît sous le champ de la dictée et sous les champs de correction ; la touche ⇧ bascule en majuscules (« É », « À »…) pour **une seule** lettre (la dictée exige la majuscule initiale).

- Les boutons ne prennent pas le focus : le champ garde le clavier, le curseur est respecté (`AccentInserter`, pur et testé).
- Dans la correction, la barre suit le dernier champ focalisé et se masque quand aucun mot n'est sélectionné.
- Toujours affichée (aucun réglage) : elle aide aussi un clavier étranger sur ordinateur. Conseil de clavier Android (Gboard français AZERTY ou HeliBoard) à documenter dans le `LISEZMOI` : non fait.
- **Non vérifié** : rendu et maniabilité au doigt sur un vrai appareil Android (taille des touches 52 px, retour à la ligne de la rangée sur petit écran).

**Google Play (0.9.3)** — décision de l'utilisateur : viser Google Play, principalement pour les Chromebooks scolaires. Côté dépôt : preset « Android Play » (Gradle, App Bundle `.aab`, arm64 + x86_64, minSdk 24, cible Android 16) et cibles `make android-template` / `make export-play` ; le bundle est signé avec la clé de publication (refus sans elle). `android/` (modèle Gradle) est ignoré par git. La publication elle-même (compte, fiche, public « enfants », politique de confidentialité) relève du propriétaire : guide dans `docs/distribution/play-store.md`. **Non vérifié** : aucun envoi à la Play Console, installation du bundle non testée.

**Retrait de Google Play, passage à F-Droid (0.9.3)** — décision de l'utilisateur : pas de frais Google. Le preset « Android Play », `make export-play` et `make android-template` (ajoutés puis retirés le même jour) sont supprimés ; l'APK reste l'artefact Android. Pour F-Droid : métadonnées `fastlane/metadata/android/fr-FR/` (ignorées de Godot et des exports), APK publié seul dans chaque Release en plus de `android.zip`, guide `docs/distribution/fdroid.md`. Voie recommandée : dépôt IzzyOnDroid (APK du développeur, depuis les Releases) ; F-Droid officiel (recompilation de Godot depuis les sources) reporté. **Non vérifié** : aucune demande déposée ; les Chromebooks scolaires gérés restent un cas ouvert (web, Linux ou APK selon l'établissement).

**IzzyOnDroid et APK arm64 (0.9.3)** — décision de l'utilisateur : tenter IzzyOnDroid, avec dépôt F-Droid personnel en secours. IzzyOnDroid plafonne les APK à 30 Mo : un second preset « Android arm64 » produit un APK arm64 seul (≈ 28,4 Mo), publié seul dans la Release (`…-android-arm64.apk`) ; l'APK arm64 + x86_64 reste dans `android.zip`. `make release` refuse un APK de plus de 30 000 000 octets (marge actuelle : environ 190 Ko seulement). Demande : ticket sur le suivi Codeberg d'IzzyOnDroid ; brouillon dans `docs/distribution/izzyondroid-request.md`, qui déclare le développement assisté par IA (leur politique rejette les applications « vibe-coded » : refus possible, à assumer). Le dépôt F-Droid personnel n'est pas encore mis en place. **Non vérifié** : acceptation, installation via un client F-Droid.

**Dépôt F-Droid personnel (0.9.4)** — mis en place en attendant la réponse d'IzzyOnDroid (voie 2 de `docs/distribution/fdroid.md`). `tools/fdroid_repo.sh` (`make fdroid-repo` / `make fdroid-publish`) construit un dépôt avec `fdroidserver` 2.4.5 à partir de l'APK arm64 de `dist/` (signature de publication d'origine conservée), index signé par une clé de dépôt distincte créée au premier lancement (hors dépôt, droits 600, **à sauvegarder**), trois dernières versions conservées, publication par force-push d'une branche orpheline `gh-pages` servie par GitHub Pages à `https://deunix-educ.github.io/aventuriers-des-mots/repo`. Texte et images localisés repris de `fastlane/`. **Vérifié** : construction locale, index (`index-v1.json`) contenant l'application, sa licence, ses catégories, l'ABI arm64 et le bon certificat de signature. **Non vérifié** : publication, activation de Pages, installation depuis un client F-Droid sur un appareil.

**Dépôt F-Droid publié (0.9.4)** — branche `gh-pages` poussée, GitHub Pages actif (source `gh-pages`, `/`), dépôt en ligne à `https://deunix-educ.github.io/aventuriers-des-mots/repo` : index et APK servis, APK identique (SHA-256) à celui de `dist/`. Adresse et empreinte de la clé du dépôt ajoutées aux README. **Non vérifié** : ajout et installation depuis un client F-Droid sur un appareil.

**Adresse du dépôt corrigée (0.9.4)** — le client F-Droid avertit « Repo address might be malformed (missing '/fdroid/repo') » : l'adresse est désormais `https://deunix-educ.github.io/aventuriers-des-mots/fdroid/repo` (dossier `fdroid/repo/` de la branche `gh-pages`). La clé du dépôt, donc l'empreinte, ne change pas ; l'ancienne adresse `/repo` n'existe plus. Anciennes mentions ci-dessus : lire `/fdroid/repo`.
