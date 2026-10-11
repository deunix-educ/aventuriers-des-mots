extends Node
## Competences, missions debloquees et planification des revisions du profil
## selectionne. Delegue les calculs a ProgressUpdates (scripts/profiles/), qui
## s'appuie sur ReviewScheduler et DifficultyManager (scripts/pedagogy/).
## L'ecriture sur disque reste groupee : save_now() est appele en fin de
## mission, pas a chaque tentative (docs/specs/decisions.md, point 7).

var _current_save: Dictionary = {}
var _current_profile_id: String = ""


## Charge la sauvegarde existante d'un profil et demarre une nouvelle seance
## (voir ProgressUpdates.start_session). Faux si le profil n'a pas de
## sauvegarde lisible.
func load_profile(profile_id: String) -> bool:
    var data: Variant = SaveManager.load(profile_id)
    if data == null:
        return false
    _current_profile_id = profile_id
    _current_save = ProgressUpdates.start_session(data)
    return true


func record_attempt(
    skill_id: String, success: bool, hint_used: bool, exercise_type: String
) -> void:
    var attempt := {
        "skill": skill_id,
        "success": success,
        "hint_used": hint_used,
        "exercise_type": exercise_type,
    }
    _current_save = ProgressUpdates.record_attempt(_current_save, attempt)


func unlock_region(region_id: String) -> void:
    _current_save = ProgressUpdates.unlock_region(_current_save, region_id)


func add_stars(amount: int) -> void:
    _current_save = ProgressUpdates.add_stars(_current_save, amount)


func stars() -> int:
    return _current_save.get("rewards", {}).get("stars", 0)


func next_difficulty_for_skill(skill_id: String, current_difficulty: int) -> int:
    return ProgressUpdates.next_difficulty_for_skill(_current_save, skill_id, current_difficulty)


func get_skill_state(skill_id: String) -> Dictionary:
    var skills: Dictionary = _current_save.get("skills", {})
    return skills.get(skill_id, ReviewScheduler.initial_state())


func current_save() -> Dictionary:
    return _current_save


## A appeler en fin de mission (pas apres chaque tentative) pour persister la
## progression du profil courant.
func save_now() -> bool:
    if _current_profile_id.is_empty():
        return false
    return SaveManager.save(_current_profile_id, _current_save)
