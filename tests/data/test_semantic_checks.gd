extends GutTest
## Tests des contraintes croisees (scripts/data/semantic_checks.gd).


func test_multiple_choice_rejects_out_of_bounds_correct_answer() -> void:
    var data := { "answers": ["a", "b"], "correct_answer": 5 }
    var errors := SemanticChecks.check_multiple_choice(data, "test")
    assert_eq(errors.size(), 1)


func test_multiple_choice_accepts_valid_index() -> void:
    var data := { "answers": ["a", "b"], "correct_answer": 1 }
    assert_eq(SemanticChecks.check_multiple_choice(data, "test"), [])


func test_sentence_correction_requires_at_least_one_error_token() -> void:
    var data := { "tokens": [{ "text": "Les", "correct": true }] }
    var errors := SemanticChecks.check_sentence_correction(data, "test")
    assert_eq(errors.size(), 1)


func test_sentence_correction_requires_expected_on_error_tokens() -> void:
    var data := { "tokens": [{ "text": "petit", "correct": false }] }
    var errors := SemanticChecks.check_sentence_correction(data, "test")
    assert_eq(errors.size(), 1)
    assert_string_contains(errors[0], "expected")


func test_dictation_word_count_must_match_target_text() -> void:
    var data := {
        "target_text": "Les petits chats dorment.",
        "words": [{ "text": "Les" }, { "text": "petits" }],
    }
    var errors := SemanticChecks.check_dictation(data, "test")
    assert_eq(errors.size(), 1)


func test_dictation_accepts_matching_word_count() -> void:
    var data := {
        "target_text": "Les petits chats dorment.",
        "words": [
            { "text": "Les" }, { "text": "petits" }, { "text": "chats" }, { "text": "dorment." }
        ],
    }
    assert_eq(SemanticChecks.check_dictation(data, "test"), [])
