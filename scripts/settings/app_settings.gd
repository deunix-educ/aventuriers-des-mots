class_name AppSettings
extends RefCounted
## Preferences de l'appareil (volume, taille du texte, animations). Code pur :
## valeurs par defaut, nettoyage d'un fichier lu sur disque (jamais de valeur
## hors limites) et conversions. Les reglages sont communs a tous les profils :
## ils ne font pas partie de la sauvegarde d'un enfant.

const FORMAT_VERSION := 1

## Facteurs de taille du texte proposes (index = choix dans l'ecran de reglages).
const TEXT_SCALES: Array[float] = [1.0, 1.15, 1.3]

## Types de theme jamais agrandis : les grands titres sont deja grands, et
## les agrandir ferait deborder les barres d'en-tete de la fenetre.
const UNSCALED_THEME_TYPES: Array[String] = ["HeaderTitle", "CardTitle", "Window"]
const VOLUME_STEPS := 5


static func defaults() -> Dictionary:
    return {
        "format_version": FORMAT_VERSION,
        "volume": 0.8,
        "music_volume": 0.5,
        "effects_volume": 0.8,
        "music_track": SoundCatalog.MUSIC_AUTO,
        "text_scale_index": 0,
        "animations_enabled": true,
    }


## Complete et borne les valeurs d'un dictionnaire quelconque (fichier absent,
## tronque ou modifie a la main) : le resultat est toujours utilisable.
static func sanitize(raw: Variant) -> Dictionary:
    var result := defaults()
    if typeof(raw) != TYPE_DICTIONARY:
        return result
    var source: Dictionary = raw
    var volume: Variant = source.get("volume")
    if typeof(volume) == TYPE_FLOAT or typeof(volume) == TYPE_INT:
        result["volume"] = clampf(float(volume), 0.0, 1.0)
    for key: String in ["music_volume", "effects_volume"]:
        var other: Variant = source.get(key)
        if typeof(other) == TYPE_FLOAT or typeof(other) == TYPE_INT:
            result[key] = clampf(float(other), 0.0, 1.0)
    var track: Variant = source.get("music_track")
    if typeof(track) == TYPE_STRING and SoundCatalog.music_choices().has(track):
        result["music_track"] = track
    var index: Variant = source.get("text_scale_index")
    if typeof(index) == TYPE_FLOAT or typeof(index) == TYPE_INT:
        result["text_scale_index"] = clampi(int(index), 0, TEXT_SCALES.size() - 1)
    var animations: Variant = source.get("animations_enabled")
    if typeof(animations) == TYPE_BOOL:
        result["animations_enabled"] = animations
    return result


static func text_scale(settings: Dictionary) -> float:
    return TEXT_SCALES[clampi(int(settings["text_scale_index"]), 0, TEXT_SCALES.size() - 1)]


## Volume de 0 a 1 vers des decibels ; le silence complet est un vrai silence.
static func volume_db(volume: float) -> float:
    if volume <= 0.0:
        return -80.0
    return linear_to_db(clampf(volume, 0.0, 1.0))
