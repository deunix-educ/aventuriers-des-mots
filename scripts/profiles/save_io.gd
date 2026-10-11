class_name SaveIO
extends RefCounted
## Lecture/ecriture des sauvegardes par profil dans user://saves, avec
## ecriture atomique (fichier temporaire puis remplacement), copie de secours
## en cas de corruption du fichier principal, et migration de schema a la
## lecture. Pas pur (touche le systeme de fichiers), mais sans dependance a
## l'arbre de scenes : testable en headless avec de vrais chemins user://.
## Un profil ne lit et n'ecrit jamais que son propre fichier (nomme par
## profile_id) : deux profils ne peuvent pas se melanger.

const SAVE_DIR := "user://saves"


static func write(profile_id: String, data: Dictionary) -> bool:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)

    var tmp_path := _tmp_path(profile_id)
    var tmp_file := FileAccess.open(tmp_path, FileAccess.WRITE)
    if tmp_file == null:
        return false
    tmp_file.store_string(JSON.stringify(data))
    tmp_file.close()

    var main_path := _save_path(profile_id)
    if FileAccess.file_exists(main_path):
        _copy_file(main_path, _backup_path(profile_id))

    var dir := DirAccess.open(SAVE_DIR)
    if dir == null:
        return false
    return dir.rename(tmp_path, main_path) == OK


## Lit la sauvegarde d'un profil, deja migree vers le schema courant et
## validee contre `schema`. Retourne null si le fichier principal est absent,
## corrompu ou invalide ET que la copie de secours l'est aussi (ou n'existe
## pas).
static func read(profile_id: String, schema: Dictionary) -> Variant:
    var from_main: Variant = _try_read(_save_path(profile_id), schema)
    if from_main != null:
        return from_main
    return _try_read(_backup_path(profile_id), schema)


static func delete(profile_id: String) -> void:
    var dir := DirAccess.open(SAVE_DIR)
    if dir == null:
        return
    for path in [_save_path(profile_id), _backup_path(profile_id), _tmp_path(profile_id)]:
        if FileAccess.file_exists(path):
            dir.remove(path.get_file())


static func list_profile_ids() -> Array[String]:
    var ids: Array[String] = []
    var dir := DirAccess.open(SAVE_DIR)
    if dir == null:
        return ids
    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        if entry.ends_with(".json") and not entry.ends_with(".backup.json"):
            ids.append(entry.get_basename())
        entry = dir.get_next()
    return ids


static func _try_read(path: String, schema: Dictionary) -> Variant:
    var parsed: Variant = _read_raw_json(path)
    if typeof(parsed) != TYPE_DICTIONARY:
        return null
    var migrated: Dictionary = SaveMigration.migrate(parsed)
    if migrated.is_empty():
        return null
    var errors: Array[String] = SchemaValidator.validate(migrated, schema)
    if not errors.is_empty():
        return null
    return migrated


static func _read_raw_json(path: String) -> Variant:
    if not FileAccess.file_exists(path):
        return null
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null
    var text := file.get_as_text()
    if text.strip_edges().is_empty():
        return null
    return JSON.parse_string(text)


static func _copy_file(from_path: String, to_path: String) -> void:
    var source := FileAccess.open(from_path, FileAccess.READ)
    if source == null:
        return
    var bytes := source.get_buffer(source.get_length())
    source.close()
    var dest := FileAccess.open(to_path, FileAccess.WRITE)
    if dest == null:
        return
    dest.store_buffer(bytes)
    dest.close()


static func _save_path(profile_id: String) -> String:
    return "%s/%s.json" % [SAVE_DIR, profile_id]


static func _tmp_path(profile_id: String) -> String:
    return "%s/%s.json.tmp" % [SAVE_DIR, profile_id]


static func _backup_path(profile_id: String) -> String:
    return "%s/%s.backup.json" % [SAVE_DIR, profile_id]
