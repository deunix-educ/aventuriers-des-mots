Cahier des charges fonctionnel et technique
Jeu éducatif de français CE1 à CM2 — Godot 4 / GDScript
Jeu éducatif CE1 à CM2 sous Godot 4 et GDScript, fondé sur les règles du BLED. Style : aventure 2D avec carte, personnages et missions. Exercices : grammaire, orthographe et dictées. Public : plusieurs profils d'enfants sur appareil familial. Fonctionnement hors ligne : oui. Prévoir architecture modulaire, progression pédagogique CE1/CE2, système de correction explicative, sauvegarde et export Linux, Windows, macOS, Android et iOS.

Direction artistique indicative : un monde de mots, des personnages attachants et une aventure adaptée aux enfants de 7 à 11 ans.

1. Présentation du projet
Nom de travail : Les Aventuriers des mots
L'objectif est de développer un jeu éducatif en 2D permettant aux enfants de CE1 à CM2 d'acquérir, de consolider et d'approfondir les règles de grammaire et d'orthographe françaises, à travers une aventure interactive inspirée de la progression pédagogique du BLED.
Le jeu doit combiner trois dimensions :
- Pédagogique : des règles clairement expliquées, des exercices progressifs, des dictées et des corrections détaillées.
- Ludique : une carte à explorer, des personnages, des missions, des objets à collectionner et des récompenses.
- Technique : une application autonome, modulaire, fonctionnant sans connexion Internet et disponible sur ordinateurs et appareils mobiles.
Le jeu ne doit pas être un simple questionnaire habillé d'un décor. La progression dans l'aventure doit donner du sens aux apprentissages, tandis que les mécanismes pédagogiques doivent garantir que l'enfant progresse réellement.
Fiche d'identité
Élément	Spécification
Public cible	CE1 à CM2, environ 7–11 ans (CM1 et CM2 ajoutés en cours de projet : voir decisions.md, points 38 à 40)
Moteur	Godot 4.x, version stable retenue au démarrage
Langage	GDScript typé
Graphismes	2D, illustrations originales, animations
Plateformes	Linux, Windows, macOS, Android, iOS
Connexion	Aucune nécessaire en fonctionnement normal
Utilisateurs	Plusieurs profils enfants sur un même appareil
Sauvegarde	Locale, persistante, par profil
Contenu	Grammaire, orthographe, conjugaison, dictées
Référence pédagogique	Règles et progression inspirées du BLED, à valider
Réseau	Non requis pour jouer, progresser ou sauvegarder
2. Vision pédagogique
Le jeu s'appuie sur un cycle d'apprentissage commun à chaque notion :
1. Découvrir la règle
Explication courte, exemple illustré, lecture audio facultative.

2. S'entraîner avec de l'aide
Exercices guidés, indices et démonstrations.

3. Réussir une mission
Application de la règle dans un défi ludique.

4. Consolider les acquis
Révisions différées, exercices variés et dictées ciblées.


Principes pédagogiques obligatoires
1. Une erreur déclenche une explication, pas une punition.
2. Les consignes sont courtes, adaptées à l'âge et accompagnées d'exemples.
3. La difficulté évolue en fonction des résultats, sans bloquer durablement l'enfant.
4. Une règle n'est pas considérée comme acquise sur la seule base d'une réussite isolée.
5. Les exercices alternent reconnaissance, manipulation, application et production écrite.
6. Les récompenses valorisent les efforts, la compréhension et la progression, pas uniquement la rapidité.
3. Univers du jeu et direction artistique
Le monde est divisé en régions pédagogiques. Chaque région possède son identité graphique, ses personnages et ses objectifs.

Région 1 — Le village des phrases
Découverte du nom, du déterminant, du verbe, de l'adjectif et de la construction des phrases. Niveau d'entrée CE1.

Région 2 — La forêt des accords
Genre, nombre, pluriels, accords dans le groupe nominal et accords entre le sujet et le verbe.

