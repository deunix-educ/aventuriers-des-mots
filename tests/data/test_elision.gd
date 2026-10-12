extends GutTest
## Garde-fou orthographique sur tous les textes du jeu : « le arbre » doit
## s'ecrire « l'arbre ». Parcourt tous les JSON de data/ (chaines et listes de
## mots consecutifs) a la recherche d'une elision manquante. Les mots a « h »
## aspire et quelques exceptions legitimes sont listes ci-dessous.

const DATA_DIR := "res://data"
## Mots a « h » aspire ou vocalique sans elision : « le hibou », « le onze ».
const NO_ELISION_WORDS: Array[String] = [
    "hibou",
    "hublot",
    "hublots",
    "haie",
    "haies",
    "héros",
    "hérisson",
    "hamac",
    "hanche",
    "hangar",
    "haricot",
    "haricots",
    "hasard",
    "hache",
    "hauteur",
    "haut",
    "haute",
    "hautes",
    "hauts",
    "hall",
    "hameau",
    "harpe",
    "hâte",
    "hérissons",
    "hurlement",
    "huit",
    "onze",
    "oui",
    "ouistiti",
    "yaourt",
    "yeux",
    "ukulélé",
]

## (*UCP) : \\w couvre les lettres accentuees. Motif : mot d'elision, espaces,
## puis mot a voyelle ou « h » initial ; l'assertion arriere ecarte « écris-la en ».
const PATTERN := (
    "(*UCP)(?<![-\\w'’])(?i)(le|la|de|que|ne|se|me|te|je|ce)\\s+"
    + "([aeiouâàäéèêëîïôöûùüœh][\\wàâäéèêëîïôöûùüçœ]*)"
)

var _regex := RegEx.new()
var _problems: Array[String] = []


func before_all() -> void:
    _regex.compile(PATTERN)


func test_no_missing_elision_in_game_texts() -> void:
    _scan_dir(DATA_DIR)
    assert_eq(_problems.size(), 0, "Elisions manquantes : %s" % "\n".join(_problems))


func test_no_missing_elision_once_the_blank_or_the_error_is_filled_in() -> void:
    # Une phrase a trous ou a corriger n'est pas verifiable mot a mot : on
    # reconstitue la phrase correcte (« ... arbre » + « Le » = « Le arbre »).
    _problems.clear()
    for path in _json_files("res://data/exercises"):
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
            _check_text(sentence, "%s (phrase reconstituee)" % data["id"])
    assert_eq(_problems.size(), 0, "Elisions manquantes : %s" % "\n".join(_problems))


func test_detector_catches_a_missing_elision() -> void:
    _problems.clear()
    _check_text("le arbre est grand", "exemple")
    assert_eq(_problems.size(), 1)
    _problems.clear()
    _check_text("Le hibou dort. Écris-la en entier. Le onze.", "exemple")
    assert_eq(_problems.size(), 0)


func _scan_dir(path: String) -> void:
    var dir := DirAccess.open(path)
    if dir == null:
        return
    for sub in dir.get_directories():
        if sub != "schemas":
            _scan_dir(path.path_join(sub))
    for file_name in dir.get_files():
        if file_name.ends_with(".json"):
            _scan_file(path.path_join(file_name))


func _scan_file(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.READ)
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    _scan_value(parsed, path)


func _scan_value(value: Variant, where: String) -> void:
    if typeof(value) == TYPE_STRING:
        _check_text(value, where)
    elif typeof(value) == TYPE_DICTIONARY:
        for key: Variant in value:
            _scan_value(value[key], where)
    elif typeof(value) == TYPE_ARRAY:
        var items: Array = value
        # Mots consecutifs d'une phrase decoupee en jetons.
        for i in range(items.size() - 1):
            if typeof(items[i]) == TYPE_STRING and typeof(items[i + 1]) == TYPE_STRING:
                _check_text("%s %s" % [items[i], items[i + 1]], where)
        for item: Variant in items:
            _scan_value(item, where)


func _check_text(text: String, where: String) -> void:
    for match in _regex.search_all(text):
        var next_word := match.get_string(2).to_lower()
        if NO_ELISION_WORDS.has(next_word):
            continue
        _problems.append("%s : « %s »" % [where, match.get_string(0)])


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
