class_name RewardRules
extends RefCounted
## Regles de deblocage des objets de la collection, a partir du catalogue
## valide de data/rewards/. Code pur : renvoie ce qui vient d'etre debloque,
## ProgressManager se charge de l'enregistrer.


## catalog : liste d'objets conformes a reward_item.schema.json.
## best_stars_by_mission : mission_id -> {"best_stars": int, ...}.
## owned : item_id deja possedes (jamais redebloques).
static func newly_unlocked(
    catalog: Array[Dictionary], total_stars: int, best_stars_by_mission: Dictionary, owned: Array
) -> Array[String]:
    var unlocked: Array[String] = []
    for item in catalog:
        var item_id: String = item["item_id"]
        if owned.has(item_id) or unlocked.has(item_id):
            continue
        if _is_unlocked(item["unlock"], total_stars, best_stars_by_mission):
            unlocked.append(item_id)
    return unlocked


static func _is_unlocked(
    unlock: Dictionary, total_stars: int, best_stars_by_mission: Dictionary
) -> bool:
    var count: int = int(unlock["count"])
    match unlock["type"]:
        "total_stars":
            return total_stars >= count
        "mission_stars":
            var result: Dictionary = best_stars_by_mission.get(unlock.get("mission_id", ""), {})
            return int(result.get("best_stars", 0)) >= count
    return false
