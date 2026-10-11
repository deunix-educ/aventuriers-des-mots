class_name AttemptFlow
extends RefCounted
## Aide graduee sur les tentatives successives d'un meme exercice, tant que la
## reponse est fausse (docs/specs/decisions.md point 7 ; exercise-lifecycle.md,
## ecart 2). Code pur.

enum SupportLevel { HINT, EXPLANATION, REVEAL }

const MAX_ATTEMPTS := 3


## attempt_number : numero de la tentative fautive en cours (1 pour la
## premiere erreur sur cet exercice, 2 pour la deuxieme, etc.).
static func support_level_for_attempt(attempt_number: int) -> SupportLevel:
    if attempt_number <= 1:
        return SupportLevel.HINT
    if attempt_number < MAX_ATTEMPTS:
        return SupportLevel.EXPLANATION
    return SupportLevel.REVEAL


## Vrai quand la tentative fautive courante doit mettre fin a l'exercice (la
## reponse corrigee est alors montree, sans sanction, et la competence est
## marquee pour une revision avec d'autres exemples).
static func should_end_exercise(attempt_number: int) -> bool:
    return attempt_number >= MAX_ATTEMPTS
