class_name DataLoader
extends RefCounted
## Charge et valide les fichiers JSON de data/ contre leurs schemas (data/schemas/).
## Meme code utilise par `make validate-data` (headless) et par ExerciseEngine a
## l'execution : une seule source de verite pour la validation (voir
## docs/specs/decisions.md, point 2).

const SCHEMA_DIR := "res://data/schemas"

static var _schema_cache: Dictionary = {}


## Mappe un type d'exercice (champ "type" des donnees) vers le nom de son schema.
## Chaine vide si le type n'est pas reconnu : la liste des types est fermee ici,
## pas devinee ailleurs.
static func exercise_schema_name_for_type(exercise_type: String) -> String:
    match exercise_type:
        "multiple_choice":
            return "exercise_multiple_choice"
        "sentence_correction":
            return "exercise_sentence_correction"
        _:
            return ""


static func load_schema(schema_name: String) -> Dictionary:
    if _schema_cache.has(schema_name):
        return _schema_cache[schema_name]
    var path := "%s/%s.schema.json" % [SCHEMA_DIR, schema_name]
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Schema introuvable : %s" % path)
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    var schema: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
    _schema_cache[schema_name] = schema
    return schema


## Lit un fichier JSON et le valide contre le schema nomme. Retourne la liste des
## erreurs (vide si valide) ; ne retourne jamais les donnees analysees, pour que
## l'appelant ne puisse pas accidentellement utiliser une donnee non validee.
static func validate_file(path: String, schema_name: String) -> Array[String]:
    var parsed: Variant = read_json(path)
    if parsed == null:
        return ["%s : lecture impossible ou JSON invalide" % path]
    var schema := load_schema(schema_name)
    return SchemaValidator.validate(parsed, schema, path)


static func read_json(path: String) -> Variant:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null
    var text := file.get_as_text()
    if text.strip_edges().is_empty():
        return null
    return JSON.parse_string(text)


static func find_json_files(root_path: String) -> Array[String]:
    var result: Array[String] = []
    var dir := DirAccess.open(root_path)
    if dir == null:
        return result
    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        if entry != "." and entry != "..":
            var full_path := root_path.path_join(entry)
            if dir.current_is_dir():
                result.append_array(find_json_files(full_path))
            elif entry.ends_with(".json"):
                result.append(full_path)
        entry = dir.get_next()
    return result
