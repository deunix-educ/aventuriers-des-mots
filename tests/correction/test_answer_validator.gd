extends GutTest
## Tests de AnswerValidator (choix multiple et correction de phrase).

var multiple_choice_exercise: Dictionary = {
    "rule_id": "regle_test",
    "answers": ["petit", "petits", "petite"],
    "correct_answer": 1,
    "hint": "indice",
    "explanation": "explication",
}

var sentence_correction_exercise: Dictionary = {
    "rule_id": "regle_test",
    "hint": "indice",
    "explanation": "explication",
    "tokens":
    [
        {"text": "Les", "correct": true},
        {
            "text": "petit",
            "correct": false,
            "expected": "petits",
            "rule_id": "regle_accord_adjectif",
        },
        {"text": "chiens", "correct": true},
    ],
}


func test_multiple_choice_correct_answer() -> void:
    var result := AnswerValidator.validate_multiple_choice(multiple_choice_exercise, 1)
    assert_true(result.is_correct)
    assert_eq(result.errors, [])


func test_multiple_choice_wrong_answer_reports_found_and_expected() -> void:
    var result := AnswerValidator.validate_multiple_choice(multiple_choice_exercise, 0)
    assert_false(result.is_correct)
    assert_eq(result.errors.size(), 1)
    assert_eq(result.errors[0]["found"], "petit")
    assert_eq(result.errors[0]["expected"], "petits")
    assert_eq(result.errors[0]["rule_id"], "regle_test")


func test_sentence_correction_fully_correct() -> void:
    var result := AnswerValidator.validate_sentence_correction(
        sentence_correction_exercise, [1], {1: "petits"}
    )
    assert_true(result.is_correct)


func test_sentence_correction_missed_faulty_token() -> void:
    var result := AnswerValidator.validate_sentence_correction(sentence_correction_exercise, [], {})
    assert_false(result.is_correct)
    assert_eq(result.errors.size(), 1)
    assert_eq(result.errors[0]["rule_id"], "regle_accord_adjectif")
    assert_eq(result.errors[0]["found"], "petit")
    assert_eq(result.errors[0]["expected"], "petits")


func test_sentence_correction_wrong_correction_text() -> void:
    var result := AnswerValidator.validate_sentence_correction(
        sentence_correction_exercise, [1], {1: "petite"}
    )
    assert_false(result.is_correct)
    assert_eq(result.errors[0]["found"], "petite")
    assert_eq(result.errors[0]["expected"], "petits")


func test_sentence_correction_false_positive_on_correct_token() -> void:
    var result := AnswerValidator.validate_sentence_correction(
        sentence_correction_exercise, [1, 2], {1: "petits", 2: "chien"}
    )
    assert_false(result.is_correct)
    assert_eq(result.errors.size(), 1)
    assert_eq(result.errors[0]["error_type"], "unclassified")
    assert_eq(result.errors[0]["position"], 2)
