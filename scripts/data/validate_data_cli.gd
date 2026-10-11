extends SceneTree
## Outil headless invoque par `make validate-data`.
## Valide chaque fichier JSON de data/ contre son schema (data/schemas/), puis
## applique les contraintes croisees que le schema ne peut pas exprimer.


func _init() -> void:
    var failures: Array[String] = []
    var checked := 0

    checked += _validate_simple_dir("res://data/rules", "rule", failures)
    checked += _validate_simple_dir("res://data/curriculum", "curriculum", failures)
    checked += _validate_dictations("res://data/dictations", failures)
    checked += _validate_exercises("res://data/exercises", failures)
    checked += _validate_missions("res://data/missions", failures)
    checked += _validate_simple_dir("res://data/localization", "localization", failures)

    if failures.is_empty():
        print("validate-data : %d fichier(s) JSON valide(s)" % checked)
        quit(0)
    else:
        for failure in failures:
            printerr(failure)
        printerr("validate-data : %d erreur(s)" % failures.size())
        quit(1)


func _validate_simple_dir(dir_path: String, schema_name: String, failures: Array[String]) -> int:
    var count := 0
    for path in DataLoader.find_json_files(dir_path):
        count += 1
        failures.append_array(DataLoader.validate_file(path, schema_name))
    return count


func _validate_dictations(dir_path: String, failures: Array[String]) -> int:
    var count := 0
    for path in DataLoader.find_json_files(dir_path):
        count += 1
        var schema_errors := DataLoader.validate_file(path, "dictation")
        failures.append_array(schema_errors)
        if schema_errors.is_empty():
            var data: Dictionary = DataLoader.read_json(path)
            failures.append_array(SemanticChecks.check_dictation(data, path))
    return count


func _validate_missions(dir_path: String, failures: Array[String]) -> int:
    var known_rule_ids: Array[String] = []
    for path in DataLoader.find_json_files("res://data/rules"):
        var rule: Variant = DataLoader.read_json(path)
        if typeof(rule) == TYPE_DICTIONARY and rule.has("rule_id"):
            known_rule_ids.append(rule["rule_id"])

    var count := 0
    for path in DataLoader.find_json_files(dir_path):
        count += 1
        var schema_errors := DataLoader.validate_file(path, "mission")
        failures.append_array(schema_errors)
        if not schema_errors.is_empty():
            continue
        var data: Dictionary = DataLoader.read_json(path)
        if not known_rule_ids.has(data["rule_id"]):
            var message := (
                "%s : rule_id '%s' ne correspond a aucune regle de data/rules"
                % [path, data["rule_id"]]
            )
            failures.append(message)
    return count


func _validate_exercises(dir_path: String, failures: Array[String]) -> int:
    var count := 0
    for path in DataLoader.find_json_files(dir_path):
        count += 1
        var data: Variant = DataLoader.read_json(path)
        if data == null or typeof(data) != TYPE_DICTIONARY or not data.has("type"):
            failures.append("%s : champ 'type' manquant ou JSON invalide" % path)
            continue
        var exercise_type: String = data["type"]
        var schema_name := DataLoader.exercise_schema_name_for_type(exercise_type)
        if schema_name.is_empty():
            failures.append("%s : type d'exercice inconnu '%s'" % [path, exercise_type])
            continue
        var schema_errors := DataLoader.validate_file(path, schema_name)
        failures.append_array(schema_errors)
        if not schema_errors.is_empty():
            continue
        match exercise_type:
            "multiple_choice":
                failures.append_array(SemanticChecks.check_multiple_choice(data, path))
            "sentence_correction":
                failures.append_array(SemanticChecks.check_sentence_correction(data, path))
    return count
