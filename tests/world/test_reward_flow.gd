extends GutTest
## Fin de mission de bout en bout cote interface : l'ecran de recompense
## enregistre le score, debloque des objets et la collection les affiche. Le
## changement de scene final n'est jamais declenche ici (voir point 14 de
## docs/specs/decisions.md).

var _profile_id: String = ""


func before_each() -> void:
    _profile_id = ProfileManager.create_profile("Test", "CE1")
    ProfileManager.select_profile(_profile_id)
    GameManager.pending_mission_id = "mission_01_pre_des_mots"


func after_each() -> void:
    ProfileManager.delete_profile(_profile_id)
    GameManager.pending_mission_id = ""
    GameManager.last_outcomes = []


func _open_reward_screen(outcomes: Array[String]) -> Control:
    GameManager.last_outcomes = outcomes
    var screen: Control = load("res://scenes/ui/reward_screen.tscn").instantiate()
    add_child_autofree(screen)
    return screen


func test_perfect_mission_gives_three_stars_and_the_trophy() -> void:
    var screen := _open_reward_screen(
        [
            MissionScoring.OUTCOME_FIRST_TRY,
            MissionScoring.OUTCOME_FIRST_TRY,
            MissionScoring.OUTCOME_FIRST_TRY,
        ]
    )
    await wait_process_frames(1)

    assert_string_contains(screen.get_node("%StarsLabel").text, "3/3")
    assert_eq(ProgressManager.mission_best_stars("mission_01_pre_des_mots"), 3)
    assert_eq(ProgressManager.stars(), 3)
    assert_true(ProgressManager.owned_items().has("item_graine_magique"))
    assert_true(ProgressManager.owned_items().has("item_trophee_pre"))
    assert_true(screen.get_node("%NewItemsLabel").visible)
    assert_false(screen.get_node("%RecordLabel").visible, "premiere fois : pas de record")


func test_revealed_answer_still_rewards_one_star_without_blame() -> void:
    var screen := _open_reward_screen(
        [
            MissionScoring.OUTCOME_REVEALED,
            MissionScoring.OUTCOME_FIRST_TRY,
            MissionScoring.OUTCOME_WITH_HELP,
        ]
    )
    await wait_process_frames(1)

    assert_string_contains(screen.get_node("%StarsLabel").text, "1/3")
    assert_eq(ProgressManager.stars(), 1)
    assert_eq(screen.get_node("%MessageLabel").text, UIText.get_text("reward_screen.message_1"))


func test_replaying_with_a_better_score_shows_a_record() -> void:
    var screen_one := _open_reward_screen([MissionScoring.OUTCOME_REVEALED])
    await wait_process_frames(1)
    screen_one.queue_free()

    var screen_two := _open_reward_screen([MissionScoring.OUTCOME_FIRST_TRY])
    await wait_process_frames(1)

    assert_true(screen_two.get_node("%RecordLabel").visible)
    assert_eq(ProgressManager.stars(), 3)


func test_collection_lists_owned_and_mysterious_items() -> void:
    var perfect: Array[String] = [MissionScoring.OUTCOME_FIRST_TRY]
    _open_reward_screen(perfect)
    await wait_process_frames(1)

    var collection: Control = load("res://scenes/ui/collection.tscn").instantiate()
    add_child_autofree(collection)
    await wait_process_frames(1)

    var rows := collection.get_node("%ItemsBox").get_children()
    assert_eq(rows.size(), ExerciseEngine.get_reward_items().size())
    assert_string_contains(
        (rows[0].find_child("TextLabel", true, false) as Label).text, "Graine magique"
    )
    assert_string_contains(
        (rows[1].find_child("TextLabel", true, false) as Label).text,
        UIText.get_text("collection.locked_title")
    )
