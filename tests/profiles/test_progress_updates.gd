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


func test_first_mission_result_adds_its_stars_to_the_total() -> void:
    var data := ProgressUpdates.record_mission_result(_base_save(), "mission_a", 2)
    assert_eq(data["rewards"]["stars"], 2)
    assert_eq(
        data["mission_results"]["mission_a"], {"best_stars": 2, "last_stars": 2, "completions": 1}
    )


func test_replaying_a_mission_only_adds_the_improvement() -> void:
    var data := ProgressUpdates.record_mission_result(_base_save(), "mission_a", 1)
    data = ProgressUpdates.record_mission_result(data, "mission_a", 3)
    assert_eq(data["rewards"]["stars"], 3, "1 puis 3 etoiles : 3 au total, pas 4")
    assert_eq(data["mission_results"]["mission_a"]["best_stars"], 3)
    assert_eq(data["mission_results"]["mission_a"]["completions"], 2)


func test_a_worse_replay_never_lowers_the_best_score() -> void:
    var data := ProgressUpdates.record_mission_result(_base_save(), "mission_a", 3)
    data = ProgressUpdates.record_mission_result(data, "mission_a", 1)
    assert_eq(data["rewards"]["stars"], 3)
    assert_eq(data["mission_results"]["mission_a"]["best_stars"], 3)
    assert_eq(data["mission_results"]["mission_a"]["last_stars"], 1)


func test_stars_of_different_missions_add_up() -> void:
    var data := ProgressUpdates.record_mission_result(_base_save(), "mission_a", 2)
    data = ProgressUpdates.record_mission_result(data, "mission_b", 3)
    assert_eq(data["rewards"]["stars"], 5)


func test_grant_items_never_duplicates() -> void:
    var ids: Array[String] = ["item_a", "item_b"]
    var data := ProgressUpdates.grant_items(_base_save(), ids)
    data = ProgressUpdates.grant_items(data, ids)
    assert_eq(data["rewards"]["items"], ["item_a", "item_b"])


func test_record_mission_result_validates_against_the_save_schema() -> void:
    var data := ProgressUpdates.record_mission_result(_base_save(), "mission_a", 2)
    var errors := SchemaValidator.validate(data, DataLoader.load_schema("save"))
    assert_eq(errors, [])


func test_next_difficulty_works_on_a_save_reloaded_from_disk() -> void:
    # Regression : relu depuis le JSON, "recent_results" est un Array non type
    # (et les entiers deviennent des flottants). L'affecter a un Array[bool]
    # faisait echouer le choix de l'exercice suivant apres un redemarrage.
    var save := SaveFactory.new_save("test_disk_reload", "Lea", "CE2")
    save["skills"] = {
        "homophones_grammaticaux":
        {
            "status": "en_consolidation",
            "recent_results": [true, true, true, true, true, true, true, true],
            "recent_hint_used": [false, false, false, false, false, false, false, false],
            "sessions_succeeded": [1, 3],
            "formats_succeeded": ["dictation"],
            "last_session_practiced": 3,
            "review_interval_index": -1,
            "next_review_session": 4,
        }
    }
    var reloaded: Dictionary = JSON.parse_string(JSON.stringify(save))
    var difficulty := ProgressUpdates.next_difficulty_for_skill(
        reloaded, "homophones_grammaticaux", 1
    )
    assert_eq(difficulty, 2, "huit reussites de suite : la difficulte monte")
