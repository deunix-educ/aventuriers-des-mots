extends Node
## Serialisation des sauvegardes par profil dans user:// (ecriture atomique,
## copie de secours, migration). Delegue le travail reel a SaveIO,
## SaveFactory et SaveMigration (scripts/profiles/), qui restent testables
## sans arbre de scenes.

var _save_schema: Dictionary = {}


func _ready() -> void:
    _save_schema = DataLoader.load_schema("save")


## Cree une nouvelle sauvegarde si le profil n'en a pas encore.
func load_or_create(profile_id: String, display_name: String, school_level: String) -> Dictionary:
    var existing: Variant = SaveIO.read(profile_id, _save_schema)
    if existing != null:
        return existing
    var created := SaveFactory.new_save(profile_id, display_name, school_level)
    SaveIO.write(profile_id, created)
    return created


## Lit la sauvegarde d'un profil existant. Null si elle est introuvable (et sa
## copie de secours aussi).
func load(profile_id: String) -> Variant:
    return SaveIO.read(profile_id, _save_schema)


func save(profile_id: String, data: Dictionary) -> bool:
    return SaveIO.write(profile_id, data)


func delete(profile_id: String) -> void:
    SaveIO.delete(profile_id)


func list_profile_ids() -> Array[String]:
    return SaveIO.list_profile_ids()
