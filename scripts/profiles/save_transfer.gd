class_name SaveTransfer
extends RefCounted
## Export et restauration d'une sauvegarde de profil vers un dossier choisi par
## l'adulte (cahier des charges §10). Le fichier exporte est exactement la
## sauvegarde versionnee du profil : le format n'est pas modifie. La
## restauration est non destructive : elle cree toujours un NOUVEAU profil
## (identifiant neuf) et n'ecrase jamais un profil existant. Pas pur (touche le
## systeme de fichiers) mais sans arbre de scenes : testable en headless.

const EXPORT_FOLDER_NAME := "AventuriersDesMots"


## Dossier d'export par defaut : Documents de l'utilisateur, ou user://exports
## si la plateforme n'en expose pas.
static func default_export_dir() -> String:
    var documents := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
    if documents.is_empty():
        return "user://exports"
    return documents.path_join(EXPORT_FOLDER_NAME)


## Exporte le profil `profile_id` dans `dest_dir`. Renvoie le chemin du fichier
## cree, ou "" en cas d'echec (profil illisible, dossier non inscriptible).
static func export_profile(profile_id: String, schema: Dictionary, dest_dir: String) -> String:
    var save: Variant = SaveIO.read(profile_id, schema)
    if save == null:
        return ""
    if (
        DirAccess.make_dir_recursive_absolute(dest_dir) != OK
        and not DirAccess.dir_exists_absolute(dest_dir)
    ):
        return ""
    var base := _safe_file_stem(save["display_name"], save["school_level"])
    var path := dest_dir.path_join(base + ".json")
    var counter := 2
    while FileAccess.file_exists(path):
        path = dest_dir.path_join("%s_%d.json" % [base, counter])
        counter += 1
    var tmp_path := path + ".tmp"
    var file := FileAccess.open(tmp_path, FileAccess.WRITE)
    if file == null:
        return ""
    file.store_string(JSON.stringify(save, "  "))
    file.close()
    var dir := DirAccess.open(dest_dir)
    if dir == null or dir.rename(tmp_path, path) != OK:
        return ""
    return path


## Fichiers de sauvegarde exportes trouves dans `dir`, tries par nom : chemin,
## nom d'affichage et niveau, ou valid=false pour un fichier illisible.
static func list_exports(dir_path: String, schema: Dictionary) -> Array[Dictionary]:
    var found: Array[Dictionary] = []
    var dir := DirAccess.open(dir_path)
    if dir == null:
        return found
    var names: Array[String] = []
    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        if not dir.current_is_dir() and entry.ends_with(".json"):
            names.append(entry)
        entry = dir.get_next()
    names.sort()
    for file_name in names:
        var path := dir_path.path_join(file_name)
        var save: Variant = read_export(path, schema)
        if save == null:
            found.append({"path": path, "valid": false, "display_name": "", "school_level": ""})
        else:
            (
                found
                . append(
                    {
                        "path": path,
                        "valid": true,
                        "display_name": save["display_name"],
                        "school_level": save["school_level"],
                    }
                )
            )
    return found


## Lit, migre et valide un fichier exporte. Null s'il n'est pas une sauvegarde
## valable (JSON invalide, schema non respecte, version inconnue).
static func read_export(path: String, schema: Dictionary) -> Variant:
    if not FileAccess.file_exists(path):
        return null
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null
    # JSON.new().parse() renvoie un code d'erreur au lieu de journaliser une
    # erreur moteur : un fichier choisi par l'adulte peut etre n'importe quoi.
    var json := JSON.new()
    if json.parse(file.get_as_text()) != OK or typeof(json.data) != TYPE_DICTIONARY:
        return null
    var parsed: Dictionary = json.data
    var migrated: Dictionary = SaveMigration.migrate(parsed)
    if migrated.is_empty():
        return null
    if not SchemaValidator.validate(migrated, schema).is_empty():
        return null
    return migrated


## Restaure le fichier `path` comme nouveau profil `new_profile_id`. Renvoie
## true si la sauvegarde a ete ecrite.
static func import_as_new_profile(path: String, schema: Dictionary, new_profile_id: String) -> bool:
    var save: Variant = read_export(path, schema)
    if save == null:
        return false
    var restored: Dictionary = save
    restored["profile_id"] = new_profile_id
    return SaveIO.write(new_profile_id, restored)


static func _safe_file_stem(display_name: String, school_level: String) -> String:
    # On retire seulement ce qu'un systeme de fichiers refuse ; les accents
    # restent, pour que « Léa » reste « Léa ».
    var forbidden := '/\\:*?"<>|.'
    var cleaned := ""
    for character in display_name.strip_edges():
        if character == " ":
            cleaned += "_"
        elif not forbidden.contains(character) and character.unicode_at(0) >= 32:
            cleaned += character
    if cleaned.is_empty():
        cleaned = "profil"
    return "%s_%s" % [cleaned, school_level]
