extends GutTest
## Tests de ProgressUpdates : application pure des tentatives et des debuts de
## seance a une sauvegarde.


func _base_save() -> Dictionary:
    return SaveFactory.new_save("profile_test", "Explorateur", "CE1")


func test_record_attempt_creates_skill_state_on_first_attempt() -> void:
    var data := _base_save()
    var attempt := {
        "skill": "accord_groupe_nominal",
        "success": true,
        "hint_used": false,
        "exercise_type": "multiple_choice",
    }
    var updated := ProgressUpdates.record_attempt(data, attempt)
    assert_true(updated["skills"].has("accord_groupe_nominal"))
    assert_eq(
        updated["skills"]["accord_groupe_nominal"]["status"], ReviewScheduler.STATUS_EN_ACQUISITION
    )


func test_record_attempt_uses_current_session_count() -> void:
    var data := _base_save()
    data["session_count"] = 5
    var attempt := {
        "skill": "accord_groupe_nominal",
        "success": true,
        "hint_used": false,
        "exercise_type": "multiple_choice",
    }
    var updated := ProgressUpdates.record_attempt(data, attempt)
    var skill_state: Dictionary = updated["skills"]["accord_groupe_nominal"]
    assert_eq(skill_state["last_session_practiced"], 5)


func test_record_attempt_does_not_mutate_input() -> void:
    var data := _base_save()
    var attempt := {
        "skill": "accord_groupe_nominal",
        "success": true,
        "hint_used": false,
        "exercise_type": "multiple_choice",
    }
    ProgressUpdates.record_attempt(data, attempt)
    assert_eq(data["skills"], {})


func test_start_session_increments_session_count() -> void:
    var data := _base_save()
    var updated := ProgressUpdates.start_session(data)
    assert_eq(updated["session_count"], 1)
    updated = ProgressUpdates.start_session(updated)
    assert_eq(updated["session_count"], 2)


func test_start_session_marks_overdue_skills_as_a_reviser() -> void:
    var data := _base_save()
    var acquise_state: Dictionary = ReviewScheduler.initial_state()
    acquise_state["status"] = ReviewScheduler.STATUS_ACQUISE
    acquise_state["next_review_session"] = 2
    data["skills"] = {"accord_groupe_nominal": acquise_state}
    data["session_count"] = 1

    var updated := ProgressUpdates.start_session(data)
    assert_eq(updated["session_count"], 2)
    assert_eq(
        updated["skills"]["accord_groupe_nominal"]["status"], ReviewScheduler.STATUS_A_REVISER
    )


func test_unlock_region_adds_region_once() -> void:
    var data := _base_save()
    data = ProgressUpdates.unlock_region(data, "foret_des_accords")
    data = ProgressUpdates.unlock_region(data, "foret_des_accords")
    assert_eq(data["unlocked_regions"], ["foret_des_accords"])


func test_next_difficulty_for_unknown_skill_returns_current_difficulty() -> void:
    var data := _base_save()
    assert_eq(ProgressUpdates.next_difficulty_for_skill(data, "inconnue", 2), 2)