Région 3 — Le château des verbes
Présent, futur, imparfait et autres formes travaillées dans la progression retenue, avec des défis de conjugaison.

Région 4 — Les grottes de l'orthographe
Homophones grammaticaux, graphies difficiles, mots fréquents et dictées thématiques.

Les régions pourront être débloquées progressivement. Le contenu CE2 approfondira les mêmes notions ou ouvrira des zones spécifiques, plutôt que de simplement augmenter le nombre de questions.
Personnages principaux
- Plume, le hibou : explique les règles et fournit des indices.
- Milo, le jeune explorateur : accompagne l'enfant dans les missions.
- Les gardiens des mots : proposent les défis de chaque région.
- Les personnages des missions : donnent un contexte narratif aux exercices.
L'enfant pourra choisir un avatar et personnaliser certains éléments cosmétiques. Ces éléments ne doivent pas donner d'avantage pédagogique.
4. Progression pédagogique CE1 et CE2
Le contenu sera organisé en chapitres, notions, règles, exercices et évaluations. La progression ci-dessous est une proposition initiale à confronter aux programmes en vigueur et aux éditions du BLED retenues.
Parcours CE1 — Acquérir les bases
1. Les mots et leur nature : nom, déterminant, verbe, adjectif et pronoms usuels.
2. Le groupe nominal : genre, nombre, déterminants, accords simples et marques du pluriel.
3. La phrase : majuscule, ponctuation, ordre des mots, phrase déclarative et interrogative.
4. Le sujet et le verbe : identification et accords simples dans les phrases étudiées.
5. La conjugaison : formes et personnes des verbes usuels, aux temps retenus dans la progression.
6. L'orthographe : mots fréquents, sons et graphies, lettres muettes, pluriels et difficultés lexicales adaptées.
7. Les premières dictées : mots, groupes de mots et phrases courtes.

Parcours CE2 — Approfondir et réinvestir
1. Les classes grammaticales : approfondissement des catégories et de leur rôle dans la phrase.
2. Les accords : groupe nominal, sujet-verbe et cas plus variés.
3. La conjugaison : régularités, verbes usuels, personnes et temps du programme retenu.
4. Les homophones : notamment a/à, et/est, son/sont, on/ont, avec des tests de substitution simples.
5. L'orthographe lexicale : mots fréquents, familles de mots et graphies à mémoriser.
6. La correction de textes : repérage et correction de plusieurs erreurs dans un contexte.
7. Les dictées : dictées préparées, dictées ciblées et courtes dictées de synthèse.

Chaque notion devra être reliée à une règle explicite, à des prérequis et à des exercices de difficultés différentes. Un enfant de CE2 qui rencontre une difficulté sur une notion de CE1 pourra revenir à un entraînement adapté sans perdre sa progression dans l'aventure.

5. Catalogue des types d'exercices
Le moteur d'exercices sera indépendant des décors. Une même mécanique pourra donc être utilisée dans plusieurs régions avec des contenus différents.
Type d'exercice	Interaction	Compétence
Choix multiple	Sélectionner une réponse	Reconnaissance d'une règle
Mot à compléter	Choisir ou saisir les lettres manquantes	Orthographe lexicale
Tri de mots	Déplacer les mots vers des catégories	Classes grammaticales
Phrase à reconstruire	Ordonner les éléments	Syntaxe
Correction de phrase	Repérer et corriger les erreurs	Grammaire et orthographe
Conjugaison	Choisir ou saisir une forme verbale	Morphologie verbale
Dictée	Écouter puis écrire	Orthographe et accords
Défi mixte	Résoudre plusieurs questions liées	Réinvestissement
Dictées : exigences particulières
Les dictées ne doivent pas être traitées comme de simples questions à choix multiple.
Le système devra proposer :
- une lecture audio de la consigne et du texte, avec commandes de lecture et de répétition ;
- une zone de saisie adaptée au clavier et aux écrans tactiles ;
- une comparaison de la production avec le texte cible ;
- une analyse des erreurs orthographiques, des accents et des accords ;
- une correction qui explique chaque erreur en fonction de la règle travaillée ;
- une nouvelle tentative, sans sanction excessive ;
- des dictées courtes, puis des dictées de synthèse.
La correction devra distinguer une erreur lexicale d'une erreur grammaticale lorsqu'une classification fiable est possible. Les réponses ambiguës ne devront pas être déclarées fausses automatiquement sans vérification.
Pour les dictées, il faudra définir les règles de tolérance : accents, apostrophes, majuscules, ponctuation, variantes admises et erreurs multiples dans un même mot. Les caractères français, dont é, è, ê, ç et œ, devront être gérés correctement.

