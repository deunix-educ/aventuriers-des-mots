extends GutTest
## Deux phrases qui ne different que d'un mot (« Les petits chiens courent. »
## / « Les petits chiens jouent. ») donnent a l'enfant l'impression d'une
## redite. On compare les ensembles de mots : au-dela de 75 % de mots communs
## (phrases d'au moins 4 mots), les deux phrases sont jugees trop proches.

const EXERCISES_DIR := "res://data/exercises"
const DICTATIONS_DIR := "res://data/dictations"
const MAX_SIMILARITY := 0.75
const MIN_WORDS := 4


func test_no_two_sentences_are_nearly_identical() -> void:
    var entries := _collect()
    var close: Array[String] = []
    for i in range(entries.size()):
        for j in range(i + 1, entries.size()):
            var a: Array = entries[i]["words"]
            var b: Array = entries[j]["words"]
            if a.size() < MIN_WORDS or b.size() < MIN_WORDS:
                continue
            var common := 0
            for word: String in a:
                if b.has(word):
                    common += 1
            var similarity := float(common) / float(maxi(a.size(), b.size()))
            if similarity >= MAX_SIMILARITY:
                close.append(
                    (
                        "%s « %s » ~ %s « %s »"
                        % [
                            entries[i]["id"],
                            entries[i]["text"],
                            entries[j]["id"],
                            entries[j]["text"]
                        ]
                    )
                )
    assert_eq(close.size(), 0, "Phrases trop proches :\n%s" % "\n".join(close))
    assert_gt(entries.size(), 100)


func _collect() -> Array[Dictionary]:
    var entries: Array[Dictionary] = []
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
            entries.append({"id": data["id"], "text": sentence, "words": _words(sentence)})
    for path in _json_files(DICTATIONS_DIR):
        var data := _read(path)
        var text: String = data["target_text"]
        entries.append({"id": data["id"], "text": text, "words": _words(text)})
    return entries


## Mots distincts, en minuscules, sans ponctuation.
func _words(sentence: String) -> Array[String]:
    var cleaned := ""
    for character in sentence.to_lower():
        if character == "'" or character == " ":
            cleaned += " "
        elif character.to_upper() != character or "éèêàâîïôûùçœ".contains(character):
            cleaned += character
        else:
            cleaned += " "
    var result: Array[String] = []
    for word in cleaned.split(" ", false):
        if not result.has(word):
            result.append(word)
    return result


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
