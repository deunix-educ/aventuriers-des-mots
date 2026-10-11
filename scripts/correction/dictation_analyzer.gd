class_name DictationAnalyzer
extends RefCounted
## Analyse la production ecrite d'un enfant pour une dictee : alignement mot a
## mot (WordAligner) avant comparaison, normalisation (TextNormalizer), puis
## classification de chaque erreur via les annotations de la donnee cible
## (dictation["words"]). Sans annotation (pas de rule_id), l'erreur reste non
## classee (voir "Points durs" du prompt de lancement). Code pur, sans horloge
## ni hasard. L'explication complete (texte de la regle) est composee par la
## couche d'affichage a partir des rule_id retournes, pas ici.

## Ponctuation de fin de phrase ignoree a la comparaison : l'audio provisoire
## (point 19/20 de docs/specs/decisions.md) ne la fait pas entendre, donc rien
## dans ce que l'enfant ecoute ne lui indique qu'il faut l'ecrire. L'exiger
## serait sanctionner une information qu'il n'a pas recue (CLAUDE.md : une
## erreur declenche une explication, jamais une punition).
const TERMINAL_PUNCTUATION := ".!?…"


static func analyze(dictation: Dictionary, submitted_text: String) -> CorrectionResult:
    var normalized_submitted := TextNormalizer.normalize(submitted_text)
    var normalized_target := TextNormalizer.normalize(dictation["target_text"])

    if _matches_target_or_variant(dictation, normalized_submitted, normalized_target):
        return CorrectionResult.correct(_build_explanation(0))

    var target_words := TextNormalizer.split_words(_strip_terminal_punctuation(normalized_target))
    var submitted_words := TextNormalizer.split_words(
        _strip_terminal_punctuation(normalized_submitted)
    )
    var words_meta: Array = dictation["words"]

    # L'alignement se fait insensible a la casse : une majuscule manquante est
    # une erreur de capitalisation a part, pas un mot substitue (voir
    # docs/specs/decisions.md point 6).
    var target_words_for_align := _to_lower_all(target_words)
    var submitted_words_for_align := _to_lower_all(submitted_words)
    var ops := WordAligner.align(target_words_for_align, submitted_words_for_align)
    var errors: Array[Dictionary] = []

    for op: Dictionary in ops:
        match op["op"]:
            "match":
                var capital_error: Variant = _check_capitalization(
                    words_meta, op["target_index"], submitted_words[op["submitted_index"]]
                )
                if capital_error != null:
                    errors.append(capital_error)
            "substitute":
                (
                    errors
                    . append(
                        _classify_error(
                            words_meta,
                            op["target_index"],
                            submitted_words[op["submitted_index"]],
                        )
                    )
                )
            "delete":
                errors.append(_classify_error(words_meta, op["target_index"], ""))
            "insert":
                (
                    errors
                    . append(
                        {
                            "position": target_words.size(),
                            "error_type": "unclassified",
                            "rule_id": "",
                            "found": submitted_words[op["submitted_index"]],
                            "expected": "",
                        }
                    )
                )

    if errors.is_empty():
        return CorrectionResult.correct(_build_explanation(0))

    return CorrectionResult.incorrect(
        errors, _build_explanation(errors.size()), "", [dictation["target_text"]]
    )


static func _matches_target_or_variant(
    dictation: Dictionary, normalized_submitted: String, normalized_target: String
) -> bool:
    var stripped_submitted := _strip_terminal_punctuation(normalized_submitted)
    if stripped_submitted == _strip_terminal_punctuation(normalized_target):
        return true
    for variant: String in dictation.get("accepted_variants", []):
        if stripped_submitted == _strip_terminal_punctuation(TextNormalizer.normalize(variant)):
            return true
    return false


## Retire les signes de ponctuation terminale (un ou plusieurs, ex. "?!") en
## fin de texte. N'affecte pas la ponctuation interne a la phrase.
static func _strip_terminal_punctuation(text: String) -> String:
    var result := text
    while (
        not result.is_empty()
        and TERMINAL_PUNCTUATION.find(result.substr(result.length() - 1)) != -1
    ):
        result = result.substr(0, result.length() - 1)
    return result.strip_edges()


static func _classify_error(words_meta: Array, target_index: int, found: String) -> Dictionary:
    var meta: Dictionary = words_meta[target_index] if target_index < words_meta.size() else {}
    var expected: String = meta.get("text", "")
    var rule_id: String = meta.get("rule_id", "")
    return {
        "position": target_index,
        "error_type": "grammatical" if not rule_id.is_empty() else "unclassified",
        "rule_id": rule_id,
        "found": found,
        "expected": expected,
    }


static func _check_capitalization(
    words_meta: Array, target_index: int, submitted_word: String
) -> Variant:
    if target_index >= words_meta.size() or submitted_word.is_empty():
        return null
    var meta: Dictionary = words_meta[target_index]
    if not meta.get("expects_capital", false):
        return null
    var first_letter := submitted_word.substr(0, 1)
    if first_letter == first_letter.to_upper():
        return null
    return {
        "position": target_index,
        "error_type": "capitalization",
        "rule_id": meta.get("rule_id", ""),
        "found": submitted_word,
        "expected": meta.get("text", submitted_word),
    }


static func _to_lower_all(words: Array[String]) -> Array[String]:
    var result: Array[String] = []
    for word in words:
        result.append(word.to_lower())
    return result


static func _build_explanation(error_count: int) -> String:
    if error_count == 0:
        return "Dictee correcte."
    return "Dictee corrigee : %d erreur(s) a revoir." % error_count
