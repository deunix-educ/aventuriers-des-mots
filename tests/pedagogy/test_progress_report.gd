extends GutTest
## Tests de ProgressReport : synthese pour l'adulte et detection des notions a
## retravailler.


func _save_with_skill(state: Dictionary) -> Dictionary:
    var save := SaveFactory.new_save("test_report", "Lea", "CE1")
    save["skills"] = {"accord_groupe_nominal": state}
    return save


func _state(status: String, results: Array, hints: Array) -> Dictionary:
    return {
        "status": status,
        "recent_results": results,
        "recent_hint_used": hints,
        "sessions_succeeded": [],
        "formats_succeeded": [],
        "last_session_practiced": 0,
        "review_interval_index": 0,
        "next_review_session": 0,
    }


func test_empty_profile_has_no_skills_and_zero_counts() -> void:
    var report := ProgressReport.build(SaveFactory.new_save("test_report", "Lea", "CE1"), 9, 10)
    assert_eq(report["stars"], 0)
    assert_eq(report["missions_done"], 0)
    assert_eq(report["missions_total"], 9)
    assert_eq(report["items_total"], 10)
    assert_eq(report["skills"].size(), 0)


func test_counts_missions_stars_and_items() -> void:
    var save := SaveFactory.new_save("test_report", "Lea", "CE1")
    save["mission_results"] = {"m1": {"best_stars": 3, "last_stars": 3, "completions": 1}}
    save["rewards"] = {"stars": 3, "items": ["a", "b"]}
    var report := ProgressReport.build(save, 9, 10)
    assert_eq(report["missions_done"], 1)
    assert_eq(report["stars"], 3)
    assert_eq(report["items_owned"], 2)


func test_skill_with_low_recent_success_needs_work() -> void:
    var save := _save_with_skill(
        _state("en_acquisition", [false, false, true, false], [true, false, false, false])
    )
    var row: Dictionary = ProgressReport.build(save, 9, 10)["skills"][0]
    assert_eq(row["attempts"], 4)
    assert_eq(row["successes"], 1)
    assert_eq(row["hints_used"], 1)
    assert_true(row["needs_work"])


func test_skill_with_good_results_does_not_need_work() -> void:
    var save := _save_with_skill(_state("en_consolidation", [true, true, false, true], []))
    var row: Dictionary = ProgressReport.build(save, 9, 10)["skills"][0]
    assert_false(row["needs_work"])


func test_too_few_attempts_is_not_a_difficulty() -> void:
    var save := _save_with_skill(_state("en_acquisition", [false, false], []))
    var row: Dictionary = ProgressReport.build(save, 9, 10)["skills"][0]
    assert_false(row["needs_work"])


func test_status_a_reviser_always_needs_work() -> void:
    var save := _save_with_skill(_state("a_reviser", [true], []))
    var row: Dictionary = ProgressReport.build(save, 9, 10)["skills"][0]
    assert_true(row["needs_work"])
