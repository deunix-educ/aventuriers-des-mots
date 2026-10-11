Tu démarres le développement des « Aventuriers des mots », un jeu éducatif de français pour des enfants de CE1 et CE2 (7–9 ans), en Godot 4 et GDScript typé. Le dépôt ne contient pour l'instant que `CLAUDE.md` et `docs/specs/`.

Lis d'abord en entier, dans cet ordre :

1. `CLAUDE.md` : conventions et invariants du projet.
2. `docs/specs/cahier-des-charges.md` : la spécification. Elle fait foi.
3. `docs/specs/exercise-lifecycle.md` : le cycle de vie d'un exercice et deux écarts à trancher.

## Objectif

Livrer la première version jouable décrite au §15 du cahier des charges. Elle existe pour valider l'architecture avant de produire le reste du contenu : un moteur d'exercices piloté par des données JSON, une correction explicative, une progression par compétence avec révisions, et des sauvegardes par profil.

Tout ce qui sort du §15 est hors périmètre : autres régions, autres types d'exercices, macOS, Android, iOS, espace adulte, éléments cosmétiques. Ne l'implémente pas, mais ne ferme aucune porte : une nouvelle région ne doit demander que des données, un nouveau type d'exercice qu'une scène et un validateur de plus.

## Étape 0 : plan, puis arrêt

N'écris aucun code avant que j'aie validé le plan. Inspecte l'environnement (`godot --version`, outils présents), puis propose-moi dans un message court :

1. La version stable de Godot 4 retenue et la façon de la figer. Si Godot n'est pas installé, dis-le avant d'installer quoi que ce soit.
2. L'outillage : cadre de tests headless, lint et formatage GDScript compatibles avec l'indentation à 4 espaces.
3. Les schémas JSON : règle, exercice (un format de réponse par type), dictée (modèle distinct, §8), curriculum, sauvegarde. Précise l'interaction retenue pour la correction de phrase : retaper la phrase, ou toucher le mot fautif puis le corriger.
4. La structure renvoyée par le moteur de correction (§6).
5. Les règles de passage entre les cinq états de maîtrise (§9) et les délais de révision, avec des seuils chiffrés.
6. Les règles de tolérance des dictées (§5) : accents, apostrophes, majuscules, ponctuation, espaces, variantes admises.
7. Ta position sur les deux écarts signalés dans `exercise-lifecycle.md`.
8. La solution pour l'audio provisoire des dictées.
9. Les écarts que tu proposes par rapport à l'arborescence du §7.
10. Les questions restées ouvertes, dont la licence du projet.

Une fois le plan validé, consigne les décisions dans `docs/specs/decisions.md`.

## Ordre de construction

La logique passe avant l'interface : une correction fausse ou une progression incohérente ne se voit pas à l'écran, alors qu'un test la détecte. Chaque étape se termine par `make check` au vert et un commit.

1. Squelette : projet Godot, `Makefile`, lint, tests, `.editorconfig`, `.gitignore`, `.gitattributes`, `README.md` et `README-EN.md`.
2. Données : schémas, validateur, `make validate-data`, premier contenu.
3. Logique pure, avec ses tests : validation des réponses, analyse des dictées, difficulté, planification des révisions.
4. Profils et sauvegardes.
5. Scènes : démarrage, sélection et création de profil, carte à trois lieux, introduction de mission, panneau de règle, hôte d'exercice et les trois types (choix multiple, correction de phrase, dictée), panneau de retour, écran de récompense, personnage guide.
6. Exports Linux et Windows.

Après l'étape 0, avance sans attendre mon accord entre les étapes. Arrête-toi seulement si la spécification se contredit ou si une décision engage le format des données ou des sauvegardes.

## Points durs

**Analyse des dictées.** C'est le composant le plus risqué. Aligne la production de l'enfant sur le texte cible mot par mot avant de comparer les caractères, sinon un mot oublié décale tout et chaque mot suivant devient une erreur. Normalise avant de comparer (formes Unicode composées et décomposées, apostrophe droite et typographique, espaces insécables, œ) : vérifie ce que GDScript offre réellement pour cela et, à défaut, utilise une table explicite pour les caractères français. La distinction entre erreur lexicale et erreur grammaticale vient des annotations du texte cible dans les données (quel mot évalue quelle règle), pas d'une analyse linguistique devinée à l'exécution. Sans annotation, l'erreur reste non classée.

**Maîtrise.** Une compétence ne devient « acquise » qu'après des réussites sur plusieurs séances et dans plusieurs formats d'exercice (§9). Une révision tire un autre exercice de la même règle, jamais celui qui vient d'être raté. L'horloge d'un appareil familial n'est pas fiable : ne fais pas reposer la progression sur elle seule, et compte aussi les séances.

**Sauvegardes.** Teste les cas de panne, pas seulement le cas nominal : fichier temporaire tronqué, fichier principal corrompu avec retour à la copie de secours, version de schéma plus ancienne à migrer, deux profils qui ne se mélangent pas.

**Sens de l'aventure.** Le jeu ne doit pas être un questionnaire habillé d'un décor. Chaque lieu de la carte porte une mission avec un court contexte narratif, issu des données, qui justifie les exercices.

## Contenu pédagogique

Tu rédiges le contenu, je le valide. Il est entièrement original et porte `"review_status": "draft"`.

- CE1, accords dans le groupe nominal : trois règles (pluriel du nom, accord du déterminant, accord de l'adjectif).
- CE2, homophones grammaticaux : a/à, et/est, son/sont, on/ont, chacun avec son test de substitution.
- Par règle, au moins 8 choix multiples et 4 corrections de phrase, répartis sur les niveaux de difficulté. Par chapitre, 3 dictées courtes. Ce volume est le minimum pour que les révisions puissent varier les exemples.

Écris pour un enfant de 7 à 9 ans : phrases courtes, vocabulaire courant, une seule réponse juste possible. Relis chaque exercice en te demandant si une autre réponse serait défendable. Si oui, reformule la phrase ou déclare la variante dans les données.

Comme du JSON se relit mal, génère `docs/review/content-review.md` à partir des données : pour chaque règle, son énoncé, puis chaque exercice avec sa réponse attendue, son indice et son explication. C'est ce document que je validerai.

## Graphismes et audio provisoires

Tout est provisoire et créé par toi : formes simples, pas d'asset tiers sans licence libre compatible, chaque source notée dans `assets/CREDITS.md`. La cible reste des voix préenregistrées (§16) : l'audio provisoire doit fonctionner hors ligne à l'exécution, être identifiable comme provisoire et se remplacer fichier par fichier sans toucher au code.

## Vérification et compte rendu

Les tests headless couvrent la correction, la progression et les sauvegardes, avec un corpus linguistique pour les pluriels, les accords, les homophones et les accents (§12). Pour ce que tu ne peux pas observer (rendu, animations, audio, tactile), écris `docs/testing/manual-checklist.md` avec les manipulations à faire.

À la fin de chaque étape, indique en quelques lignes ce qui est fait, ce que les tests couvrent, ce qui n'a pas été vérifié et pourquoi, et les décisions prises sans moi. Si un export ne peut pas être produit ou lancé dans ton environnement, dis-le tel quel.