6. Système de correction explicative
C'est l'un des composants les plus importants du projet.
Exemple : l'enfant écrit « Les petit chiens courent ».
Retour pédagogique

Phrase proposée par l'enfant
Les petit chiens courent.
Correction proposée
Les petits chiens courent.

Pourquoi ?
Le déterminant « les » indique un pluriel. L'adjectif « petit » s'accorde avec le nom « chiens » et prend donc la marque du pluriel : « petits ».

Pour t'aider à retenir
« Quand un adjectif accompagne un nom, il s'accorde généralement avec ce nom en genre et en nombre. »
Prochain défi : retrouver les marques du pluriel dans trois autres groupes nominaux.

Fonctionnement interne
Le moteur de correction devra retourner une structure exploitable par l'interface, comprenant :
- le résultat global ;
- les erreurs identifiées et leur position ;
- la règle concernée ;
- l'explication adaptée au niveau ;
- un indice facultatif ;
- une ou plusieurs propositions de remédiation.
Les explications seront préparées et validées dans les données pédagogiques, plutôt que générées automatiquement au moment de chaque erreur. Cela garantit un fonctionnement hors ligne, une cohérence des règles et un contrôle de la qualité pédagogique.

7. Architecture technique Godot 4
Je recommande une architecture modulaire, avec une séparation stricte entre le moteur du jeu, les données pédagogiques et la progression de chaque enfant.
Arborescence proposée

aventuriers_des_mots/
├── project.godot
├── autoload/
│   ├── game_manager.gd
│   ├── profile_manager.gd
│   ├── progress_manager.gd
│   ├── exercise_engine.gd
│   ├── save_manager.gd
│   ├── audio_manager.gd
│   └── settings_manager.gd
├── scenes/
│   ├── boot/
│   │   └── boot.tscn
│   ├── profiles/
│   │   ├── profile_select.tscn
│   │   └── profile_create.tscn
│   ├── world/
│   │   ├── world_map.tscn
│   │   ├── region.tscn
│   │   └── mission_intro.tscn
│   ├── exercises/
│   │   ├── exercise_host.tscn
│   │   ├── multiple_choice.tscn
│   │   ├── word_sort.tscn
│   │   ├── sentence_builder.tscn
│   │   ├── sentence_correction.tscn
│   │   ├── conjugation.tscn
│   │   └── dictation.tscn
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── rule_panel.tscn
│   │   ├── feedback_panel.tscn
│   │   ├── reward_screen.tscn
│   │   └── pause_menu.tscn
│   └── characters/
│       ├── avatar.tscn
│       └── guide_owl.tscn
├── scripts/
│   ├── models/
│   │   ├── exercise_data.gd
│   │   ├── rule_data.gd
│   │   └── player_progress.gd
│   ├── correction/
│   │   ├── answer_validator.gd
│   │   └── dictation_analyzer.gd
│   └── pedagogy/
│       ├── difficulty_manager.gd
│       └── review_scheduler.gd
├── data/
│   ├── curriculum/
│   ├── rules/
│   ├── exercises/
│   │   ├── ce1/
│   │   └── ce2/
│   ├── dictations/
│   └── localization/
├── assets/
│   ├── characters/
│   ├── environments/
│   ├── interface/
│   ├── audio/
│   ├── fonts/
│   └── animations/
└── tests/
    ├── test_corrections.gd
    ├── test_progression.gd
    ├── test_saves.gd
    └── test_exercise_data.gd


