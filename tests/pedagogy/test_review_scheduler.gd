extends GutTest
## Tests de ReviewScheduler : transitions de maitrise (cahier des charges §9)
## et planification des revisions en seances (pas en dates calendaires).


func _attempt(
    success: bool, hint_used: bool = false, exercise_type: String = "multiple_choice"
) -> Dictionary:
    return {"success": success, "hint_used": hint_used, "exercise_type": exercise_type}


func test_initial_state_is_decouverte() -> void:
    assert_eq(ReviewScheduler.initial_state()["status"], ReviewScheduler.STATUS_DECOUVERTE)


func test_first_success_moves_to_en_acquisition() -> void:
    var state := ReviewScheduler.record_attempt(ReviewScheduler.initial_state(), _attempt(true), 1)
    assert_eq(state["status"], ReviewScheduler.STATUS_EN_ACQUISITION)


func test_first_failure_stays_at_decouverte() -> void:
    var state := ReviewScheduler.record_attempt(ReviewScheduler.initial_state(), _attempt(false), 1)
    assert_eq(state["status"], ReviewScheduler.STATUS_DECOUVERTE)


func test_two_hintless_successes_reach_en_consolidation() -> void:
    var state := ReviewScheduler.initial_state()
    state = ReviewScheduler.record_attempt(state, _attempt(true), 1)
    state = ReviewScheduler.record_attempt(state, _attempt(true), 1)
    assert_eq(state["status"], ReviewScheduler.STATUS_EN_CONSOLIDATION)


func test_successes_with_hints_do_not_reach_en_consolidation() -> void:
    var state := ReviewScheduler.initial_state()
    state = ReviewScheduler.record_attempt(state, _attempt(true, true), 1)
    state = ReviewScheduler.record_attempt(state, _attempt(true, true), 1)
    assert_eq(state["status"], ReviewScheduler.STATUS_EN_ACQUISITION)


func test_full_path_to_acquise_requires_sessions_and_formats() -> void:
    var state := ReviewScheduler.initial_state()
    var sessions := [1, 1, 2, 2, 3, 3, 4, 4]
    var types := ["multiple_choice", "sentence_correction"]
    for i in 8:
        state = ReviewScheduler.record_attempt(
            state, _attempt(true, false, types[i % 2]), sessions[i]
        )
    assert_eq(state["status"], ReviewScheduler.STATUS_ACQUISE)
    assert_eq(state["review_interval_index"], 0)
    assert_eq(state["next_review_session"], 4 + ReviewScheduler.REVIEW_INTERVALS_SESSIONS[0])


func test_acquise_requires_at_least_three_distinct_sessions() -> void:
    var state := ReviewScheduler.initial_state()
    var types := ["multiple_choice", "sentence_correction"]
    # 8 succes mais seulement 2 seances distinctes : ne doit pas atteindre "acquise".
    for i in 8:
        state = ReviewScheduler.record_attempt(
            state, _attempt(true, false, types[i % 2]), 1 if i < 4 else 2
        )
    assert_ne(state["status"], ReviewScheduler.STATUS_ACQUISE)


func test_acquise_requires_at_least_two_distinct_formats() -> void:
    var state := ReviewScheduler.initial_state()
    var sessions := [1, 1, 2, 2, 3, 3, 4, 4]
    for i in 8:
        state = ReviewScheduler.record_attempt(state, _attempt(true), sessions[i])
    assert_ne(state["status"], ReviewScheduler.STATUS_ACQUISE)


func _make_acquise_state(interval_index: int, next_review_session: int) -> Dictionary:
    var state := ReviewScheduler.initial_state()
    state["status"] = ReviewScheduler.STATUS_ACQUISE
    state["recent_results"] = [true, true, true, true, true, true, true, true]
    state["recent_hint_used"] = [false, false, false, false, false, false, false, false]
    state["sessions_succeeded"] = [1, 2, 3]
    state["formats_succeeded"] = ["multiple_choice", "sentence_correction"]
    state["review_interval_index"] = interval_index
    state["next_review_session"] = next_review_session
    return state


func test_failure_on_acquise_skill_moves_to_a_reviser() -> void:
    var state := _make_acquise_state(0, 99)
    state = ReviewScheduler.record_attempt(state, _attempt(false), 5)
    assert_eq(state["status"], ReviewScheduler.STATUS_A_REVISER)
    assert_eq(state["next_review_session"], -1)


func test_success_on_a_reviser_skill_returns_to_acquise_at_first_interval() -> void:
    var state := _make_acquise_state(2, 99)
    state["status"] = ReviewScheduler.STATUS_A_REVISER
    state = ReviewScheduler.record_attempt(state, _attempt(true), 10)
    assert_eq(state["status"], ReviewScheduler.STATUS_ACQUISE)
    assert_eq(state["review_interval_index"], 0)
    assert_eq(state["next_review_session"], 10 + ReviewScheduler.REVIEW_INTERVALS_SESSIONS[0])


func test_successful_review_on_time_advances_to_next_interval() -> void:
    var state := _make_acquise_state(0, 5)
    assert_true(ReviewScheduler.is_due_for_review(state, 5))
    state = ReviewScheduler.record_attempt(state, _attempt(true), 5)
    assert_eq(state["status"], ReviewScheduler.STATUS_ACQUISE)
    assert_eq(state["review_interval_index"], 1)
    assert_eq(state["next_review_session"], 5 + ReviewScheduler.REVIEW_INTERVALS_SESSIONS[1])


func test_success_before_due_date_does_not_advance_interval() -> void:
    var state := _make_acquise_state(0, 10)
    assert_false(ReviewScheduler.is_due_for_review(state, 5))
    state = ReviewScheduler.record_attempt(state, _attempt(true), 5)
    assert_eq(state["review_interval_index"], 0)
    assert_eq(state["next_review_session"], 10)


func test_review_interval_never_exceeds_last_step() -> void:
    var last_index := ReviewScheduler.REVIEW_INTERVALS_SESSIONS.size() - 1
    var state := _make_acquise_state(last_index, 5)
    state = ReviewScheduler.record_attempt(state, _attempt(true), 5)
    assert_eq(state["review_interval_index"], last_index)


func test_mark_overdue_as_review_transitions_without_new_attempt() -> void:
    var state := _make_acquise_state(0, 5)
    var updated := ReviewScheduler.mark_overdue_as_review(state, 6)
    assert_eq(updated["status"], ReviewScheduler.STATUS_A_REVISER)


func test_mark_overdue_as_review_does_nothing_before_due_date() -> void:
    var state := _make_acquise_state(0, 5)
    var updated := ReviewScheduler.mark_overdue_as_review(state, 3)
    assert_eq(updated["status"], ReviewScheduler.STATUS_ACQUISE)
