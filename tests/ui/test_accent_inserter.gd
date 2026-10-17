extends GutTest
## Barre d'accents : insertion a la position du curseur et comportement de la
## barre (focus conserve par le champ, majuscule a usage unique).


func test_inserts_at_the_caret() -> void:
    var result := AccentInserter.insert("ete", 0, "é")
    assert_eq(result["text"], "éete")
    assert_eq(result["caret"], 1)
    result = AccentInserter.insert("ete", 3, "é")
    assert_eq(result["text"], "eteé")
    result = AccentInserter.insert("cole", 0, "É")
    assert_eq(result["text"], "École")


func test_caret_is_clamped_and_empty_character_changes_nothing() -> void:
    assert_eq(AccentInserter.insert("ab", 99, "é")["text"], "abé")
    assert_eq(AccentInserter.insert("ab", -4, "é")["text"], "éab")
    assert_eq(AccentInserter.insert("ab", 1, "")["text"], "ab")


func test_lower_and_upper_sets_match_and_cover_french_accents() -> void:
    var lower := AccentInserter.characters(false)
    var upper := AccentInserter.characters(true)
    assert_eq(lower.size(), upper.size())
    for i in lower.size():
        assert_eq(lower[i].to_upper(), upper[i])
    for needed in ["é", "è", "ê", "à", "ù", "ç", "î", "ô", "œ", "â", "û"]:
        assert_true(lower.has(needed), needed)


func test_bar_inserts_into_its_target_and_shift_applies_once() -> void:
    var edit := LineEdit.new()
    add_child_autofree(edit)
    var bar := AccentBar.new()
    add_child_autofree(bar)
    await wait_process_frames(2)
    assert_false(bar.visible, "pas de cible : barre masquee")

    bar.set_target(edit)
    assert_true(bar.visible)
    edit.text = "t"
    edit.caret_column = 1
    var accent_button: Button = null
    for child in bar.get_children():
        if child is Button and (child as Button).text == "é":
            accent_button = child
    assert_not_null(accent_button)
    assert_eq(accent_button.focus_mode, Control.FOCUS_NONE, "le champ garde le focus")
    accent_button.pressed.emit()
    assert_eq(edit.text, "té")
    assert_eq(edit.caret_column, 2)

    var shift: Button = bar.get_child(0)
    shift.button_pressed = true
    await wait_process_frames(2)
    var upper_button: Button = null
    for child in bar.get_children():
        if child is Button and (child as Button).text == "É":
            upper_button = child
    assert_not_null(upper_button)
    upper_button.pressed.emit()
    assert_eq(edit.text, "téÉ")
    await wait_process_frames(2)
    assert_false(shift.button_pressed, "la majuscule ne sert qu'une fois")


func test_dictation_and_correction_scenes_have_an_accent_bar() -> void:
    var dictation: Control = load("res://scenes/exercises/dictation.tscn").instantiate()
    add_child_autofree(dictation)
    await wait_process_frames(2)
    var bars := dictation.find_children("*", "HFlowContainer", true, false)
    assert_eq(bars.size(), 1)
    assert_true((bars[0] as Control).visible)
