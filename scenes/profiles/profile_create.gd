extends Control
## Creation d'un profil enfant : prenom/pseudo et niveau scolaire. Pas
## d'avatar ni d'element cosmetique : hors perimetre de la premiere version
## jouable (voir prompt de lancement, Objectif).

@onready var _title_label: Label = %TitleLabel
@onready var _name_label: Label = %NameLabel
@onready var _name_edit: LineEdit = %NameEdit
@onready var _level_label: Label = %LevelLabel
@onready var _level_box: HBoxContainer = %LevelBox
@onready var _error_label: Label = %ErrorLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
    _title_label.text = UIText.get_text("profile_create.title")
    _name_label.text = UIText.get_text("profile_create.name_label")
    _name_edit.placeholder_text = UIText.get_text("profile_create.name_placeholder")
    _level_label.text = UIText.get_text("profile_create.level_label")
    _error_label.text = UIText.get_text("profile_create.name_required_error")
    _error_label.visible = false
    _confirm_button.text = UIText.get_text("profile_create.confirm_button")
    _cancel_button.text = UIText.get_text("profile_create.cancel_button")

    _build_level_buttons()

    _confirm_button.pressed.connect(_on_confirm_pressed)
    _cancel_button.pressed.connect(_on_cancel_pressed)


## Un bouton par niveau (SchoolLevels.ALL), un seul actif a la fois ; CE1 par
## defaut.
func _build_level_buttons() -> void:
    var group := ButtonGroup.new()
    for level in SchoolLevels.ALL:
        # Un niveau sans contenu n'est pas propose (il apparait avec ses tableaux).
        if ExerciseEngine.get_regions_for_level(level).is_empty():
            continue
        var button := Button.new()
        button.text = UIText.get_text("profile_create.level_%s" % level.to_lower())
        button.theme_type_variation = &"SecondaryButton"
        button.toggle_mode = true
        button.button_group = group
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.custom_minimum_size = Vector2(0, 56)
        button.set_meta("level", level)
        button.button_pressed = _level_box.get_child_count() == 0
        _level_box.add_child(button)


func _selected_level() -> String:
    for child in _level_box.get_children():
        var button := child as Button
        if button != null and button.button_pressed:
            return button.get_meta("level")
    return "CE1"


func _on_confirm_pressed() -> void:
    var display_name := _name_edit.text.strip_edges()
    if display_name.is_empty():
        _error_label.visible = true
        return

    var school_level := _selected_level()
    var profile_id := ProfileManager.create_profile(display_name, school_level)
    if ProfileManager.select_profile(profile_id):
        GameManager.goto(GameManager.SCENE_WORLD_MAP)


func _on_cancel_pressed() -> void:
    GameManager.goto(GameManager.SCENE_PROFILE_SELECT)