Cette arborescence est un point de départ : il faudra ajuster les fichiers selon les responsabilités réelles et éviter de multiplier les modules sans nécessité.
Autoloads : responsabilités
Module	Rôle
GameManager	Cycle de vie, navigation et état général
ProfileManager	Création, sélection et suppression des profils
ProgressManager	Compétences, missions et révisions
ExerciseEngine	Chargement et déroulement des exercices
SaveManager	Sérialisation et sauvegardes
AudioManager	Voix, dictées, musiques et effets sonores
SettingsManager	Volume, taille du texte et préférences
Les scènes doivent rester autonomes et communiquer par des signaux Godot ou par des interfaces clairement définies. Une scène de dictée ne doit pas gérer elle-même les sauvegardes ou la progression générale.

Cycle de vie d'un exercice
mermaid-diagram.png joint

8. Format des données pédagogiques
Les exercices doivent être des données, et non du code spécifique à chaque question. Un fichier JSON permet de modifier, vérifier et enrichir le contenu sans toucher aux scènes Godot.
Exemple illustratif d'un exercice de CE1 :

{
  "id": "ce1_accord_001",
  "level": "CE1",
  "domain": "grammaire",
  "skill": "accord_groupe_nominal",
  "rule_id": "regle_accord_adjectif",
  "difficulty": 1,
  "type": "multiple_choice",
  "instruction": "Choisis le bon groupe de mots.",
  "question": "Les ... chiens jouent.",
  "answers": [
    "petit",
    "petits",
    "petite"
  ],
  "correct_answer": 1,
  "hint": "Observe le déterminant « les » et le nom « chiens ».",
  "explanation": "Le groupe nominal est au pluriel. L'adjectif prend ici la marque du pluriel.",
  "review_tags": [
    "pluriel",
    "accord_adjectif"
  ]
}

Le schéma définitif devra préciser les champs obligatoires, les formats de réponse, les règles de validation et les références aux fichiers audio.
Pour les dictées, il faudra un modèle de données distinct : texte cible, enregistrement audio, segments éventuels, règles évaluées, variantes acceptées et critères de correction.
Règle d'architecture : le contenu ne doit jamais pouvoir exécuter du code arbitraire. Les données JSON sont validées au chargement et les types d'exercices autorisés sont définis dans le moteur.


9. Progression et personnalisation
Le jeu devra mémoriser séparément les résultats de chaque enfant. La progression pédagogique et la progression narrative seront liées, mais distinctes.
Indicateurs par compétence
- nombre de tentatives ;
- taux de réussite récent ;
- erreurs fréquentes ;
- niveau d'aide utilisé ;
- dernière date de pratique ;
- maîtrise estimée ;
- prochaine révision conseillée.
Une première version peut employer un système simple et transparent :
1. Découverte : présentation de la règle.
2. En cours d'acquisition : réussite avec des indices.
3. En consolidation : réussite répétée sans aide.
4. Acquise : réussite confirmée sur plusieurs séances et dans plusieurs formats.
5. À réviser : difficulté réapparue après un délai.
Ces états sont pédagogiques, pas des notes scolaires officielles.
Le système de révision devra faire revenir les notions fragiles après un délai adapté. Il ne doit pas se limiter à répéter immédiatement la même question : il faut varier les exemples et les contextes.
Profils familiaux
Chaque profil comprendra :
- un identifiant interne ;
- un pseudonyme et un avatar ;
- le niveau scolaire et les préférences ;
- la progression CE1/CE2 ;
- les résultats et révisions ;
- les récompenses ;
- les paramètres personnels utiles.
L'écran de sélection devra être simple et lisible. La suppression d'un profil nécessitera une confirmation explicite. Les données seront conservées localement, sans compte obligatoire ni collecte réseau.
Une zone réservée à l'adulte pourra présenter les progrès, les difficultés récurrentes et les notions à retravailler. Elle devra être accessible sans complexifier l'expérience de l'enfant.


