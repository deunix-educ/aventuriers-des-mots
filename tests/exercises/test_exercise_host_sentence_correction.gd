extends GutTest
## Reproduction d'un bug signale manuellement via exercise_host (pas
## seulement la scene isolee) : toucher "petit" puis taper "petits" sur
## la mission "Le pont des phrases".

var _profile_id: String = ""


func before_each() -> void:
    _profile_id = ProfileManager.create_profile("Test", "CE1")
    ProfileManager.select_profile(_profile_id)
    GameManager.pending_mission_id = "mission_02_pont_des_phrases"


func after_each() -> void:
    ProfileManager.delete_profile(_profile_id)
    GameManager.pending_mission_id = ""


func test_correct_word_tap_and_retype_validates_through_exercise_host() -> void:
    var host: Control = load("res://scenes/exercises/exercise_host.tscn").instantiate()
    add_child_autofree(host)
    await wait_process_frames(1)

    var overlay: Control = host.get_node("%OverlayContainer")
    overlay.get_child(0).continued.emit()
    await wait_process_frames(1)

    var exercise_scene: Control = host.get_node("%ExerciseContainer").get_child(0)
    var exercise: Dictionary = host.get_current_exercise()
    assert_eq(exercise["type"], "sentence_correction")

    var faulty_index := -1
    for i in (exercise["tokens"] as Array).size():
        if (exercise["tokens"][i] as Dictionary).get("correct", true) == false:
            faulty_index = i
    assert_ne(faulty_index, -1, "l'exercice doit avoir un mot fautif")
    var expected: String = exercise["tokens"][faulty_index]["expected"]

    var tokens_box: Control = exercise_scene.get_node("%TokensBox")
    var faulty_button: Button = tokens_box.get_child(faulty_index)
    faulty_button.toggled.emit(true)
    await wait_process_frames(1)

    var corrections_box: Control = exercise_scene.get_node("%CorrectionsBox")
    assert_eq(corrections_box.get_child_count(), 1)
    var edit: LineEdit = corrections_box.get_child(0)
    edit.text = expected

    exercise_scene.get_node("%ValidateButton").pressed.emit()
    await wait_process_frames(1)

    # Le panneau de retour doit annoncer une reussite ("Bravo !"), pas une
    # erreur, et la tentative doit etre enregistree comme reussie.
    var feedback: Control = overlay.get_child(overlay.get_child_count() - 1)
    var title_label: Label = feedback.get_node("%TitleLabel")
    assert_eq(title_label.text, UIText.get_text("feedback_panel.correct_title"))

    var skill_state := ProgressManager.get_skill_state("accord_groupe_nominal")
    assert_eq(skill_state["recent_results"], [true])
