extends Control
## Creation d'un profil enfant : prenom/pseudo et niveau scolaire. Pas
## d'avatar ni d'element cosmetique : hors perimetre de la premiere version
## jouable (voir prompt de lancement, Objectif).

@onready var _title_label: Label = %TitleLabel
@onready var _name_label: Label = %NameLabel
@onready var _name_edit: LineEdit = %NameEdit
@onready var _level_label: Label = %LevelLabel
@onready var _ce1_button: Button = %CE1Button
@onready var _ce2_button: Button = %CE2Button
@onready var _error_label: Label = %ErrorLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
    _title_label.text = UIText.get_text("profile_create.title")
    _name_label.text = UIText.get_text("profile_create.name_label")
    _name_edit.placeholder_text = UIText.get_text("profile_create.name_placeholder")
    _level_label.text = UIText.get_text("profile_create.level_label")
    _ce1_button.text = UIText.get_text("profile_create.level_ce1")
    _ce2_button.text = UIText.get_text("profile_create.level_ce2")
    _error_label.text = UIText.get_text("profile_create.name_required_error")
    _error_label.visible = false
    _confirm_button.text = UIText.get_text("profile_create.confirm_button")
    _cancel_button.text = UIText.get_text("profile_create.cancel_button")

    _ce1_button.button_pressed = true

    _confirm_button.pressed.connect(_on_confirm_pressed)
    _cancel_button.pressed.connect(_on_cancel_pressed)


func _on_confirm_pressed() -> void:
    var display_name := _name_edit.text.strip_edges()
    if display_name.is_empty():
        _error_label.visible = true
        return

    var school_level := "CE1" if _ce1_button.button_pressed else "CE2"
    var profile_id := ProfileManager.create_profile(display_name, school_level)
    if ProfileManager.select_profile(profile_id):
        GameManager.goto(GameManager.SCENE_WORLD_MAP)


func _on_cancel_pressed() -> void:
    GameManager.goto(GameManager.SCENE_PROFILE_SELECT)