10. Sauvegarde locale et fonctionnement hors ligne
Godot fournit user://, un emplacement adapté aux données persistantes de l'application. Les sauvegardes devront être séparées du dossier du projet et ne pas dépendre du répertoire de lancement.
Je recommande :
- un fichier de données par profil ;
- un format versionné, par exemple JSON dans la première version ;
- une sauvegarde après chaque mission ou changement important ;
- une écriture atomique ou un mécanisme de fichier temporaire et remplacement ;
- une sauvegarde de secours en cas de corruption ;
- une migration des données si le format change entre deux versions ;
- un bouton d'export et de restauration de sauvegarde, au minimum dans l'espace adulte.
Le chiffrement n'est pas indispensable pour des données pédagogiques ordinaires, mais les fichiers ne doivent pas être présentés comme inviolables. L'objectif est la robustesse et la confidentialité locale, pas la protection contre un attaquant disposant d'un accès complet à l'appareil.
Exemple de structure de sauvegarde

{
  "schema_version": 1,
  "profile_id": "profile_001",
  "display_name": "Explorateur",
  "school_level": "CE1",
  "unlocked_regions": [
    "village_des_phrases"
  ],
  "skills": {
    "accord_groupe_nominal": {
      "status": "consolidation",
      "attempts": 12,
      "recent_success_rate": 0.83,
      "last_practiced": "2026-10-11"
    }
  },
  "rewards": {
    "stars": 18,
    "items": []
  }
}

Les données de date et de progression ci-dessus sont des exemples de format, pas des résultats réels.


11. Interface utilisateur et accessibilité
L'interface doit être conçue pour des enfants qui maîtrisent encore progressivement la lecture et l'écriture.
Exigences visuelles
- Typographie très lisible, avec une police adaptée aux jeunes lecteurs.
- Contrastes suffisants et taille de texte réglable.
- Boutons larges, adaptés au tactile et à la souris.
- Consignes courtes, accompagnées si nécessaire d'une lecture audio.
- Animations fluides, sans surcharge visuelle.
- Indications de réussite ou d'erreur qui ne reposent pas uniquement sur la couleur.
- Interface adaptée au format portrait ou paysage selon la plateforme.
- Possibilité de désactiver les animations et de régler les volumes sonores.
Je choisirais une direction artistique cohérente, avec des illustrations originales et une palette de couleurs limitée par région. Le jeu doit être attrayant sans distraire l'enfant de la règle étudiée.
Résolutions et formats
L'interface sera conçue avec les conteneurs et ancres de Godot, plutôt qu'avec des positions fixes. Cela permettra de gérer les écrans d'ordinateurs, les tablettes et les smartphones.
Les interactions devront fonctionner au clavier, à la souris et au tactile. Pour les dictées, l'interface mobile devra gérer correctement l'ouverture du clavier virtuel, les accents et le retour au jeu.


