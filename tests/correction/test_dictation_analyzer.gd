extends GutTest
## Tests de DictationAnalyzer : alignement, classification lexicale/grammaticale
## via annotation, majuscule, variantes acceptees.

var dictation: Dictionary = {
    "target_text": "Les petits chats dorment.",
    "words":
    [
        {"text": "Les", "expects_capital": true},
        {"text": "petits", "rule_id": "regle_accord_adjectif"},
        {"text": "chats"},
        {"text": "dorment."},
    ],
    "accepted_variants": [],
}


func test_exact_match_is_correct() -> void:
    var result := DictationAnalyzer.analyze(dictation, "Les petits chats dorment.")
    assert_true(result.is_correct)
    assert_eq(result.errors, [])


func test_annotated_word_error_is_classified_as_grammatical() -> void:
    var result := DictationAnalyzer.analyze(dictation, "Les petit chats dorment.")
    assert_false(result.is_correct)
    assert_eq(result.errors.size(), 1)
    assert_eq(result.errors[0]["error_type"], "grammatical")
    assert_eq(result.errors[0]["rule_id"], "regle_accord_adjectif")
    assert_eq(result.errors[0]["found"], "petit")
    assert_eq(result.errors[0]["expected"], "petits")


func test_unannotated_word_error_is_unclassified() -> void:
    var result := DictationAnalyzer.analyze(dictation, "Les petits chat dorment.")
    assert_false(result.is_correct)
    assert_eq(result.errors.size(), 1)
    assert_eq(result.errors[0]["error_type"], "unclassified")
    assert_eq(result.errors[0]["rule_id"], "")


func test_missing_word_does_not_cascade_into_further_errors() -> void:
    # Le mot "petits" est omis : sans alignement, cela provoquerait deux
    # erreurs en cascade sur "chats" et "dorment.".
    var result := DictationAnalyzer.analyze(dictation, "Les chats dorment.")
    assert_false(result.is_correct)
    assert_eq(result.errors.size(), 1)
    assert_eq(result.errors[0]["rule_id"], "regle_accord_adjectif")


func test_missing_capital_is_reported_separately() -> void:
    var result := DictationAnalyzer.analyze(dictation, "les petits chats dorment.")
    assert_false(result.is_correct)
    assert_eq(result.errors.size(), 1)
    assert_eq(result.errors[0]["error_type"], "capitalization")


func test_accepted_variant_is_treated_as_correct() -> void:
    var dictation_with_variant: Dictionary = dictation.duplicate(true)
    dictation_with_variant["accepted_variants"] = ["Les petits chats dorment"]
    var result := DictationAnalyzer.analyze(dictation_with_variant, "Les petits chats dorment")
    assert_true(result.is_correct)


func test_normalizes_before_comparing() -> void:
    var result := DictationAnalyzer.analyze(dictation, "Les petits chats dorment.")
    assert_true(result.is_correct)
