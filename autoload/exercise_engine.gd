extends Node
## Chargement et deroulement des exercices a partir des donnees JSON validees.
## Valide chaque fichier au chargement avec le meme validateur que
## `make validate-data` (DataLoader/SchemaValidator, scripts/data/) : un
## fichier invalide est ignore (avec une erreur journalisee), jamais charge
## tel quel. Le tirage au sort d'un exercice est delegue a ExercisePicker,
## pur, avec un generateur aleatoire possede ici (voir CLAUDE.md : le hasard
## est injecte dans la logique pure, pas lu directement par elle).

var _rules: Dictionary = {}
var _exercises_by_rule_and_type: Dictionary = {}
var _dictations_by_rule: Dictionary = {}
var _missions: Dictionary = {}
var _mission_order: Array[String] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    _rng.randomize()
    _load_rules()
    _load_exercises()
    _load_dictations()
    _load_missions()


func get_rule(rule_id: String) -> Dictionary:
    return _rules.get(rule_id, {})


func get_missions() -> Array[Dictionary]:
    var missions: Array[Dictionary] = []
    for mission_id in _mission_order:
        missions.append(_missions[mission_id])
    return missions


func get_mission(mission_id: String) -> Dictionary:
    return _missions.get(mission_id, {})


## Tire le prochain exercice (ou dictee) pour une mission, au plus proche de
## `difficulty`, sans redonner `exclude_id`. Dictionnaire vide si la mission
## n'a aucun contenu disponible.
func pick_exercise_for_mission(
    mission: Dictionary, exclude_id: String, difficulty: int
) -> Dictionary:
    var rule_id: String = mission["rule_id"]
    var exercise_type: String = mission["exercise_type"]
    var candidates: Array[Dictionary] = _candidates_for(rule_id, exercise_type)
    var filtered := _filter_by_difficulty(candidates, difficulty)
    var picked: Variant = ExercisePicker.pick(filtered, exclude_id, _rng)
    return picked if picked != null else {}


## Ne garde que les candidats a la difficulte demandee ; si aucun ne la
## propose, retombe sur l'ensemble des candidats plutot que de n'en donner
## aucun (le contenu disponible est encore limite, voir docs/specs/decisions.md).
func _filter_by_difficulty(candidates: Array[Dictionary], difficulty: int) -> Array[Dictionary]:
    var exact: Array[Dictionary] = []
    for candidate in candidates:
        if int(candidate.get("difficulty", difficulty)) == difficulty:
            exact.append(candidate)
    return exact if not exact.is_empty() else candidates


func _candidates_for(rule_id: String, exercise_type: String) -> Array[Dictionary]:
    if exercise_type == "dictation":
        return _dictations_by_rule.get(rule_id, [] as Array[Dictionary])
    var by_type: Dictionary = _exercises_by_rule_and_type.get(rule_id, {})
    return by_type.get(exercise_type, [] as Array[Dictionary])


func _load_rules() -> void:
    for path in DataLoader.find_json_files("res://data/rules"):
        var errors := DataLoader.validate_file(path, "rule")
        if not errors.is_empty():
            push_error("Regle ignoree (%s) : %s" % [path, errors])
            continue
        var rule: Dictionary = DataLoader.read_json(path)
        _rules[rule["rule_id"]] = rule


func _load_exercises() -> void:
    for path in DataLoader.find_json_files("res://data/exercises"):
        var raw: Variant = DataLoader.read_json(path)
        if typeof(raw) != TYPE_DICTIONARY or not raw.has("type"):
            push_error("Exercice ignore (%s) : type manquant ou JSON invalide" % path)
            continue
        var exercise: Dictionary = raw
        var exercise_type: String = exercise["type"]
        var schema_name := DataLoader.exercise_schema_name_for_type(exercise_type)
        if schema_name.is_empty():
            push_error("Exercice ignore (%s) : type inconnu '%s'" % [path, exercise_type])
            continue
        var errors := SchemaValidator.validate(exercise, DataLoader.load_schema(schema_name))
        if not errors.is_empty():
            push_error("Exercice ignore (%s) : %s" % [path, errors])
            continue

        var rule_id: String = exercise["rule_id"]
        if not _exercises_by_rule_and_type.has(rule_id):
            _exercises_by_rule_and_type[rule_id] = {}
        var by_type: Dictionary = _exercises_by_rule_and_type[rule_id]
        if not by_type.has(exercise_type):
            by_type[exercise_type] = [] as Array[Dictionary]
        (by_type[exercise_type] as Array[Dictionary]).append(exercise)


func _load_dictations() -> void:
    for path in DataLoader.find_json_files("res://data/dictations"):
        var errors := DataLoader.validate_file(path, "dictation")
        if not errors.is_empty():
            push_error("Dictee ignoree (%s) : %s" % [path, errors])
            continue
        var dictation: Dictionary = DataLoader.read_json(path)
        for rule_id: String in dictation["rule_ids"]:
            if not _dictations_by_rule.has(rule_id):
                _dictations_by_rule[rule_id] = [] as Array[Dictionary]
            (_dictations_by_rule[rule_id] as Array[Dictionary]).append(dictation)


func _load_missions() -> void:
    var mission_ids: Array[String] = []
    for path in DataLoader.find_json_files("res://data/missions"):
        var errors := DataLoader.validate_file(path, "mission")
        if not errors.is_empty():
            push_error("Mission ignoree (%s) : %s" % [path, errors])
            continue
        var mission: Dictionary = DataLoader.read_json(path)
        _missions[mission["mission_id"]] = mission
        mission_ids.append(mission["mission_id"])
    mission_ids.sort()
    _mission_order = mission_ids
