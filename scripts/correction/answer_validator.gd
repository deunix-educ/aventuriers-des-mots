class_name AnswerValidator
extends RefCounted
## Valide une reponse de choix multiple ou de correction de phrase et produit
## la structure de correction du §6 (voir CorrectionResult). Code pur : aucune
## dependance a l'arbre de scenes, aucune horloge, aucun hasard.


static func validate_multiple_choice(
    exercise: Dictionary, selected_answer: int
) -> CorrectionResult:
    var correct_answer: int = exercise["correct_answer"]
    if selected_answer == correct_answer:
        return CorrectionResult.correct(exercise["explanation"])

    var answers: Array = exercise["answers"]
    var found := ""
    if selected_answer >= 0 and selected_answer < answers.size():
        found = answers[selected_answer]
    var expected: String = answers[correct_answer]

    var error := {
        "position": 0,
        "error_type": "grammatical",
        "rule_id": exercise["rule_id"],
        "found": found,
        "expected": expected,
    }
    return CorrectionResult.incorrect(
        [error], exercise["explanation"], exercise["hint"], [expected]
    )


## selected_indices : index des tokens que l'enfant a touches comme fautifs.
## corrections : correction saisie pour chaque token touche (cle = index du
## token, valeur = texte saisi).
static func validate_sentence_correction(
    exercise: Dictionary, selected_indices: Array[int], corrections: Dictionary
) -> CorrectionResult:
    var tokens: Array = exercise["tokens"]
    var errors: Array[Dictionary] = []

    for i in tokens.size():
        var token: Dictionary = tokens[i]
        var is_faulty: bool = token.get("correct", true) == false
        var was_selected: bool = selected_indices.has(i)

        if is_faulty and not was_selected:
            errors.append(_missed_error(i, token, exercise))
        elif is_faulty and was_selected:
            var submitted: String = corrections.get(i, "")
            if not _matches_expected(submitted, token["expected"], token["text"]):
                errors.append(_wrong_correction_error(i, submitted, token, exercise))
        elif not is_faulty and was_selected:
            errors.append(_false_positive_error(i, token, exercise))

    if errors.is_empty():
        return CorrectionResult.correct(exercise["explanation"])

    var remediation: Array[String] = []
    for token: Dictionary in tokens:
        if token.get("correct", true) == false:
            remediation.append(token["expected"])
    return CorrectionResult.incorrect(
        errors, exercise["explanation"], exercise["hint"], remediation
    )


## Compare la correction saisie a celle attendue en ignorant les differences
## incidentes (majuscule/minuscule, apostrophe typographique, espaces,
## accents decomposes) : ce n'est pas la casse qui est evaluee ici, c'est
## l'accord. Quand le mot touche porte une elision (« j'achèterai »), l'enfant
## peut taper le mot entier (« j'achèterais ») ou seulement le verbe
## (« achèterais ») : une reponse ambigue n'est pas declaree fausse
## automatiquement (CLAUDE.md, invariants pedagogiques).
static func _matches_expected(submitted: String, expected: String, token_text: String = "") -> bool:
    var typed := TextNormalizer.normalize(submitted).to_lower()
    for form in _accepted_forms(expected, token_text):
        if typed == TextNormalizer.normalize(form).to_lower():
            return true
    return false


## Formes acceptees : l'attendu, sans son prefixe d'elision (« j' », « l' »...),
## ou avec le prefixe du mot touche quand l'attendu n'en porte pas.
static func _accepted_forms(expected: String, token_text: String) -> Array[String]:
    var forms: Array[String] = [expected]
    var normalized_expected := TextNormalizer.normalize(expected)
    var normalized_token := TextNormalizer.normalize(token_text)
    var expected_cut := normalized_expected.find("'")
    if expected_cut != -1:
        forms.append(normalized_expected.substr(expected_cut + 1))
    var token_cut := normalized_token.find("'")
    if token_cut != -1 and expected_cut == -1:
        forms.append(normalized_token.substr(0, token_cut + 1) + normalized_expected)
    return forms


static func _missed_error(index: int, token: Dictionary, exercise: Dictionary) -> Dictionary:
    return {
        "position": index,
        "error_type": "grammatical",
        "rule_id": token.get("rule_id", exercise["rule_id"]),
        "found": token["text"],
        "expected": token["expected"],
    }


static func _wrong_correction_error(
    index: int, submitted: String, token: Dictionary, exercise: Dictionary
) -> Dictionary:
    return {
        "position": index,
        "error_type": "grammatical",
        "rule_id": token.get("rule_id", exercise["rule_id"]),
        "found": submitted,
        "expected": token["expected"],
    }


static func _false_positive_error(
    index: int, token: Dictionary, exercise: Dictionary
) -> Dictionary:
    return {
        "position": index,
        "error_type": "unclassified",
        "rule_id": exercise["rule_id"],
        "found": token["text"],
        "expected": token["text"],
    }
