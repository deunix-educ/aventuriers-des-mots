extends GutTest
## La carte n'affiche que les missions du niveau du profil ; un profil CE2 peut
## basculer sur la carte CE1 pour revoir les notions precedentes (point 27 de
## docs/specs/decisions.md).

var _profile_id: String = ""


func after_each() -> void:
    ProfileManager.delete_profile(_profile_id)


func _open_map_for(level: String) -> Control:
    _profile_id = ProfileManager.create_profile("Test", level)
    ProfileManager.select_profile(_profile_id)
    var map: Control = load("res://scenes/world/world_map.tscn").instantiate()
    add_child_autofree(map)
    return map


func test_ce1_profile_sees_only_ce1_missions_and_no_toggle() -> void:
    var map := _open_map_for("CE1")
    await wait_process_frames(1)

    assert_eq(map.get_node("%MapArea").get_child_count(), 9)
    assert_false(map.get_node("%LevelToggleButton").visible)
    GameManager.map_region_id = ""


func test_ce2_profile_sees_ce2_missions_and_can_review_ce1() -> void:
    var map := _open_map_for("CE2")
    await wait_process_frames(1)

    assert_eq(map.get_node("%MapArea").get_child_count(), 12)
    assert_eq(map.get_node("%TitleLabel").text, "Le marais des homophones")
    var toggle: Button = map.get_node("%LevelToggleButton")
    assert_true(toggle.visible)

    toggle.pressed.emit()
    await wait_process_frames(1)
    assert_eq(map.get_node("%MapArea").get_child_count(), 9)
    assert_eq(map.get_node("%TitleLabel").text, "La forêt des accords")
    assert_eq(toggle.text, "Retour au CE2")

    toggle.pressed.emit()
    await wait_process_frames(1)
    assert_eq(map.get_node("%MapArea").get_child_count(), 12)


func test_ce1_profile_can_move_between_its_regions() -> void:
    var map := _open_map_for("CE1")
    await wait_process_frames(1)
    assert_eq(map.get_node("%TitleLabel").text, "La forêt des accords")
    var button: Button = map.get_node("%RegionButton")
    assert_true(button.visible)
    assert_eq(map.get_node("%MapArea").get_child_count(), 9)

    button.pressed.emit()
    await wait_process_frames(1)
    assert_eq(map.get_node("%TitleLabel").text, "La plage des sons")
    assert_eq(map.get_node("%MapArea").get_child_count(), 9)

    button.pressed.emit()
    await wait_process_frames(1)
    assert_eq(map.get_node("%TitleLabel").text, "La montagne des verbes")

    button.pressed.emit()
    await wait_process_frames(1)
    assert_eq(map.get_node("%TitleLabel").text, "La forêt des accords")
    GameManager.map_region_id = ""


func test_map_offers_a_way_back_to_the_profile_selection() -> void:
    var map := _open_map_for("CE1")
    await wait_process_frames(1)

    var button: Button = map.get_node("%ProfileButton")
    assert_true(button.visible)
    assert_eq(button.text, UIText.get_text("world_map.change_profile_button"))
