extends Control
## Reglages de l'appareil : volume, taille du texte, animations. Accessible
## depuis la carte et la selection de profil sans barriere (l'enfant peut
## baisser le son lui-meme). L'espace adulte est un bouton separe, derriere
## une petite barriere.

@onready var _title_label: Label = %TitleLabel
@onready var _volume_label: Label = %VolumeLabel
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _music_label: Label = %MusicLabel
@onready var _music_slider: HSlider = %MusicSlider
@onready var _effects_label: Label = %EffectsLabel
@onready var _effects_slider: HSlider = %EffectsSlider
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

    _music_label.text = UIText.get_text("settings.music_label")
    _effects_label.text = UIText.get_text("settings.effects_label")
    _setup_slider(_volume_slider, SettingsManager.volume, _on_volume_changed)
    _setup_slider(_music_slider, SettingsManager.music_volume, _on_music_changed)
    _setup_slider(_effects_slider, SettingsManager.effects_volume, _on_effects_changed)
    # Un petit son a la fin du geste fait entendre le niveau choisi.
    _volume_slider.drag_ended.connect(_on_drag_ended)
    _effects_slider.drag_ended.connect(_on_drag_ended)

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


func _setup_slider(slider: HSlider, value: float, handler: Callable) -> void:
    slider.min_value = 0.0
    slider.max_value = 1.0
    slider.step = 1.0 / AppSettings.VOLUME_STEPS
    slider.value = value
    slider.value_changed.connect(handler)


func _on_volume_changed(value: float) -> void:
    SettingsManager.set_volume(value)


func _on_music_changed(value: float) -> void:
    SettingsManager.set_music_volume(value)


func _on_effects_changed(value: float) -> void:
    SettingsManager.set_effects_volume(value)


func _on_drag_ended(_value_changed: bool) -> void:
    AudioManager.play_sfx("success")


func _on_text_size_pressed(index: int) -> void:
    SettingsManager.set_text_scale_index(index)


func _on_animations_chosen(enabled: bool) -> void:
    SettingsManager.set_animations_enabled(enabled)


func _on_adult_pressed() -> void:
    GameManager.goto(GameManager.SCENE_ADULT_SPACE)


func _on_back_pressed() -> void:
    GameManager.goto(GameManager.settings_return_scene)
