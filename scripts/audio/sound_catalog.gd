class_name SoundCatalog
extends RefCounted
## Identifiants des effets sonores et des musiques, resolus vers un fichier
## d'un repertoire fixe (jamais de chemin libre : voir CLAUDE.md). Code pur.

const SFX_DIR := "res://assets/audio/sfx"
const MUSIC_DIR := "res://assets/audio/music"

const SFX_IDS: Array[String] = ["click", "success", "try_again", "star", "fanfare"]
const MUSIC_IDS: Array[String] = ["forest", "marsh"]


static func sfx_path(sfx_id: String) -> String:
    if not SFX_IDS.has(sfx_id):
        return ""
    return "%s/%s.ogg" % [SFX_DIR, sfx_id]


static func music_path(music_id: String) -> String:
    if not MUSIC_IDS.has(music_id):
        return ""
    return "%s/%s.ogg" % [MUSIC_DIR, music_id]


## Musique d'une region selon le niveau scolaire de la regle.
static func music_for_level(level: String) -> String:
    return "marsh" if level == "CE2" else "forest"
