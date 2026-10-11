extends Control
## Ecran de selection de profil : un profil par enfant, suppression avec
## confirmation explicite (cahier des charges §9).

var _pending_delete_profile_id: String = ""

@onready var _title_label: Label = %TitleLabel
@onready var _profile_list: VBoxContainer = %ProfileList
@onready var _empty_state_label: Label = %EmptyStateLabel
@onready var _new_profile_button: Button = %NewProfileButton
@onready var _settings_button: Button = %SettingsButton
@onready var _delete_confirm_dialog: ConfirmationDialog = %DeleteConfirmDialog


func _ready() -> void:
    _title_label.text = UIText.get_text("profile_select.title")
    _new_profile_button.text = UIText.get_text("profile_select.new_profile_button")
    _empty_state_label.text = UIText.get_text("profile_select.empty_state")
    _delete_confirm_dialog.title = UIText.get_text("profile_select.delete_confirm_title")
    _delete_confirm_dialog.dialog_text = UIText.get_text("profile_select.delete_confirm_message")
    _delete_confirm_dialog.ok_button_text = UIText.get_text("profile_select.delete_confirm_yes")
    _delete_confirm_dialog.cancel_button_text = UIText.get_text(
        "profile_select.delete_confirm_no"
    )

    _settings_button.text = UIText.get_text("profile_select.settings_button")
    _settings_button.pressed.connect(_on_settings_pressed)
    _new_profile_button.pressed.connect(_on_new_profile_pressed)
    _delete_confirm_dialog.confirmed.connect(_on_delete_confirmed)

    AudioManager.play_music("forest")
    _refresh_profile_list()


func _refresh_profile_list() -> void:
    for child in _profile_list.get_children():
        child.queue_free()

    var summaries := ProfileManager.list_profile_summaries()
    _empty_state_label.visible = summaries.is_empty()

    for summary: Dictionary in summaries:
        _profile_list.add_child(_build_profile_row(summary))


func _build_profile_row(summary: Dictionary) -> Control:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)

    var select_button := Button.new()
    select_button.text = "%s (%s)" % [summary["display_name"], summary["school_level"]]
    select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    select_button.custom_minimum_size = Vector2(0, 56)
    select_button.pressed.connect(_on_profile_selected.bind(summary["profile_id"]))
    row.add_child(select_button)

    var delete_button := Button.new()
    delete_button.theme_type_variation = &"SecondaryButton"
    delete_button.text = UIText.get_text("profile_select.delete_button")
    delete_button.pressed.connect(_on_delete_requested.bind(summary["profile_id"]))
    row.add_child(delete_button)

    return row


func _on_profile_selected(profile_id: String) -> void:
    if ProfileManager.select_profile(profile_id):
        GameManager.goto(GameManager.SCENE_WORLD_MAP)


func _on_delete_requested(profile_id: String) -> void:
    _pending_delete_profile_id = profile_id
    _delete_confirm_dialog.popup_centered()


func _on_delete_confirmed() -> void:
    if _pending_delete_profile_id.is_empty():
        return
    ProfileManager.delete_profile(_pending_delete_profile_id)
    _pending_delete_profile_id = ""
    _refresh_profile_list()


func _on_new_profile_pressed() -> void:
    GameManager.goto(GameManager.SCENE_PROFILE_CREATE)


func _on_settings_pressed() -> void:
    GameManager.settings_return_scene = GameManager.SCENE_PROFILE_SELECT
    GameManager.goto(GameManager.SCENE_SETTINGS)
