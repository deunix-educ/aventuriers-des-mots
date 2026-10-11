class_name ProgressUpdates
extends RefCounted
## Fonctions pures qui appliquent une tentative d'exercice ou un debut de
## seance a une sauvegarde (dictionnaire conforme a save.schema.json), en
## s'appuyant sur ReviewScheduler et DifficultyManager (scripts/pedagogy/).
## ProgressManager (autoload) est seul responsable d'appeler ces fonctions et
## de persister le resultat via SaveManager ; l'ecriture sur disque reste
## groupee en fin de mission (docs/specs/decisions.md, point 7).


## attempt : {"skill": String, "success": bool, "hint_used": bool,
## "exercise_type": String}.
static func record_attempt(save_data: Dictionary, attempt: Dictionary) -> Dictionary:
    var updated: Dictionary = save_data.duplicate(true)
    var skills: Dictionary = updated["skills"]
    var skill_id: String = attempt["skill"]
    var skill_state: Dictionary = (
        skills[skill_id] if skills.has(skill_id) else ReviewScheduler.initial_state()
    )
    var current_session: int = updated["session_count"]
    skills[skill_id] = ReviewScheduler.record_attempt(skill_state, attempt, current_session)
    updated["skills"] = skills
    return updated


## A appeler une fois en debut de seance, avant toute tentative : incremente
## session_count et bascule en "a_reviser" les competences "acquise" dont le
## delai de revision est depasse sans nouvelle pratique.
static func start_session(save_data: Dictionary) -> Dictionary:
    var updated: Dictionary = save_data.duplicate(true)
    updated["session_count"] = int(updated["session_count"]) + 1
    var current_session: int = updated["session_count"]

    var skills: Dictionary = updated["skills"]
    var updated_skills: Dictionary = {}
    for skill_id: String in skills:
        updated_skills[skill_id] = ReviewScheduler.mark_overdue_as_review(
            skills[skill_id], current_session
        )
    updated["skills"] = updated_skills
    return updated


static func next_difficulty_for_skill(
    save_data: Dictionary, skill_id: String, current_difficulty: int
) -> int:
    var skills: Dictionary = save_data["skills"]
    if not skills.has(skill_id):
        return current_difficulty
    var recent: Array[bool] = skills[skill_id]["recent_results"]
    return DifficultyManager.next_difficulty(current_difficulty, recent)


static func unlock_region(save_data: Dictionary, region_id: String) -> Dictionary:
    var updated: Dictionary = save_data.duplicate(true)
    var regions: Array = updated["unlocked_regions"]
    if not regions.has(region_id):
        regions.append(region_id)
    updated["unlocked_regions"] = regions
    return updated


## Les recompenses valorisent l'effort et la progression, jamais la vitesse
## (cahier des charges §2, principe 6) : un nombre fixe d'etoiles par mission
## terminee, quel que soit le temps pris ou le nombre d'aides utilisees.
static func add_stars(save_data: Dictionary, amount: int) -> Dictionary:
    var updated: Dictionary = save_data.duplicate(true)
    var rewards: Dictionary = updated["rewards"].duplicate(true)
    rewards["stars"] = int(rewards["stars"]) + amount
    updated["rewards"] = rewards
    return updated
