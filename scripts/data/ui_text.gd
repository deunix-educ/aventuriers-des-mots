class_name UIText
extends RefCounted
## Textes d'interface destines a l'enfant, charges depuis
## data/localization/fr.json : jamais en dur dans les scripts ou les scenes
## (voir CLAUDE.md, Conventions de code).

const LOCALIZATION_PATH := "res://data/localization/fr.json"

static var _cache: Dictionary = {}


static func get_text(key: String) -> String:
    if _cache.is_empty():
        _load()
    if not _cache.has(key):
        push_error("Cle de traduction manquante : %s" % key)
        return key
    return _cache[key]


static func _load() -> void:
    var file := FileAccess.open(LOCALIZATION_PATH, FileAccess.READ)
    if file == null:
        push_error("Fichier de traduction introuvable : %s" % LOCALIZATION_PATH)
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    _cache = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
