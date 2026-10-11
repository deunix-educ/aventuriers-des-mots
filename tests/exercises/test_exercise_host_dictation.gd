extends GutTest
## Reproduction de deux retours de test manuel via exercise_host, sur la
## dictee "Les petits chats dorment." (voir docs/specs/decisions.md, points
## 21 et 22) : la reponse exacte doit valider, et la majuscule/le point final
## restent exiges (conventions generales d'ecriture, pas une tolerance).

var _profile_id: String = ""


func before_each() -> void:
    _profile_id = ProfileManager.create_profile("Test", "CE1")
    ProfileManager.select_profile(_profile_id)
    GameManager.pending_mission_id = "mission_03_clairiere_echo"


func after_each() -> void:
    ProfileManager.delete_profile(_profile_id)
    GameManager.pending_mission_id = ""


func test_exact_target_text_is_validated_as_correct() -> void:
    var host: Control = await _ready_host()
    var exercise_scene: Control = host.get_node("%ExerciseContainer").get_child(0)
    var exercise: Dictionary = host.get_current_exercise()
    assert_eq(exercise["target_text"], "Les petits chats dorment.")

    (exercise_scene.get_node("%TextEdit") as LineEdit).text = exercise["target_text"]
    exercise_scene.get_node("%ValidateButton").pressed.emit()
    await wait_process_frames(1)

    assert_eq(_feedback_title(host), UIText.get_text("feedback_panel.correct_title"))


func test_missing_final_period_is_not_validated_as_correct() -> void:
    var host: Control = await _ready_host()
    var exercise_scene: Control = host.get_node("%ExerciseContainer").get_child(0)

    (exercise_scene.get_node("%TextEdit") as LineEdit).text = "Les petits chats dorment"
    exercise_scene.get_node("%ValidateButton").pressed.emit()
    await wait_process_frames(1)

    assert_eq(_feedback_title(host), UIText.get_text("feedback_panel.incorrect_title"))


func _ready_host() -> Control:
    var host: Control = load("res://scenes/exercises/exercise_host.tscn").instantiate()
    add_child_autofree(host)
    await wait_process_frames(1)

    var overlay: Control = host.get_node("%OverlayContainer")
    overlay.get_child(0).continued.emit()
    await wait_process_frames(1)
    return host


func _feedback_title(host: Control) -> String:
    var overlay: Control = host.get_node("%OverlayContainer")
    var feedback: Control = overlay.get_child(overlay.get_child_count() - 1)
    var title_label: Label = feedback.get_node("%TitleLabel")
    return title_label.text
