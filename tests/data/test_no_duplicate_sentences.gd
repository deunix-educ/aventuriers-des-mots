extends GutTest
## Aucune phrase ne doit apparaitre deux fois dans le jeu (exercices et
## dictees confondus) : un meme enonce revu dans deux missions est une
## redite, pas un nouvel exercice. La phrase est reconstituee en version
## correcte (blanc rempli, mot fautif corrige) puis comparee sans casse ni
## ponctuation.

const EXERCISES_DIR := "res://data/exercises"
const DICTATIONS_DIR := "res://data/dictations"


func test_no_sentence_is_used_twice() -> void:
    var seen: Dictionary = {}
    var duplicates: Array[String] = []
    for entry in _collect_sentences():
        var key := _normalize(entry["sentence"])
        if seen.has(key):
            duplicates.append("« %s » : %s et %s" % [entry["sentence"], seen[key], entry["id"]])
        else:
            seen[key] = entry["id"]
    assert_eq(duplicates.size(), 0, "Phrases en double :\n%s" % "\n".join(duplicates))
    assert_gt(seen.size(), 100, "le test doit avoir vu les phrases du jeu")


func _collect_sentences() -> Array[Dictionary]:
    var sentences: Array[Dictionary] = []
    for path in _json_files(EXERCISES_DIR):
        var data := _read(path)
        var sentence := ""
        if data.get("type", "") == "multiple_choice":
            var answers: Array = data["answers"]
            sentence = str(data["question"]).replace(
                "...", str(answers[int(data["correct_answer"])])
            )
        elif data.get("type", "") == "sentence_correction":
            var words: Array[String] = []
            for token: Dictionary in data["tokens"]:
                words.append(token["text"] if token["correct"] else token["expected"])
            sentence = " ".join(words)
        if not sentence.is_empty():
            sentences.append({"id": data["id"], "sentence": sentence})
    for path in _json_files(DICTATIONS_DIR):
        var data := _read(path)
        sentences.append({"id": data["id"], "sentence": data["target_text"]})
    return sentences


func _normalize(sentence: String) -> String:
    var cleaned := ""
    for character in sentence.to_lower():
        if character.is_valid_int() or character == "'" or character == " ":
            cleaned += character
        elif character.to_upper() != character or "éèêàâîïôûùçœ".contains(character):
            cleaned += character
        else:
            cleaned += " "
    var parts := cleaned.split(" ", false)
    return " ".join(parts)


func _json_files(path: String) -> Array[String]:
    var found: Array[String] = []
    var dir := DirAccess.open(path)
    if dir == null:
        return found
    for sub in dir.get_directories():
        found.append_array(_json_files(path.path_join(sub)))
    for file_name in dir.get_files():
        if file_name.ends_with(".json"):
            found.append(path.path_join(file_name))
    return found


func _read(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
