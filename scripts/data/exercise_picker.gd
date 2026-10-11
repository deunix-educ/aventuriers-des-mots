class_name ExercisePicker
extends RefCounted
## Choisit un exercice parmi une liste de candidats, sans jamais redonner celui
## qui vient d'etre traite ("Points durs" du prompt de lancement : une revision
## tire un autre exercice de la meme regle, jamais celui qui vient d'etre
## rate). Code pur : le generateur aleatoire est injecte, jamais lu
## directement.


## Retourne null si `candidates` est vide. Si tous les candidats sont exclus
## (un seul exercice disponible), le redonne : pas d'autre choix possible.
static func pick(
    candidates: Array[Dictionary], exclude_id: String, rng: RandomNumberGenerator
) -> Variant:
    if candidates.is_empty():
        return null

    var pool: Array[Dictionary] = []
    for candidate in candidates:
        if candidate["id"] != exclude_id:
            pool.append(candidate)
    if pool.is_empty():
        pool = candidates

    return pool[rng.randi_range(0, pool.size() - 1)]
