class_name SaveMigration
extends RefCounted
## Migration des sauvegardes entre versions de schema. Code pur. Chaque
## montee de version ajoute une etape a la chaine ci-dessous, sans jamais
## reecrire les etapes passees.
## Version 2 : ajout de mission_results (meilleur score par mission).

const CURRENT_SCHEMA_VERSION := 2


## Retourne un dictionnaire vide si la version est absente, invalide, ou plus
## recente que ce que cette version du moteur sait lire : refuser plutot que
## de deviner et corrompre la progression de l'enfant.
static func migrate(data: Dictionary) -> Dictionary:
    if not data.has("schema_version"):
        return {}
    var version: Variant = data["schema_version"]
    if typeof(version) != TYPE_INT and typeof(version) != TYPE_FLOAT:
        return {}
    var version_int: int = int(version)
    if version_int < 1 or version_int > CURRENT_SCHEMA_VERSION:
        return {}

    var migrated: Dictionary = data.duplicate(true)
    if version_int == 1:
        migrated = _migrate_v1_to_v2(migrated)
        version_int = 2
    migrated["schema_version"] = CURRENT_SCHEMA_VERSION
    return migrated


## Les etoiles deja gagnees (rewards.stars) sont conservees telles quelles ;
## le detail par mission n'existait pas, il repart vide.
static func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
    var migrated: Dictionary = data.duplicate(true)
    if not migrated.has("mission_results"):
        migrated["mission_results"] = {}
    return migrated
