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
