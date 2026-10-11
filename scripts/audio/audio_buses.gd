class_name AudioBuses
extends RefCounted
## Bus audio du jeu, crees a l'execution (pas de fichier de disposition a
## maintenir) : « Music » et « Effects » sont des enfants du bus principal,
## dont le volume est le volume general. Les voix des dictees restent sur le
## bus principal : elles ne sont jamais couvertes par la musique.

const MUSIC := "Music"
const EFFECTS := "Effects"


## Cree les bus manquants. Idempotent.
static func ensure() -> void:
    for bus_name in [MUSIC, EFFECTS]:
        if AudioServer.get_bus_index(bus_name) != -1:
            continue
        AudioServer.add_bus()
        var index := AudioServer.bus_count - 1
        AudioServer.set_bus_name(index, bus_name)
        AudioServer.set_bus_send(index, "Master")
