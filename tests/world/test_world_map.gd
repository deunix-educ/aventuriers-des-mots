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


func test_ce2_profile_sees_ce2_missions_and_can_review_ce1() -> void:
    var map := _open_map_for("CE2")
    await wait_process_frames(1)

    assert_eq(map.get_node("%MapArea").get_child_count(), 12)
    assert_eq(map.get_node("%TitleLabel").text, UIText.get_text("world_map.title_ce2"))
    var toggle: Button = map.get_node("%LevelToggleButton")
    assert_true(toggle.visible)

    toggle.pressed.emit()
    await wait_process_frames(1)
    assert_eq(map.get_node("%MapArea").get_child_count(), 9)
    assert_eq(map.get_node("%TitleLabel").text, UIText.get_text("world_map.title"))

    toggle.pressed.emit()
    await wait_process_frames(1)
    assert_eq(map.get_node("%MapArea").get_child_count(), 12)
