class_name SemanticChecks
extends RefCounted
## Contraintes croisees entre champs qu'un schema JSON (voir SchemaValidator) ne
## peut pas exprimer : index valide, coherence entre deux tableaux, etc.
## Appele uniquement apres une validation de schema reussie : ces fonctions
## supposent une structure deja conforme.


static func check_multiple_choice(data: Dictionary, path: String) -> Array[String]:
    var errors: Array[String] = []
    var answers: Array = data.get("answers", [])
    var correct_answer: int = data.get("correct_answer", -1)
    if correct_answer < 0 or correct_answer >= answers.size():
        errors.append(
            (
                "%s : correct_answer (%d) hors des bornes de answers (%d element(s))"
                % [path, correct_answer, answers.size()]
            )
        )
    return errors


static func check_sentence_correction(data: Dictionary, path: String) -> Array[String]:
    var errors: Array[String] = []
    var tokens: Array = data.get("tokens", [])
    var has_error_token := false
    for i in tokens.size():
        var token: Dictionary = tokens[i]
        if token.get("correct", true) == false:
            has_error_token = true
            if not token.has("expected"):
                errors.append(
                    "%s.tokens[%d] : token fautif sans correction attendue ('expected')" % [path, i]
                )
    if not has_error_token:
        errors.append("%s : aucun token fautif, rien a corriger" % path)
    return errors


static func check_dictation(data: Dictionary, path: String) -> Array[String]:
    var errors: Array[String] = []
    var target_text: String = data.get("target_text", "")
    var words: Array = data.get("words", [])
    var expected_word_count := target_text.split(" ", false).size()
    if words.size() != expected_word_count:
        errors.append(
            (
                "%s : %d mot(s) annote(s) pour %d mot(s) dans target_text"
                % [path, words.size(), expected_word_count]
            )
        )
    return errors


static func check_reward_item(data: Dictionary, path: String) -> Array[String]:
    var errors: Array[String] = []
    var unlock: Dictionary = data.get("unlock", {})
    var count: int = int(unlock.get("count", 0))
    match unlock.get("type", ""):
        "total_stars":
            if unlock.has("mission_id"):
                errors.append("%s : total_stars ne prend pas de mission_id" % path)
        "mission_stars":
            if not unlock.has("mission_id"):
                errors.append("%s : mission_stars exige un mission_id" % path)
            if count > 3:
                errors.append(
                    "%s : une mission rapporte au plus 3 etoiles (count=%d)" % [path, count]
                )
    return errors
