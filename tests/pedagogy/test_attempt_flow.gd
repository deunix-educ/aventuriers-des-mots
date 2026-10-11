extends GutTest
## Tests de AttemptFlow : aide graduee sur 3 tentatives, sortie sans blocage.


func test_first_error_gives_a_hint() -> void:
    assert_eq(AttemptFlow.support_level_for_attempt(1), AttemptFlow.SupportLevel.HINT)


func test_second_error_gives_an_explanation() -> void:
    assert_eq(AttemptFlow.support_level_for_attempt(2), AttemptFlow.SupportLevel.EXPLANATION)


func test_third_error_reveals_the_answer() -> void:
    assert_eq(AttemptFlow.support_level_for_attempt(3), AttemptFlow.SupportLevel.REVEAL)


func test_exercise_ends_at_max_attempts() -> void:
    assert_false(AttemptFlow.should_end_exercise(2))
    assert_true(AttemptFlow.should_end_exercise(3))
