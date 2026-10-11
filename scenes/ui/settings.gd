extends Control
## Reglages de l'appareil : volume, taille du texte, animations. Accessible
## depuis la carte et la selection de profil sans barriere (l'enfant peut
## baisser le son lui-meme). L'espace adulte est un bouton separe, derriere
## une petite barriere.

@onready var _title_label: Label = %TitleLabel
@onready var _volume_label: Label = %VolumeLabel
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _text_size_label: Label = %TextSizeLabel
@onready var _text_size_box: HBoxContainer = %TextSizeBox
@onready var _animations_label: Label = %AnimationsLabel
@onready var _animations_box: HBoxContainer = %AnimationsBox
@onready var _adult_button: Button = %AdultButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
    _title_label.text = UIText.get_text("settings.title")
    _volume_label.text = UIText.get_text("settings.volume_label")
    _text_size_label.text = UIText.get_text("settings.text_size_label")
    _animations_label.text = UIText.get_text("settings.animations_label")
    _adult_button.text = UIText.get_text("settings.adult_button")
    _back_button.text = UIText.get_text("settings.back_button")

    _volume_slider.min_value = 0.0
    _volume_slider.max_value = 1.0
    _volume_slider.step = 1.0 / AppSettings.VOLUME_STEPS
    _volume_slider.value = SettingsManager.volume
    _volume_slider.value_changed.connect(_on_volume_changed)

    _build_text_size_buttons()

    _build_animation_buttons()

    _adult_button.pressed.connect(_on_adult_pressed)
    _back_button.pressed.connect(_on_back_pressed)


func _build_text_size_buttons() -> void:
    var group := ButtonGroup.new()
    for index in range(AppSettings.TEXT_SCALES.size()):
        var button := Button.new()
        button.text = UIText.get_text("settings.text_size_%d" % index)
        button.toggle_mode = true
        button.button_group = group
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.custom_minimum_size = Vector2(0, 52)
        button.button_pressed = index == SettingsManager.text_scale_index
        button.pressed.connect(_on_text_size_pressed.bind(index))
        _text_size_box.add_child(button)


func _build_animation_buttons() -> void:
    var group := ButtonGroup.new()
    for enabled: bool in [true, false]:
        var button := Button.new()
        button.text = UIText.get_text("settings.animations_on" if enabled else "settings.animations_off")
        button.toggle_mode = true
        button.button_group = group
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.custom_minimum_size = Vector2(0, 52)
        button.button_pressed = enabled == SettingsManager.animations_enabled
        button.pressed.connect(_on_animations_chosen.bind(enabled))
        _animations_box.add_child(button)


func _on_volume_changed(value: float) -> void:
    SettingsManager.set_volume(value)


func _on_text_size_pressed(index: int) -> void:
    SettingsManager.set_text_scale_index(index)


func _on_animations_chosen(enabled: bool) -> void:
    SettingsManager.set_animations_enabled(enabled)


func _on_adult_pressed() -> void:
    GameManager.goto(GameManager.SCENE_ADULT_SPACE)


func _on_back_pressed() -> void:
    GameManager.goto(GameManager.settings_return_scene)
