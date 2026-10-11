class_name ProgressReport
extends RefCounted
## Synthese de progression destinee a l'adulte, calculee a partir d'une
## sauvegarde. Code pur : aucun acces a l'arbre de scenes ni au disque. Les
## intitules viennent de l'appelant (UIText) : ici seulement des identifiants
## et des nombres. Une notion « a retravailler » n'est jamais un jugement sur
## l'enfant : c'est un signal pour l'adulte (cahier des charges §9).

## Nombre minimal de tentatives recentes avant de parler de difficulte.
const MIN_ATTEMPTS_FOR_DIFFICULTY := 3
## Taux de reussite recent en dessous duquel la notion est signalee.
const STRUGGLE_RATE := 0.6


## `missions_total` : nombre de missions du niveau de l'enfant ;
## `items_total` : taille du catalogue d'objets.
static func build(save: Dictionary, missions_total: int, items_total: int) -> Dictionary:
    var results: Dictionary = save.get("mission_results", {})
    var rewards: Dictionary = save.get("rewards", {"stars": 0, "items": []})
    var skills: Array[Dictionary] = []
    var skill_states: Dictionary = save.get("skills", {})
    var skill_ids: Array = skill_states.keys()
    skill_ids.sort()
    for skill_id: String in skill_ids:
        skills.append(_skill_row(skill_id, skill_states[skill_id]))
    return {
        "display_name": save.get("display_name", ""),
        "school_level": save.get("school_level", ""),
        "session_count": int(save.get("session_count", 0)),
        "stars": int(rewards.get("stars", 0)),
        "missions_done": results.size(),
        "missions_total": missions_total,
        "items_owned": rewards.get("items", []).size(),
        "items_total": items_total,
        "skills": skills,
    }


static func _skill_row(skill_id: String, state: Dictionary) -> Dictionary:
    var recent: Array = state.get("recent_results", [])
    var hints: Array = state.get("recent_hint_used", [])
    var successes := 0
    for result: bool in recent:
        if result:
            successes += 1
    var hint_count := 0
    for used: bool in hints:
        if used:
            hint_count += 1
    var attempts := recent.size()
    var status: String = state.get("status", "decouverte")
    var struggling := (
        attempts >= MIN_ATTEMPTS_FOR_DIFFICULTY
        and float(successes) / float(attempts) < STRUGGLE_RATE
    )
    return {
        "skill_id": skill_id,
        "status": status,
        "attempts": attempts,
        "successes": successes,
        "hints_used": hint_count,
        "needs_work": status == "a_reviser" or struggling,
    }
