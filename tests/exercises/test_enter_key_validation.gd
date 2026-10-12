extends GutTest
## La touche Entree valide une saisie comme le bouton « Valider ».


func test_enter_in_the_correction_field_submits_the_answer() -> void:
    var scene: Control = load("res://scenes/exercises/sentence_correction.tscn").instantiate()
    add_child_autofree(scene)
    await wait_process_frames(1)
    var exercise: Dictionary = DataLoader.read_json(
        "res://data/exercises/ce1/ce1_accord_adjectif_correction_01.json"
    )
    scene.load_exercise(exercise)
    await wait_process_frames(1)

    (scene.get_node("%TokensBox").get_child(1) as Button).toggled.emit(true)
    await wait_process_frames(1)
    var edit: LineEdit = scene.get_node("%CorrectionsBox").get_child(0)
    edit.text = "petits"

    watch_signals(scene)
    edit.text_submitted.emit(edit.text)
    assert_signal_emitted_with_parameters(scene, "answer_submitted", [[1], {1: "petits"}])


func test_enter_in_the_dictation_field_submits_the_text() -> void:
    var scene: Control = load("res://scenes/exercises/dictation.tscn").instantiate()
    add_child_autofree(scene)
    await wait_process_frames(1)
    var edit: LineEdit = scene.get_node("%TextEdit")
    edit.text = "La fleur est belle."

    watch_signals(scene)
    edit.text_submitted.emit(edit.text)
    assert_signal_emitted_with_parameters(scene, "answer_submitted", ["La fleur est belle."])
