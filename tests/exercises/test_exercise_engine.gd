extends GutTest
## Tests de l'autoload ExerciseEngine, charge au demarrage avec les vraies
## donnees de data/ (deja validees par make validate-data).


func test_known_rule_is_loaded() -> void:
    var rule := ExerciseEngine.get_rule("regle_accord_adjectif")
    assert_eq(rule["level"], "CE1")
    assert_eq(rule["review_status"], "draft")


func test_unknown_rule_returns_empty_dictionary() -> void:
    assert_eq(ExerciseEngine.get_rule("regle_inconnue"), {})


func test_missions_are_loaded_and_sorted() -> void:
    var missions := ExerciseEngine.get_missions()
    assert_eq(missions.size(), 21)
    var ids: Array = missions.map(func(m: Dictionary) -> String: return m["mission_id"])
    assert_eq(ids, ids.duplicate())  # trivialement vrai, documente l'ordre stable
    assert_true(ids.has("mission_01_pre_des_mots"))
    assert_true(ids.has("mission_09_rocher_qui_repete"))
    assert_true(ids.has("mission_21_colline_echos"))


func test_missions_are_filtered_by_the_level_of_their_rule() -> void:
    assert_eq(ExerciseEngine.get_missions_for_level("CE1").size(), 9)
    assert_eq(ExerciseEngine.get_missions_for_level("CE2").size(), 12)
    assert_eq(ExerciseEngine.get_missions_for_level("CM1").size(), 0)


func test_get_mission_returns_the_requested_mission() -> void:
    var mission := ExerciseEngine.get_mission("mission_02_pont_des_phrases")
    assert_eq(mission["exercise_type"], "sentence_correction")
    assert_eq(mission["rule_id"], "regle_accord_adjectif")


func test_pick_exercise_for_multiple_choice_mission() -> void:
    var mission := ExerciseEngine.get_mission("mission_01_pre_des_mots")
    var exercise := ExerciseEngine.pick_exercise_for_mission(mission, "", 1)
    assert_eq(exercise["type"], "multiple_choice")
    assert_eq(exercise["rule_id"], "regle_accord_adjectif")


func test_pick_exercise_for_dictation_mission() -> void:
    var mission := ExerciseEngine.get_mission("mission_03_clairiere_echo")
    var exercise := ExerciseEngine.pick_exercise_for_mission(mission, "", 1)
    assert_true(exercise.has("target_text"))
    assert_true(exercise.has("words"))


func test_pick_exercise_never_repeats_the_excluded_id_when_alternatives_exist() -> void:
    var mission := ExerciseEngine.get_mission("mission_01_pre_des_mots")
    var first := ExerciseEngine.pick_exercise_for_mission(mission, "", 1)
    for _i in 10:
        var picked := ExerciseEngine.pick_exercise_for_mission(mission, first["id"], 1)
        assert_ne(picked["id"], first["id"])


func test_pick_exercise_falls_back_to_any_difficulty_when_none_match() -> void:
    var mission := ExerciseEngine.get_mission("mission_01_pre_des_mots")
    var exercise := ExerciseEngine.pick_exercise_for_mission(mission, "", 3)
    assert_eq(exercise["type"], "multiple_choice")
