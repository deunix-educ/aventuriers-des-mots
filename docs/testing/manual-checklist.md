# Checklist de vérification manuelle

Tout ce qui suit ne peut pas être vérifié sans écran (rendu, mise en page, animations, audio, tactile, clavier) et n'a donc pas été vérifié par les tests automatisés. À faire à la main avant de considérer l'étape « Scènes » terminée.

## Parcours complet

1. `make run`.
2. Écran de sélection de profil vide → bouton « Nouveau profil » visible et cliquable.
3. Création de profil : le bouton de validation refuse un prénom vide avec un message visible (pas seulement une absence de réaction) ; CE1 est sélectionné par défaut ; le bouton CE2 bascule correctement l'état visuel des deux boutons (ils doivent se comporter comme des boutons radio, un seul actif à la fois).
4. Après création, arrivée sur la carte (« La forêt des accords ») avec trois lieux visibles et positionnés à des endroits différents, pas superposés.
5. Chaque lieu affiche un intitulé et un état (« À découvrir », etc.) lisible.
6. Clic sur un lieu → introduction de la mission : le texte narratif s'affiche en entier (pas tronqué), Plume (le hibou) affiche la même phrase dans sa bulle.
7. « Commencer la mission » → panneau de règle : énoncé et exemple lisibles, bouton « C'est parti ! » visible.
8. Mission « Le pré des petits mots » (choix multiple) : les réponses sont cliquables, une réponse juste affiche « Bravo ! », une réponse fausse affiche « Pas tout à fait » avec un indice.
9. Refaire une erreur sur le même exercice : after la 2e erreur, l'explication remplace l'indice ; après la 3e, la bonne réponse est montrée et l'exercice passe au suivant sans blocage.
10. Mission « Le pont des phrases » (correction de phrase) : toucher un mot le fait apparaître comme sélectionné (état visuel distinct, pas seulement une couleur) ; un champ de saisie apparaît sous le mot sélectionné ; toucher à nouveau le mot fait disparaître le champ.
11. Mission « La clairière de l'écho » (dictée) : à l'arrivée sur l'exercice, la voix de synthèse doit se faire entendre automatiquement ; le bouton « Réécouter » la rejoue sans planter ; le badge « Voix provisoire » est visible ; la zone de saisie accepte le texte et les accents. Taper le texte sans point final (rien dans l'audio ne l'indique) doit être accepté comme correct (point 21 de `decisions.md`).
12. Après 3 exercices, écran de récompense avec le nombre d'étoiles, puis retour à la carte.
13. Quitter le jeu puis relancer `make run` : le profil et sa progression doivent être conservés (sélectionner le même profil, vérifier que l'état affiché sur la carte a changé par rapport à l'état initial).
14. Depuis la sélection de profil, supprimer un profil : une confirmation explicite doit apparaître avant la suppression effective ; annuler doit ne rien supprimer.

## Accessibilité et interface

- Réussite et erreur ne doivent jamais se distinguer **uniquement** par la couleur (vérifier que le texte du titre du panneau de retour diffère bien : « Bravo ! » vs « Pas tout à fait »).
- Taille et contraste du texte à vérifier sur un petit écran et un grand écran (redimensionner la fenêtre pendant que le jeu tourne, vérifier que les boutons restent utilisables et ne se chevauchent pas — conteneurs et ancres, pas de position fixe).
- Boutons testés à la souris et au clavier (tabulation / entrée). Le tactile n'a pas pu être testé (pas d'export mobile à ce stade).
- Vérifier qu'aucun texte destiné à l'enfant n'apparaît tronqué ou coupé sur les écrans où l'`autowrap` est activé.

## Audio

- `ce1_accord_adjectif_dictee_01` a un fichier audio provisoire généré par `make generate-dictation-audio` (voix neuronale Piper, voir `assets/CREDITS.md`). Testé manuellement : voix claire et bien comprise.
- Toute dictée ajoutée sans régénérer son audio se dégrade silencieusement (avertissement en console, pas de plantage) : vérifier qu'aucune dictée manquante ne passe inaperçue avant diffusion (`make generate-dictation-audio` ne régénère pas l'existant, `--force` pour forcer).

## Exports

- `make export-linux` produit `build/linux/aventuriers_des_mots.x86_64` : lancé et vérifié en headless dans cet environnement, mais **jamais vu à l'écran** ni testé sur une autre distribution (cahier des charges §13 demande un test sur les distributions cibles).
- `make export-windows` produit `build/windows/aventuriers_des_mots.exe` : seul le format du binaire (PE32+) a pu être vérifié ici. **Jamais exécuté** (pas de machine Windows ni de Wine disponibles) : à tester sur une vraie machine Windows avant toute diffusion.
- Vérifier manuellement que le jeu se comporte correctement en plein écran et en fenêtré sur les deux plateformes.

## Non vérifié par choix

- Export macOS, Android, iOS : hors périmètre de cette version (voir prompt de lancement, Objectif).
- Clavier virtuel tactile, formats d'écran mobile : hors périmètre de cette version.
- Animations : aucune n'existe encore (interface statique assumée pour ce prototype).
