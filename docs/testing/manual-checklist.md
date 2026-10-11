# Checklist de vérification manuelle

Tout ce qui suit ne peut pas être vérifié sans écran (rendu, mise en page, animations, audio, tactile, clavier) et n'a donc pas été vérifié par les tests automatisés. À faire à la main avant de considérer l'étape « Scènes » terminée.

## Parcours complet

1. `make run`.
2. Écran de sélection de profil vide → bouton « Nouveau profil » visible et cliquable.
3. Création de profil : le bouton de validation refuse un prénom vide avec un message visible (pas seulement une absence de réaction) ; CE1 est sélectionné par défaut ; le bouton CE2 bascule correctement l'état visuel des deux boutons (ils doivent se comporter comme des boutons radio, un seul actif à la fois).
4. Après création, arrivée sur la carte (« La forêt des accords ») avec **neuf** lieux visibles (point 25 de `decisions.md` : extension au-delà du prototype §15), disposés sur une grille 3x3 (point 26 : deux missions se chevauchaient avant ce repositionnement) — vérifier qu'aucun marqueur ne se superpose à un autre, y compris en redimensionnant la fenêtre vers une taille réduite.
5. Chaque lieu affiche un intitulé et un état (« À découvrir », etc.) lisible.
6. Clic sur un lieu → introduction de la mission : le texte narratif s'affiche en entier (pas tronqué), Plume (le hibou) affiche la même phrase dans sa bulle.
7. « Commencer la mission » → panneau de règle : énoncé et exemple lisibles, bouton « C'est parti ! » visible.
8. Mission « Le pré des petits mots » (choix multiple) : les réponses sont cliquables, une réponse juste affiche « Bravo ! », une réponse fausse affiche « Pas tout à fait » avec un indice.
9. Refaire une erreur sur le même exercice : after la 2e erreur, l'explication remplace l'indice ; après la 3e, la bonne réponse est montrée et l'exercice passe au suivant sans blocage.
10. Mission « Le pont des phrases » (correction de phrase) : toucher un mot le fait apparaître comme sélectionné (état visuel distinct, pas seulement une couleur) ; un champ de saisie apparaît sous le mot sélectionné ; toucher à nouveau le mot fait disparaître le champ.
11. Mission « La clairière de l'écho » (dictée) : à l'arrivée sur l'exercice, la voix de synthèse doit se faire entendre automatiquement ; le bouton « Réécouter » la rejoue sans planter ; le badge « Voix provisoire » est visible ; la zone de saisie accepte le texte et les accents. Le rappel « N'oublie pas : une majuscule au début de la phrase et un point à la fin ! » doit être visible (point 22 de `decisions.md`) ; taper le texte sans majuscule ou sans point final doit être refusé, avec l'erreur correspondante.
12. Après 3 exercices, écran de récompense avec le nombre d'étoiles, puis retour à la carte.
12ter. Profil **CE2** : la carte affiche « Le marais des homophones » avec 12 lieux (4 colonnes × 3 lignes, sans chevauchement) et un bouton « Revoir le CE1 » qui bascule sur les 9 lieux CE1 (et « Retour au CE2 » revient) ; un profil CE1 n'a pas ce bouton (point 27 de `decisions.md`). Jamais vu à l'écran. Jouer une mission de chaque règle CE2 (a/à, et/est, son/sont, on/ont), dont une dictée : voix claire, rappel majuscule/point visible.
12quater. Score et récompenses (point 30 de `decisions.md`) : terminer une mission sans aucune erreur donne 3 étoiles, avec un indice 2, avec une réponse montrée 1 (message encourageant, jamais de blâme) ; la carte affiche « Total d'étoiles » et « Étoiles : n/3 » sur chaque lieu sans texte coupé ; rejouer avec un meilleur score affiche « Nouveau record » et n'ajoute que la différence ; « Ma collection » montre les objets trouvés et les objets mystère avec la façon de les obtenir (liste défilante). Quitter puis relancer : étoiles et objets conservés.
12bis. Répéter rapidement les points 8-12 sur une mission de chacune des deux nouvelles règles (« La ruche qui se multiplie » pour le pluriel du nom, « Le sentier des bons compagnons » pour l'accord du déterminant) : jamais vu à l'écran, seulement validé en headless (point 25 de `decisions.md`).
13. Quitter le jeu puis relancer `make run` : le profil et sa progression doivent être conservés (sélectionner le même profil, vérifier que l'état affiché sur la carte a changé par rapport à l'état initial).
14. Depuis la sélection de profil, supprimer un profil : une confirmation explicite doit apparaître avant la suppression effective ; annuler doit ne rien supprimer.

## Accessibilité et interface

- Habillage (point 31 de `decisions.md`) : relire chaque écran (profils, carte CE1 et CE2, introduction, règle, les trois types d'exercice, retour juste/faux, récompense, collection) ; le rendu à 1152x648 a été relu sur captures, pas les autres tailles ni le tactile. Redimensionner la fenêtre : les lieux de la carte restent entiers et ne se chevauchent pas.
- Navigation : « Changer de profil » sur la carte ramène au choix du profil sans perte ; « Quitter la mission » demande confirmation, ne donne aucune étoile et ramène à la carte.

- Réussite et erreur ne doivent jamais se distinguer **uniquement** par la couleur (vérifier que le texte du titre du panneau de retour diffère bien : « Bravo ! » vs « Pas tout à fait »).
- Taille et contraste du texte à vérifier sur un petit écran et un grand écran (redimensionner la fenêtre pendant que le jeu tourne, vérifier que les boutons restent utilisables et ne se chevauchent pas — conteneurs et ancres, pas de position fixe).
- Boutons testés à la souris et au clavier (tabulation / entrée). Le tactile n'a pas pu être testé (pas d'export mobile à ce stade).
- Vérifier qu'aucun texte destiné à l'enfant n'apparaît tronqué ou coupé sur les écrans où l'`autowrap` est activé.

## Réglages et espace adulte (point 32 de `decisions.md`)

- « Réglages » depuis la carte et depuis le choix du profil ; « Retour » revient à l'écran d'où l'on vient.
- Taille du texte : Normal / Grand / Très grand s'applique immédiatement, à tous les écrans, et est conservée après redémarrage. Au plus grand réglage, aucun bouton ne sort de la fenêtre.
- Animations : « Sans animations » supprime les rebonds et fondus (carte, récompense) ; le réglage est conservé après redémarrage.
- Volume : écouter une dictée en déplaçant le curseur (le son baisse, le silence est complet à 0). Aucun son d'interface n'existe encore.
- Espace adulte : une mauvaise réponse à la barrière n'ouvre rien ; la bonne ouvre le tableau de progrès. Après quelques missions, les notions et leurs réussites correspondent à ce qui a été joué.
- Export : « Exporter ce profil » crée un fichier dans `Documents/AventuriersDesMots/` (vérifier le chemin affiché). Restaurer ce fichier crée un nouveau profil identique ; le profil d'origine est intact. Un fichier quelconque déposé dans le dossier est signalé « illisible » et ne peut pas être restauré.

## Audio

- Son et musique (point 33 de `decisions.md`) : clic sur les boutons, « Bravo » (accord montant) et « Pas tout à fait » (deux notes douces, jamais agressives), étoiles une à une puis fanfare à 3 étoiles ou objet gagné ; musique de forêt (CE1) et de marais (CE2), en boucle sans coupure audible, qui baisse pendant une dictée ; cinq morceaux au choix dans « Musique de fond » (le choix s'entend aussitôt et est conservé après redémarrage) ; trois curseurs de réglages qui agissent bien chacun sur leur bus ; tout reste agréable à volume moyen et il n'y a jamais d'écrasement de la voix.

- `ce1_accord_adjectif_dictee_01` a un fichier audio provisoire généré par `make generate-dictation-audio` (voix neuronale Piper, voir `assets/CREDITS.md`). Testé manuellement : voix claire et bien comprise.
- Toute dictée ajoutée sans régénérer son audio se dégrade silencieusement (avertissement en console, pas de plantage) : vérifier qu'aucune dictée manquante ne passe inaperçue avant diffusion (`make generate-dictation-audio` ne régénère pas l'existant, `--force` pour forcer).

## Exports

- `make package` produit `dist/aventuriers-des-mots-0.1.0-{linux,windows}-x86_64.*` (exécutable unique, PCK embarqué) : sommes de contrôle et lancement headless de l'archive Linux vérifiés ici ; le binaire Windows n'a été vérifié que par son format (PE32+).

- `make export-linux` produit `build/linux/aventuriers_des_mots.x86_64` : lancé et vérifié en headless dans cet environnement, mais **jamais vu à l'écran** ni testé sur une autre distribution (cahier des charges §13 demande un test sur les distributions cibles).
- `make export-windows` produit `build/windows/aventuriers_des_mots.exe` : seul le format du binaire (PE32+) a pu être vérifié ici. **Jamais exécuté** (pas de machine Windows ni de Wine disponibles) : à tester sur une vraie machine Windows avant toute diffusion.
- Vérifier manuellement que le jeu se comporte correctement en plein écran et en fenêtré sur les deux plateformes.

## Non vérifié par choix

- Export macOS, Android, iOS : hors périmètre de cette version (voir prompt de lancement, Objectif).
- Clavier virtuel tactile, formats d'écran mobile : hors périmètre de cette version.
- Animations : aucune n'existe encore (interface statique assumée pour ce prototype).
