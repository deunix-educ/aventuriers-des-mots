extends GutTest
## Reproduction d'un bug signale manuellement via exercise_host : la dictee
## "Les petits chats dorment." tapee exactement comme entendue n'etait pas
## validee comme correcte.

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


## "J'entends parfaitement mais ne valide pas" : l'audio ne fait entendre
## aucune ponctuation, donc l'enfant qui ecrit exactement ce qu'il entend
## (sans le point final) doit tout de meme etre valide.
func test_missing_final_period_is_still_validated_as_correct() -> void:
    var host: Control = await _ready_host()
    var exercise_scene: Control = host.get_node("%ExerciseContainer").get_child(0)

    (exercise_scene.get_node("%TextEdit") as LineEdit).text = "Les petits chats dorment"
    exercise_scene.get_node("%ValidateButton").pressed.emit()
    await wait_process_frames(1)

    assert_eq(_feedback_title(host), UIText.get_text("feedback_panel.correct_title"))


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
