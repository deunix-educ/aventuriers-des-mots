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


func test_sentence_correction_accepts_correction_with_different_case() -> void:
    # Rapporte manuellement : "Petits" (majuscule incidente, ex. autocapitalisation)
    # devait etre accepte au meme titre que "petits".
    var result := AnswerValidator.validate_sentence_correction(
        sentence_correction_exercise, [1], {1: "Petits"}
    )
    assert_true(result.is_correct)


func test_sentence_correction_accepts_correction_with_surrounding_whitespace() -> void:
    var result := AnswerValidator.validate_sentence_correction(
        sentence_correction_exercise, [1], {1: "  petits  "}
    )
    assert_true(result.is_correct)


func test_sentence_correction_accepts_decomposed_accented_correction() -> void:
    var exercise_with_accent: Dictionary = {
        "rule_id": "regle_test",
        "hint": "indice",
        "explanation": "explication",
        "tokens":
        [
            {
                "text": "lecole",
                "correct": false,
                "expected": "école",
                "rule_id": "regle_accord_adjectif",
            },
        ],
    }
    # "e" + accent aigu combinant (U+0301), forme decomposee du meme mot.
    var result := AnswerValidator.validate_sentence_correction(
        exercise_with_accent, [0], {0: "école"}
    )
    assert_true(result.is_correct)


func _elision_exercise() -> Dictionary:
    return {
        "rule_id": "regle_x",
        "hint": "indice",
        "explanation": "explication",
        "tokens":
        [
            {"text": "Si", "correct": true},
            {"text": "j'achèterai", "correct": false, "expected": "j'achèterais"},
            {"text": "une", "correct": true},
        ],
    }


func test_elided_token_accepts_the_whole_word_or_only_the_verb() -> void:
    var exercise := _elision_exercise()
    for typed in ["j'achèterais", "J'achèterais", "j’achèterais", "achèterais", " achèterais "]:
        var result := AnswerValidator.validate_sentence_correction(exercise, [1], {1: typed})
        assert_true(result.is_correct, "« %s » doit etre accepte" % typed)


func test_elided_token_still_rejects_a_wrong_correction() -> void:
    var exercise := _elision_exercise()
    for typed in ["j'achèterai", "achèterai", "achetterais", ""]:
        var result := AnswerValidator.validate_sentence_correction(exercise, [1], {1: typed})
        assert_false(result.is_correct, "« %s » ne doit pas etre accepte" % typed)


func test_expected_without_elision_accepts_the_prefix_of_the_touched_word() -> void:
    var exercise := _elision_exercise()
    exercise["tokens"][1]["expected"] = "achèterais"
    for typed in ["achèterais", "j'achèterais"]:
        var result := AnswerValidator.validate_sentence_correction(exercise, [1], {1: typed})
        assert_true(result.is_correct, "« %s » doit etre accepte" % typed)


func test_correction_does_not_require_the_final_punctuation_of_the_word() -> void:
    # Le mot touche porte souvent le point de la phrase (« roze. ») : taper
    # « rose » ou « rose. » est correct, « roze » ne l'est pas.
    var exercise := {
        "rule_id": "regle_x",
        "hint": "indice",
        "explanation": "explication",
        "tokens":
        [
            {"text": "La", "correct": true},
            {"text": "roze.", "correct": false, "expected": "rose."},
        ],
    }
    for typed in ["rose", "rose.", "Rose", " rose "]:
        var result := AnswerValidator.validate_sentence_correction(exercise, [1], {1: typed})
        assert_true(result.is_correct, "« %s » doit etre accepte" % typed)
    for typed in ["roze", "roze.", "rosse", ""]:
        var result := AnswerValidator.validate_sentence_correction(exercise, [1], {1: typed})
        assert_false(result.is_correct, "« %s » ne doit pas etre accepte" % typed)
