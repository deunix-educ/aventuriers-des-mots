extends Node
## Lecture des voix (dictees), des effets sonores et de la musique d'ambiance.
## Les sons viennent d'identifiants resolus par SoundCatalog dans un
## repertoire fixe. Un fichier absent se degrade silencieusement
## (avertissement journalise) plutot que de faire planter le jeu. La musique
## baisse pendant qu'une dictee est lue, pour ne jamais couvrir la voix.

const MUSIC_DUCK_DB := -12.0
const MUSIC_BASE_DB := -6.0

var _voice_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _effect_players: Array[AudioStreamPlayer] = []
var _current_music_id := ""
var _stream_cache: Dictionary = {}


func _ready() -> void:
    AudioBuses.ensure()
    _voice_player = AudioStreamPlayer.new()
    _voice_player.finished.connect(_on_voice_finished)
    add_child(_voice_player)

    _music_player = AudioStreamPlayer.new()
    _music_player.bus = AudioBuses.MUSIC
    _music_player.volume_db = MUSIC_BASE_DB
    add_child(_music_player)

    for _i in range(4):
        var player := AudioStreamPlayer.new()
        player.bus = AudioBuses.EFFECTS
        add_child(player)
        _effect_players.append(player)

    # Un clic sur n'importe quel bouton du jeu produit le meme petit son.
    get_tree().node_added.connect(_on_node_added)


func play_dictation(audio_id: String) -> void:
    if audio_id.is_empty():
        return
    var path := "%s/%s.ogg" % ["res://assets/audio/dictations", audio_id]
    if not ResourceLoader.exists(path):
        push_warning("Audio de dictee introuvable (pas encore genere) : %s" % path)
        return
    _voice_player.stream = load(path)
    _voice_player.play()
    _music_player.volume_db = MUSIC_BASE_DB + MUSIC_DUCK_DB


func play_sfx(sfx_id: String) -> void:
    var stream := _load_stream(SoundCatalog.sfx_path(sfx_id))
    if stream == null:
        return
    for player in _effect_players:
        if not player.playing:
            player.stream = stream
            player.play()
            return
    # Tous les lecteurs sont occupes : on coupe le premier plutot que d'ignorer.
    _effect_players[0].stream = stream
    _effect_players[0].play()


## Lance la musique d'ambiance en boucle. Sans effet si c'est deja celle-ci.
func play_music(music_id: String) -> void:
    if music_id == _current_music_id and _music_player.playing:
        return
    var stream := _load_stream(SoundCatalog.music_path(music_id))
    if stream == null:
        return
    if stream is AudioStreamOggVorbis:
        (stream as AudioStreamOggVorbis).loop = true
    _current_music_id = music_id
    _music_player.stream = stream
    _music_player.play()


func current_music_id() -> String:
    return _current_music_id


func stop_music() -> void:
    _current_music_id = ""
    _music_player.stop()


func _load_stream(path: String) -> AudioStream:
    if path.is_empty():
        return null
    if _stream_cache.has(path):
        return _stream_cache[path]
    if not ResourceLoader.exists(path):
        push_warning("Son introuvable : %s" % path)
        return null
    var stream: AudioStream = load(path)
    _stream_cache[path] = stream
    return stream


func _on_voice_finished() -> void:
    _music_player.volume_db = MUSIC_BASE_DB


func _on_node_added(node: Node) -> void:
    var button := node as BaseButton
    if button != null and not button.has_meta("silent"):
        button.pressed.connect(play_sfx.bind("click"))
