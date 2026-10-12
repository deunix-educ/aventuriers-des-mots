extends GutTest
## Parcours des scenes de reglages et d'espace adulte : navigation et barriere.
## Ne modifie jamais les reglages reels ni les profils de l'utilisateur.

const SETTINGS_SCENE := preload("res://scenes/ui/settings.tscn")
const ADULT_SCENE := preload("res://scenes/ui/adult_space.tscn")


func test_settings_scene_builds_one_button_per_text_size() -> void:
    var scene: Control = add_child_autofree(SETTINGS_SCENE.instantiate())
    var box: HBoxContainer = scene.find_child("TextSizeBox", true, false)
    assert_eq(box.get_child_count(), AppSettings.TEXT_SCALES.size())


func test_adult_space_hides_content_until_gate_is_solved() -> void:
    var scene: Control = add_child_autofree(ADULT_SCENE.instantiate())
    var gate: Control = scene.find_child("GateBox", true, false)
    var content: Control = scene.find_child("ContentBox", true, false)
    assert_true(gate.visible)
    assert_false(content.visible)

    var input: LineEdit = scene.find_child("GateInput", true, false)
    input.text = "0"
    scene._on_gate_submitted()
    assert_true(gate.visible, "une mauvaise reponse ne doit pas ouvrir l'espace")
    assert_false(content.visible)

    input.text = str(scene._challenge["answer"])
    scene._on_gate_submitted()
    assert_false(gate.visible)
    assert_true(content.visible)


func test_profile_deletion_belongs_to_the_adult_space() -> void:
    var profile_id := ProfileManager.create_profile("ASupprimer", "CE1")
    var other_id := ProfileManager.create_profile("AGarder", "CE1")

    # Choix de profil : aucun bouton « Supprimer » pour l'enfant.
    var select_scene: Control = add_child_autofree(
        load("res://scenes/profiles/profile_select.tscn").instantiate()
    )
    await wait_process_frames(1)
    for button in select_scene.find_children("*", "Button", true, false):
        assert_ne((button as Button).text, "Supprimer", "pas de suppression cote enfant")
    assert_null(select_scene.find_child("DeleteConfirmDialog", true, false))

    # Espace adulte : apres la barriere, suppression avec confirmation.
    var scene: Control = add_child_autofree(ADULT_SCENE.instantiate())
    scene.get_node("%GateInput").text = str(scene._challenge["answer"])
    scene._on_gate_submitted()
    await wait_process_frames(1)

    var option: OptionButton = scene.get_node("%ProfileOption")
    var target_index := -1
    for i in option.item_count:
        if option.get_item_metadata(i) == profile_id:
            target_index = i
    assert_ne(target_index, -1)
    option.select(target_index)
    scene._on_profile_option_selected(target_index)

    scene._on_delete_pressed()
    var dialog: ConfirmationDialog = scene.get_node("%DeleteDialog")
    assert_true(dialog.visible, "une confirmation doit etre demandee")
    assert_true(ProfileManager.list_profiles().has(profile_id), "rien n'est supprime avant")
    dialog.hide()

    scene._on_delete_confirmed()
    assert_false(ProfileManager.list_profiles().has(profile_id))
    assert_true(ProfileManager.list_profiles().has(other_id), "les autres profils sont intacts")

    ProfileManager.delete_profile(other_id)


func test_profile_creation_offers_only_levels_that_have_content() -> void:
    var scene: Control = add_child_autofree(
        load("res://scenes/profiles/profile_create.tscn").instantiate()
    )
    await wait_process_frames(1)
    var offered: Array[String] = []
    for button in scene.get_node("%LevelBox").get_children():
        offered.append(button.get_meta("level"))
    var expected: Array[String] = []
    for level in SchoolLevels.ALL:
        if not ExerciseEngine.get_regions_for_level(level).is_empty():
            expected.append(level)
    assert_eq(offered, expected)
    assert_true(offered.has("CE1") and offered.has("CE2"))


func test_quit_button_asks_for_confirmation_then_quits_through_the_hook() -> void:
    var quits: Array[int] = []
    GameManager.quit_hook = func() -> void: quits.append(1)
    for path in ["res://scenes/profiles/profile_select.tscn", "res://scenes/ui/settings.tscn"]:
        var scene: Control = add_child_autofree(load(path).instantiate())
        await wait_process_frames(1)
        var button: Button = scene.get_node("%QuitButton")
        var dialog: ConfirmationDialog = scene.get_node("%QuitDialog")
        assert_eq(button.text, UIText.get_text("quit.button"))
        var before_press := quits.size()
        button.pressed.emit()
        assert_true(dialog.visible, "une confirmation doit etre demandee")
        assert_eq(quits.size(), before_press, "rien ne quitte avant la confirmation")
        var before := quits.size()
        dialog.hide()
        dialog.confirmed.emit()
        assert_eq(quits.size(), before + 1)
    GameManager.quit_hook = Callable()
