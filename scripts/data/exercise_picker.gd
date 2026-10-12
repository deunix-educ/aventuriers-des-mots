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


## Tire un exercice qui n'a pas encore ete vu pendant la mission : d'abord
## parmi `preferred` (la difficulte visee), puis parmi `all` si tous les
## preferes ont ete vus. Quand tout a ete vu (mission plus longue que le
## contenu disponible), retombe sur `pick` en evitant au moins le dernier vu.
static func pick_unseen(
    preferred: Array[Dictionary],
    all: Array[Dictionary],
    seen_ids: Array[String],
    rng: RandomNumberGenerator
) -> Variant:
    for source in [preferred, all]:
        var pool: Array[Dictionary] = []
        for candidate: Dictionary in source:
            if not seen_ids.has(candidate["id"]):
                pool.append(candidate)
        if not pool.is_empty():
            return pool[rng.randi_range(0, pool.size() - 1)]
    var last := "" if seen_ids.is_empty() else seen_ids[seen_ids.size() - 1]
    return pick(preferred, last, rng)
