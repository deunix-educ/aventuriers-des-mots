class_name DifficultyManager
extends RefCounted
## Suggere le niveau de difficulte (1 a 3) du prochain exercice pour une
## competence, a partir de l'historique recent de reussites. Code pur : ne lit
## ni horloge ni hasard, ne modifie aucun etat (ProgressManager est responsable
## du stockage).

const MIN_DIFFICULTY := 1
const MAX_DIFFICULTY := 3
const WINDOW := 3


## recent_results : resultats des tentatives les plus recentes, la derniere en
## dernier. Monte d'un niveau apres WINDOW reussites consecutives ; descend
## d'un niveau apres WINDOW echecs consecutifs ; ne bouge pas sinon. Jamais en
## dehors de [MIN_DIFFICULTY, MAX_DIFFICULTY] : la difficulte evolue sans
## jamais bloquer durablement l'enfant (cahier des charges §2).
static func next_difficulty(current_difficulty: int, recent_results: Array[bool]) -> int:
    if recent_results.size() < WINDOW:
        return clampi(current_difficulty, MIN_DIFFICULTY, MAX_DIFFICULTY)

    var last_window: Array[bool] = recent_results.slice(recent_results.size() - WINDOW)
    var all_success := true
    var all_failure := true
    for result in last_window:
        if result:
            all_failure = false
        else:
            all_success = false

    if all_success:
        return clampi(current_difficulty + 1, MIN_DIFFICULTY, MAX_DIFFICULTY)
    if all_failure:
        return clampi(current_difficulty - 1, MIN_DIFFICULTY, MAX_DIFFICULTY)
    return clampi(current_difficulty, MIN_DIFFICULTY, MAX_DIFFICULTY)
