extends GutTest
## Quitter une mission en cours : confirmation demandee, aucune etoile ni
## aucun objet, jamais compte comme un echec. Le changement de scene n'est
## pas observe ici (voir point 14 de docs/specs/decisions.md).

var _profile_id: String = ""


func before_each() -> void:
    _profile_id = ProfileManager.create_profile("Test", "CE1")
    ProfileManager.select_profile(_profile_id)
    GameManager.pending_mission_id = "mission_01_pre_des_mots"


func after_each() -> void:
    ProfileManager.delete_profile(_profile_id)
    GameManager.pending_mission_id = ""
    GameManager.last_outcomes = []


func _open_host() -> Control:
    var host: Control = load("res://scenes/exercises/exercise_host.tscn").instantiate()
    add_child_autofree(host)
    await wait_process_frames(1)
    return host


func test_abandon_asks_for_confirmation_before_leaving() -> void:
    var host: Control = await _open_host()

    var dialog: ConfirmationDialog = host.get_node("%AbandonConfirmDialog")
    assert_false(dialog.visible)
    assert_eq((host.get_node("%AbandonButton") as Button).text, "Quitter la mission")

    host.get_node("%AbandonButton").pressed.emit()
    await wait_process_frames(1)

    assert_true(dialog.visible, "la confirmation doit s'afficher avant de quitter")
    assert_eq(GameManager.pending_mission_id, "mission_01_pre_des_mots", "pas encore parti")


func test_confirmed_abandon_gives_no_stars_and_clears_the_mission() -> void:
    var host: Control = await _open_host()

    host.get_node("%AbandonConfirmDialog").confirmed.emit()

    assert_eq(GameManager.pending_mission_id, "")
    assert_eq(ProgressManager.stars(), 0)
    assert_eq(ProgressManager.mission_best_stars("mission_01_pre_des_mots"), 0)
    assert_eq(ProgressManager.owned_items(), [])
