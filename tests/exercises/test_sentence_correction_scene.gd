extends GutTest
## Reproduction d'un bug signale manuellement : taper la correction attendue
## ("petits") sur le mot fautif ("petit") de
## ce1_accord_adjectif_correction_01 n'etait pas reconnu comme juste.


func test_tapping_the_faulty_word_and_typing_its_correction_validates() -> void:
    var scene: Control = load("res://scenes/exercises/sentence_correction.tscn").instantiate()
    add_child_autofree(scene)
    await wait_process_frames(1)

    var exercise: Dictionary = DataLoader.read_json(
        "res://data/exercises/ce1/ce1_accord_adjectif_correction_01.json"
    )
    scene.load_exercise(exercise)
    await wait_process_frames(1)

    var tokens_box: Control = scene.get_node("%TokensBox")
    assert_eq(tokens_box.get_child_count(), 4)
    var faulty_button: Button = tokens_box.get_child(1)
    assert_eq(faulty_button.text, "petit")

    faulty_button.toggled.emit(true)
    await wait_process_frames(1)

    var corrections_box: Control = scene.get_node("%CorrectionsBox")
    assert_eq(corrections_box.get_child_count(), 1, "un champ de correction doit apparaitre")
    var edit: LineEdit = corrections_box.get_child(0)
    edit.text = "petits"

    watch_signals(scene)
    scene.get_node("%ValidateButton").pressed.emit()
    await wait_process_frames(1)

    assert_signal_emitted_with_parameters(scene, "answer_submitted", [[1], {1: "petits"}])

    var result := AnswerValidator.validate_sentence_correction(exercise, [1], {1: "petits"})
    assert_true(result.is_correct, "'petits' doit etre accepte comme correction de 'petit'")