12. Exigences de qualité et tests
Le projet sera considéré comme exploitable lorsque les critères suivants seront validés.
Domaine	Critère d'acceptation
Pédagogie	Chaque exercice possède une réponse attendue, une règle associée et une explication validée
Corrections	Les réponses justes et fausses sont correctement évaluées selon les règles définies
Progression	Les notions, niveaux et missions débloqués sont cohérents
Profils	Deux enfants peuvent jouer sans mélanger leurs résultats
Sauvegarde	Les progrès sont conservés après fermeture et redémarrage
Résilience	Une sauvegarde interrompue ne détruit pas automatiquement la dernière version valide
Hors ligne	Les parcours, exercices, dictées et sauvegardes fonctionnent sans Internet
Interface	Les menus et exercices restent utilisables sur petits et grands écrans
Performance	Les transitions et animations restent fluides sur les appareils cibles retenus
Export	Chaque plateforme possède une version installable et testée
Confidentialité	Aucune collecte ou transmission réseau n'est nécessaire au fonctionnement normal
Il faudra automatiser en priorité les tests des règles de correction, de la progression et des sauvegardes. Un corpus de tests linguistiques permettra de vérifier les pluriels, les accords, les homophones, les accents et les cas particuliers.

13. Export multiplateforme
Godot permet de préparer des exports pour les cinq plateformes visées, mais chaque cible demande une validation spécifique.
Plateforme	Points de vigilance
Linux	Tester sur les distributions cibles et leurs dépendances graphiques
Windows	Vérifier l'installation, les chemins de sauvegarde et les polices
macOS	Vérifier la signature, la distribution et les restrictions de sécurité
Android	Tester le tactile, les formats d'écran, l'audio et le clavier virtuel
iOS	Prévoir la chaîne d'export Apple, Xcode et un environnement macOS compatible
Les versions mobiles nécessitent des tests sur appareils réels. Pour iOS, un Mac et les outils Apple seront nécessaires à la préparation et à la signature de la version distribuable. L'export ne garantit pas, à lui seul, l'acceptation dans les boutiques d'applications.
Je recommande de commencer les validations techniques sur Linux et Windows, puis Android, tout en vérifiant assez tôt la faisabilité de la chaîne macOS/iOS pour éviter une mauvaise surprise en fin de projet.

14. Plan de réalisation

Phase 1 — Cadrage pédagogique et technique
Livrables : cahier des règles, schéma des données, architecture du projet, maquettes d'interface.
Définir les notions, les prérequis, les règles de correction et les premiers exercices validés.

Phase 2 — Prototype jouable
Livrable : une région, une mission complète et un profil.
Créer la carte, le personnage guide, le moteur d'exercices, la correction explicative et la sauvegarde.

Phase 3 — Contenu pédagogique
Livrable : premiers chapitres CE1 et CE2.
Ajouter les règles, exercices variés, dictées, tests de correction et mécanismes de révision.

Phase 4 — Profils et expérience familiale
Livrable : version familiale complète en local.
Finaliser les profils multiples, les sauvegardes, les réglages et le tableau de progression.

Phase 5 — Tests et distribution
Livrable : versions candidates pour les plateformes retenues.
Tester les appareils réels, la restauration des sauvegardes, l'accessibilité, les performances et les procédures d'installation.


15. Périmètre de la première version jouable
Pour maîtriser le risque et obtenir rapidement un résultat concret, je limiterais le premier prototype à :
- une carte avec trois lieux accessibles ;
- un personnage guide animé ;
- deux profils enfants ;
- un chapitre CE1 sur les accords dans le groupe nominal ;
- un chapitre CE2 sur les homophones grammaticaux ;
- trois types d'exercices : choix multiple, correction de phrase et dictée ;
- une correction explicative et un système d'indices ;
- une progression par compétence et des révisions ;
- une sauvegarde locale ;
- un premier export Linux et Windows.
Ce périmètre suffit à valider l'architecture sans devoir produire immédiatement toutes les régions, animations et centaines d'exercices.

16. Décisions à prendre avant de commencer le code

Trois décisions auront une influence importante sur la conception :

1. Direction graphique
Dessin animé 2D, personnages et décors illustrés


2. Voix des dictées et consignes
Voix préenregistrées, naturelles et constantes


3. Gestion du contenu pédagogique
Fichiers JSON édités hors de Godot

4. Référence au BLED
S'inspirer des règles et rédiger des exercices originaux
