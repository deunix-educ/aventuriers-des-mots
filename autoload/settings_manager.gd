extends Node
## Volumes (general, musique, effets), taille du texte et animations. Les
## reglages sont ceux de l'appareil
## (user://settings.json), pas ceux d'un profil. Les valeurs sont nettoyees par
## AppSettings a chaque lecture ; un fichier absent ou abime redonne les valeurs
## par defaut sans erreur. Le volume agit sur le bus principal ; la taille du
## texte met a l'echelle les tailles du theme global.

signal changed

const SETTINGS_PATH := "user://settings.json"

var animations_enabled := true
var volume := 0.8
var music_volume := 0.5
var effects_volume := 0.8
var music_track := SoundCatalog.MUSIC_AUTO
var text_scale_index := 0

var _base_font_sizes: Dictionary = {}
var _base_default_font_size := 0


func _ready() -> void:
    load_from_disk()
    apply()


func text_scale() -> float:
    return AppSettings.TEXT_SCALES[text_scale_index]


## Taille d'un texte fixe dans un script, mise a l'echelle du reglage.
func scaled_font_size(base: int) -> int:
    return int(round(base * text_scale()))


func set_volume(value: float) -> void:
    volume = clampf(value, 0.0, 1.0)
    _commit()


func set_music_volume(value: float) -> void:
    music_volume = clampf(value, 0.0, 1.0)
    _commit()


func set_effects_volume(value: float) -> void:
    effects_volume = clampf(value, 0.0, 1.0)
    _commit()


func set_music_track(choice: String) -> void:
    music_track = choice if SoundCatalog.music_choices().has(choice) else SoundCatalog.MUSIC_AUTO
    _commit()


func set_text_scale_index(index: int) -> void:
    text_scale_index = clampi(index, 0, AppSettings.TEXT_SCALES.size() - 1)
    _commit()


func set_animations_enabled(enabled: bool) -> void:
    animations_enabled = enabled
    _commit()


func load_from_disk() -> void:
    var raw: Variant = null
    if FileAccess.file_exists(SETTINGS_PATH):
        var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
        if file != null:
            raw = JSON.parse_string(file.get_as_text())
    var clean := AppSettings.sanitize(raw)
    volume = clean["volume"]
    music_volume = clean["music_volume"]
    effects_volume = clean["effects_volume"]
    music_track = clean["music_track"]
    text_scale_index = clean["text_scale_index"]
    animations_enabled = clean["animations_enabled"]


## Ecriture atomique : fichier temporaire puis remplacement.
func save_to_disk() -> bool:
    var data := AppSettings.defaults()
    data["volume"] = volume
    data["music_volume"] = music_volume
    data["effects_volume"] = effects_volume
    data["music_track"] = music_track
    data["text_scale_index"] = text_scale_index
    data["animations_enabled"] = animations_enabled
    var tmp_path := SETTINGS_PATH + ".tmp"
    var file := FileAccess.open(tmp_path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data))
    file.close()
    var dir := DirAccess.open("user://")
    if dir == null:
        return false
    return dir.rename(tmp_path, SETTINGS_PATH) == OK


## Applique les reglages au moteur : volume du bus principal et tailles du
## theme global.
func apply() -> void:
    AudioBuses.ensure()
    AudioServer.set_bus_volume_db(0, AppSettings.volume_db(volume))
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index(AudioBuses.MUSIC), AppSettings.volume_db(music_volume)
    )
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index(AudioBuses.EFFECTS), AppSettings.volume_db(effects_volume)
    )
    _apply_text_scale()


func _commit() -> void:
    apply()
    save_to_disk()
    changed.emit()


func _apply_text_scale() -> void:
    var theme := ThemeDB.get_project_theme()
    if theme == null:
        return
    # Les tailles d'origine sont memorisees une fois : on recalcule toujours
    # a partir d'elles pour ne pas accumuler les facteurs.
    if _base_font_sizes.is_empty():
        _base_default_font_size = theme.default_font_size
        for type_name in theme.get_font_size_type_list():
            for item_name in theme.get_font_size_list(type_name):
                _base_font_sizes["%s/%s" % [type_name, item_name]] = theme.get_font_size(
                    item_name, type_name
                )
    var factor := text_scale()
    theme.default_font_size = int(round(_base_default_font_size * factor))
    for key: String in _base_font_sizes:
        var parts := key.split("/")
        if AppSettings.UNSCALED_THEME_TYPES.has(parts[0]):
            continue
        theme.set_font_size(parts[1], parts[0], int(round(_base_font_sizes[key] * factor)))
