class_name SaveFactory
extends RefCounted
## Construit une nouvelle sauvegarde vide pour un profil, conforme a
## data/schemas/save.schema.json. Code pur.


static func new_save(profile_id: String, display_name: String, school_level: String) -> Dictionary:
    return {
        "schema_version": SaveMigration.CURRENT_SCHEMA_VERSION,
        "profile_id": profile_id,
        "display_name": display_name,
        "school_level": school_level,
        "session_count": 0,
        "unlocked_regions": [],
        "skills": {},
        "rewards": {"stars": 0, "items": []},
    }
