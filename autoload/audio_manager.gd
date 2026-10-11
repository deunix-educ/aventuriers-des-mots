extends Node
## Lecture des voix, dictees, musiques et effets sonores, y compris l'audio
## provisoire des dictees. Aucun fichier audio n'est encore fourni (etape
## "Graphismes et audio provisoires", a venir) : play_dictation se degrade
## silencieusement (avertissement journalise) si le fichier est absent,
## plutot que de faire planter le jeu.

const DICTATION_AUDIO_DIR := "res://assets/audio/dictations"

var _player: AudioStreamPlayer


func _ready() -> void:
    _player = AudioStreamPlayer.new()
    add_child(_player)


func play_dictation(audio_id: String) -> void:
    if audio_id.is_empty():
        return
    var path := "%s/%s.ogg" % [DICTATION_AUDIO_DIR, audio_id]
    if not ResourceLoader.exists(path):
        push_warning("Audio de dictee introuvable (pas encore genere) : %s" % path)
        return
    _player.stream = load(path)
    _player.play()
