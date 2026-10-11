extends Node
## Creation, selection et suppression des profils enfants. Chaque profil a un
## profile_id distinct ; SaveManager garantit qu'un profil ne lit ni n'ecrit
## jamais le fichier d'un autre (voir "Points durs" du prompt de lancement).

var current_profile_id: String = ""


func create_profile(display_name: String, school_level: String) -> String:
    var profile_id := _generate_profile_id()
    SaveManager.load_or_create(profile_id, display_name, school_level)
    return profile_id


## Charge le profil dans ProgressManager et le marque comme profil courant.
## Ne fait rien si le profil n'existe pas.
func select_profile(profile_id: String) -> bool:
    if not ProgressManager.load_profile(profile_id):
        return false
    current_profile_id = profile_id
    return true


func delete_profile(profile_id: String) -> void:
    SaveManager.delete(profile_id)
    if current_profile_id == profile_id:
        current_profile_id = ""


func list_profiles() -> Array[String]:
    return SaveManager.list_profile_ids()


## Resume de chaque profil pour l'ecran de selection : profile_id, display_name
## et school_level, sans charger toute la progression.
func list_profile_summaries() -> Array[Dictionary]:
    var summaries: Array[Dictionary] = []
    for profile_id in list_profiles():
        var data: Variant = SaveManager.load(profile_id)
        if data == null:
            continue
        var summary := {
            "profile_id": profile_id,
            "display_name": data["display_name"],
            "school_level": data["school_level"],
        }
        summaries.append(summary)
    return summaries


func _generate_profile_id() -> String:
    return "profile_%d_%d" % [Time.get_unix_time_from_system(), randi() % 10000]
