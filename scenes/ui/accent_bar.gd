class_name AccentBar
extends HFlowContainer
## Rangee de boutons d'accents sous un champ de saisie. Les boutons ne prennent
## jamais le focus : le champ garde le clavier (et le clavier tactile reste
## ouvert). Une touche « Maj » bascule entre minuscules et majuscules (la
## dictee exige la majuscule initiale).

var _target: LineEdit = null
var _uppercase := false
var _shift_button: Button


func _ready() -> void:
    add_theme_constant_override("h_separation", 6)
    add_theme_constant_override("v_separation", 6)
    _shift_button = Button.new()
    _shift_button.text = "⇧"
    _shift_button.tooltip_text = UIText.get_text("accent_bar.shift_tooltip")
    _shift_button.toggle_mode = true
    _shift_button.focus_mode = Control.FOCUS_NONE
    _shift_button.theme_type_variation = &"SecondaryButton"
    _shift_button.toggled.connect(_on_shift_toggled)
    _style(_shift_button)
    add_child(_shift_button)
    _rebuild()
    visible = _target != null


## Cible un champ de saisie ; null masque la barre.
func set_target(edit: LineEdit) -> void:
    _target = edit
    visible = edit != null


func _on_shift_toggled(pressed: bool) -> void:
    _uppercase = pressed
    _rebuild()


func _rebuild() -> void:
    for child in get_children():
        if child != _shift_button:
            child.queue_free()
    for character in AccentInserter.characters(_uppercase):
        var button := Button.new()
        button.text = character
        button.focus_mode = Control.FOCUS_NONE
        button.theme_type_variation = &"SecondaryButton"
        button.pressed.connect(_on_accent_pressed.bind(character))
        _style(button)
        add_child(button)


func _on_accent_pressed(character: String) -> void:
    if _target == null or not is_instance_valid(_target):
        return
    var result := AccentInserter.insert(_target.text, _target.caret_column, character)
    _target.text = result["text"]
    _target.caret_column = result["caret"]
    # Une majuscule sert une fois : on revient aux minuscules.
    if _uppercase:
        _shift_button.button_pressed = false


func _style(button: Button) -> void:
    button.custom_minimum_size = Vector2(52, 52)
    button.add_theme_font_size_override("font_size", SettingsManager.scaled_font_size(26))
